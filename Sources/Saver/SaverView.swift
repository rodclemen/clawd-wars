import ScreenSaver
import AppKit
import QuartzCore

/// The Clawd Wars screen saver: the window's location at full screen, the crew fighting on its floor, and each
/// session's state as a hologram over its head. It shows what the running app publishes (`SaverFeed`); with
/// Clawd Wars not running, what the hooks last wrote (`SaverFeed.fromHooks`). With no session running at all it puts
/// on a show instead (a made-up crew duelling, somewhere new every few minutes).
///
/// Runs inside macOS's sandboxed screen saver host, one instance per display (and one for the System Settings
/// preview). Everything is Core Animation layers: the location's picture and pixel art scaled on the GPU with
/// nearest-neighbour filtering, text rendered once per look and cached.
@objc(ClawdWarsSaverView)
final class ClawdWarsSaverView: ScreenSaverView {
    private let host = NSView()
    private let roomLayer = CALayer(), liveLayer = CALayer()
    private var pool: [CALayer] = []
    private var room: (size: CGSize, location: Location, image: CGImage)?
    private var live: PixelCanvas?
    private var textCache: [String: CGImage] = [:]
    private var feed: SaverFeed?
    private var lastRead = 0.0
    private var lastLocation = Location.cantina
    /// Inside the app (the window's screen-saver view) it's handed the feed directly instead of reading the file.
    var feedSource: (() -> SaverFeed?)?
    /// Shown in the app's window rather than as the screen saver: no clock (the menu bar has one), a bigger place
    /// name, and the card under the mouse shown larger, to read.
    var inWindow = false { didSet { updateTrackingAreas() } }
    private var mouse: CGPoint?
    /// Against burn-in: every other 10 minutes the clock and the place name swap corners, and the cards and name tags
    /// move up clear of where they were.
    private static let shiftEvery = 600.0       // ten minutes
    private var started = Date().timeIntervalSince1970
    private var shifted = false
    /// Every 10 minutes the saver also wipes, Star Wars style, to somewhere new: the home of someone else in the crew
    /// (anywhere at all with just the one). `visit` is where it went; nil until the first wipe (where the app says).
    private var period = 0
    private var visit: Location?
    private let wipeLayer = CALayer(), wipeMask = CAShapeLayer()
    private var wipe: (start: Double, clock: Bool)?
    private var trips = 0                       // the wipes take turns: a hard edge, then a clock
    /// With Clawd Wars not running: a made-up crew, cast for `demoPlace` (a local or two among them), off somewhere
    /// new every `demoEvery`.
    private var demo: [SaverFeed.Session] = []
    private var demoPlace: Location?
    private var lastTrip = Date().timeIntervalSince1970
    private static let demoEvery = 180.0        // three minutes

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 15
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        host.wantsLayer = true
        addSubview(host)
        guard let root = host.layer else { return }
        root.backgroundColor = CGColor(gray: 0, alpha: 1)
        root.masksToBounds = true
        for l in [roomLayer, liveLayer] {
            l.anchorPoint = .zero
            l.magnificationFilter = .nearest
            l.actions = Self.noAnimations
            root.addSublayer(l)
        }
        // The old place, frozen, over the new one while the wipe takes it away (under the crew and the cards).
        wipeLayer.anchorPoint = .zero
        wipeLayer.magnificationFilter = .nearest
        wipeLayer.actions = Self.noAnimations
        wipeLayer.isHidden = true
        wipeMask.actions = ["path": NSNull()]
        wipeLayer.mask = wipeMask
        root.addSublayer(wipeLayer)
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    private static let noAnimations: [String: CAAction] = [
        "contents": NSNull(), "bounds": NSNull(), "position": NSNull(), "transform": NSNull(),
        "opacity": NSNull(), "hidden": NSNull(), "frame": NSNull(),
    ]

    override func startAnimation() {
        super.startAnimation()
        lastRead = 0
        started = Date().timeIntervalSince1970
        period = 0
        visit = nil
        lastTrip = started
    }

    override func draw(_ rect: NSRect) {}   // the layers are the picture

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        guard inWindow else { return }
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    /// In the app's window: its menu on a right-click, as everywhere else in the window.
    var contextMenu: (() -> NSMenu?)?

    override func rightMouseDown(with event: NSEvent) {
        if let menu = contextMenu?() { NSMenu.popUpContextMenu(menu, with: event, for: self) } else { super.rightMouseDown(with: event) }
    }

    override func mouseMoved(with event: NSEvent) { mouse = convert(event.locationInWindow, from: nil) }
    override func mouseExited(with event: NSEvent) { mouse = nil }

    override func animateOneFrame() {
        let now = Date().timeIntervalSince1970
        if now - lastRead >= 1 {
            lastRead = now
            if let feedSource { feed = feedSource() } else {
                // Clawd Wars closed (its feed gone stale): the hooks still say who's running.
                let app = SaverFeed.load()
                feed = app.flatMap { now - $0.at < SaverFeed.staleAfter ? $0 : nil } ?? SaverFeed.fromHooks(now: now, last: app) ?? app
            }
        }
        let p = isPreview ? 0 : Int((now - started) / Self.shiftEvery)
        shifted = p % 2 == 1
        if p != period { period = p; travel(now) }
        else if !isPreview, !crewed(now), now - lastTrip >= Self.demoEvery { travel(now) }
        render(now)
    }

    // MARK: Travel

    /// Off somewhere new: freeze what's on screen into the wipe layer, pick the place, and start the wipe (a hard edge
    /// across the screen and a clock wipe, taking turns).
    private func travel(_ now: Double) {
        lastTrip = now
        let here = visit ?? lastLocation
        let crew = (running(now) ? feed?.sessions ?? [] : []).flatMap { [$0.cast] + $0.agents.map(\.cast) }.map { Cast(id: $0) }
        let homes = Set(crew.map(\.home)).subtracting([here])
        guard let next = crew.count > 1 && !homes.isEmpty ? homes.randomElement()
                : Location.allCases.filter({ $0 != here }).randomElement() else { return }
        if let room {
            let liveNow = liveLayer.contents.flatMap { CFGetTypeID($0 as CFTypeRef) == CGImage.typeID ? ($0 as! CGImage) : nil }
            if let frozen = Wipe.flatten([room.image] + (liveNow.map { [$0] } ?? [])) {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                wipeLayer.contents = frozen
                wipeLayer.frame = roomLayer.frame
                wipeMask.frame = wipeLayer.bounds
                wipeMask.path = Wipe.remaining(0, clock: trips % 2 == 0, in: wipeLayer.bounds)
                wipeLayer.isHidden = false
                CATransaction.commit()
                wipe = (now, trips % 2 == 0)
                trips += 1
            }
        }
        visit = next
    }

    // MARK: Frame

    private struct Item {
        var image: CGImage
        var rect: CGRect
        var mirrored = false
        var alpha: CGFloat = 1
        var smooth = false      // text and panels: linear filtering; pixel art: nearest
    }

    /// Screen points per art pixel: about 270 art pixels from floor to ceiling, whatever the display.
    private var P: CGFloat { max(1, (bounds.height / 270).rounded()) }
    /// Text and panels are sized against a 1080-point-tall screen.
    private var u: CGFloat { max(0.3, bounds.height / 1080) }
    private var scale: CGFloat { window?.backingScaleFactor ?? 2 }

    /// Fed by the app (the window's view), it's running by definition: during a live resize the app's timers pause
    /// and the feed ages past `staleAfter`, which put up "isn't running" until the mouse let go.
    private func running(_ now: Double) -> Bool {
        feed.map { feedSource != nil || now - $0.at < SaverFeed.staleAfter } ?? false
    }

    /// There's a crew worth showing. With no AI running the stage is empty, so the demo cast fills in; as the screen
    /// saver it also does for a lone session sitting idle (one still figure all night), but not one at work or waiting
    /// on you. The app's window always shows its crew.
    private func crewed(_ now: Double) -> Bool {
        guard running(now), let sessions = feed?.sessions, !sessions.isEmpty else { return false }
        if feedSource == nil, sessions.count == 1, let lone = sessions.first, lone.mood == "idle", lone.agents.isEmpty { return false }
        return true
    }

    private func render(_ now: Double) {
        guard let root = host.layer else { return }
        let running = running(now)
        // Stale or not, the feed says where the crew was last: the place stays when Clawd Wars quits.
        if let f = feed, let l = Location(rawValue: f.location) { lastLocation = l }
        let location = visit ?? lastLocation
        let P = self.P
        let cw = Int((bounds.width / P).rounded(.up)), ch = Int((bounds.height / P).rounded(.up))
        let floorRows = max(8, Int(Double(ch) * 0.125))
        let picture = CGRect(x: 0, y: 0, width: CGFloat(cw) * P, height: CGFloat(ch) * P)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // The place: redrawn only when the location or the display changes.
        if room?.size != bounds.size || room?.location != location {
            let c = PixelCanvas(cw, ch)
            location.drawStatic(c, floorRows: floorRows)
            if let img = c.makeImage() {
                room = (bounds.size, location, img)
                roomLayer.contents = img
                roomLayer.frame = picture
            }
            live = nil
        }
        // What moves there.
        if location.animates(rows: ch) {
            if live?.w != cw || live?.h != ch { live = PixelCanvas(cw, ch) } else { live?.clear() }
            if let live {
                location.drawAnimated(live, floorRows: floorRows, t: now)
                liveLayer.contents = live.makeImage()
                liveLayer.frame = picture
            }
        } else {
            liveLayer.contents = nil
        }
        if let w = wipe {
            let k = (now - w.start) / Wipe.duration
            if k >= 1 {
                wipe = nil
                wipeLayer.isHidden = true
                wipeLayer.contents = nil
            } else {
                wipeMask.path = Wipe.remaining(k, clock: w.clock, in: wipeLayer.bounds)
            }
        }

        // A soft shade from the top, so the place name and clock read on bright places (the cantina, Hoth).
        var items: [Item] = [Item(image: shade(), rect: CGRect(x: 0, y: bounds.height * 0.6, width: bounds.width,
                                                               height: bounds.height * 0.4), smooth: true)]
        let feet = CGFloat(floorRows) * P * 0.55
        if crewed(now), let f = feed {
            items += crew(f.sessions, now: now, feet: feet)
        } else {
            if demoPlace != location { demo = cast(for: location, now: now); demoPlace = location }
            items += crew(demo, now: now, feet: feet, cards: false)
        }
        items += hud(running ? feed : nil, location: location, now: now, idle: !running)
        show(items, in: root)
        CATransaction.commit()
    }

    private func show(_ items: [Item], in root: CALayer) {
        for (i, item) in items.enumerated() {
            if i == pool.count {
                let l = CALayer()
                l.actions = Self.noAnimations
                root.addSublayer(l)
                pool.append(l)
            }
            let l = pool[i]
            l.contents = item.image
            l.magnificationFilter = item.smooth ? .linear : .nearest
            l.minificationFilter = item.smooth ? .linear : .nearest
            l.bounds = CGRect(origin: .zero, size: item.rect.size)
            l.position = CGPoint(x: item.rect.midX, y: item.rect.midY)
            l.transform = item.mirrored ? CATransform3DMakeScale(-1, 1, 1) : CATransform3DIdentity
            l.opacity = Float(item.alpha)
            l.isHidden = false
        }
        for l in pool.dropFirst(items.count) where !l.isHidden { l.isHidden = true; l.contents = nil }
    }

    // MARK: Crew

    private struct Member {
        let key: String
        let cast: Cast
        let session: SaverFeed.Session
        let agent: SaverFeed.Agent?
        var isLeader: Bool { agent == nil }
        var weapon: Weapon { cast.weapon }
    }

    private struct Placed {
        let m: Member
        var x: CGFloat = 0
        var facing: CGFloat = 1
        var role: FightRole?
    }

    /// The same pairing as the window: only Claudes that are working or thinking fight (idle ones and ones waiting for
    /// you step aside). Han and Greedo face off, Claudes fight Claudes, agents fight agents (saber duels first), a
    /// leftover Claude and agent fight each other, anyone else left over cheers. Then the line is spread across the floor.
    private func crew(_ sessions: [SaverFeed.Session], now t: Double, feet: CGFloat, cards: Bool = true) -> [Item] {
        var members: [Member] = []
        for s in sessions {
            members.append(Member(key: "L:" + s.id, cast: Cast(id: s.cast), session: s, agent: nil))
            for a in s.agents { members.append(Member(key: "A:" + a.id, cast: Cast(id: a.cast), session: s, agent: a)) }
        }
        guard !members.isEmpty else { return [] }

        var pairs: [(Member, Member)] = []
        func pairUp(_ pool: inout [Member]) {
            for saberFirst in [true, false] {
                var k = 0
                while k < pool.count {
                    let ok = { (a: Member, b: Member) in !saberFirst || (a.weapon == .saber && b.weapon == .saber) }
                    guard let m = pool.indices.dropFirst(k + 1).first(where: { ok(pool[k], pool[$0]) }) else { k += 1; continue }
                    pairs.append((pool[k], pool[m]))
                    pool.remove(at: m); pool.remove(at: k)
                }
            }
        }
        let active = { (m: Member) in !m.isLeader || m.session.mood == "working" || m.session.mood == "thinking" }
        var leaders = members.filter { $0.isLeader && $0.weapon != .none && active($0) }
        var agents = members.filter { !$0.isLeader && $0.weapon != .none }
        if let han = (leaders + agents).first(where: { $0.cast.isHan }),
           let greedo = (leaders + agents).first(where: { $0.cast.isGreedo }) {
            pairs.append((han, greedo))
            leaders.removeAll { $0.key == han.key || $0.key == greedo.key }
            agents.removeAll { $0.key == han.key || $0.key == greedo.key }
        }
        pairUp(&leaders)
        pairUp(&agents)
        if let v = leaders.first, let a = agents.first { pairs.append((v, a)); leaders.removeFirst(); agents.removeFirst() }
        let cheering = pairs.isEmpty ? Set<String>() : Set((agents + leaders).map(\.key))
        let paired = Set(pairs.flatMap { [$0.0.key, $0.1.key] })
        let order = Dictionary(uniqueKeysWithValues: members.enumerated().map { ($1.key, $0) })
        var groups: [[Member]] = pairs.map { [$0.0, $0.1] } + members.filter { !paired.contains($0.key) }.map { [$0] }
        groups.sort { $0.compactMap { order[$0.key] }.min()! < $1.compactMap { order[$0.key] }.min()! }

        // Sizes: the crew's pixels match the place's, agents a little smaller; everyone shrinks if the line won't fit.
        var ls = P, cs = max(1, (P * 0.7).rounded())
        var placed: [Placed] = []
        while true {
            placed = layout(groups, ls: ls, cs: cs)
            let span = (placed.map(\.x).max() ?? 0) - (placed.map(\.x).min() ?? 0) + 40 * ls
            if span <= bounds.width * 0.94 || ls <= 1 { break }
            ls -= 1; cs = max(1, (ls * 0.7).rounded())
        }
        // Centre the line, then spread the groups out a little if there's room to spare.
        let minX = placed.map(\.x).min() ?? 0, maxX = placed.map(\.x).max() ?? 0
        let shift = (bounds.width - (maxX - minX)) / 2 - minX
        for i in placed.indices { placed[i].x += shift }

        var roles: [String: FightRole] = [:]
        var incoming: [String: Double] = [:]
        var fights: [(Placed, Placed)] = []
        for (a, b) in pairs {
            guard let pa = placed.first(where: { $0.m.key == a.key }), let pb = placed.first(where: { $0.m.key == b.key }) else { continue }
            let (l, r) = pa.x <= pb.x ? (pa, pb) : (pb, pa)
            let (lr, rr) = fightRoles(l.m.weapon, r.m.weapon)
            roles[l.m.key] = lr; roles[r.m.key] = rr
            fights.append((l, r))
            if case .shoot(let lo) = lr, case .shoot(let ro) = rr { incoming[l.m.key] = ro; incoming[r.m.key] = lo }
        }
        for key in cheering { roles[key] = .cheer }

        var items: [Item] = []
        let base = feet - 8 * ls       // canvas bottom for a leader: its feet are 8 rows up
        // Agents first, so leaders (and their sabers) draw on top.
        for p in placed.sorted(by: { !$0.m.isLeader && $1.m.isLeader }) {
            let s = p.m.isLeader ? ls : cs
            let c = PixelCanvas(Sprite.width, Sprite.height)
            let role = roles[p.m.key]
            if p.m.isLeader {
                let sess = p.m.session
                p.m.cast.draw(c, t: t, mode: role != nil ? .working : mode(sess), walking: false, role: role ?? .none,
                              urgent: sess.urgent && role == nil, sitting: sess.sitting && role == nil, asSession: true)
            } else {
                let phase = Double(abs(p.m.key.hashValue % 100)) / 37
                p.m.cast.draw(c, t: role != nil ? t : t + phase, mode: .working, walking: false, role: role ?? .none, asSession: false)
            }
            c.addOutline(AIStyle.outline(p.m.session.assistant))
            guard let img = c.makeImage() else { continue }
            let mirrored = p.facing < 0
            let bodyX = (mirrored ? CGFloat(Sprite.width) - CGFloat(Sprite.bodyCenterX) : CGFloat(Sprite.bodyCenterX)) * s
            let duck = incoming[p.m.key].map { CGFloat(duckAmount(t: t, shooterOffset: $0, armoured: p.m.cast.armoured)) } ?? 0
            let y = p.m.isLeader ? base : base + (ls - cs) * 8
            items.append(Item(image: img, rect: CGRect(x: (p.x - bodyX).rounded(), y: y, width: CGFloat(Sprite.width) * s,
                                                       height: (CGFloat(Sprite.height) * s * (1 - 0.22 * duck)).rounded()),
                              mirrored: mirrored))
        }
        // Bolts, deflections, lightning and sparks.
        for (l, r) in fights {
            guard fightFXVisible(t: t, l.m.weapon, r.m.weapon) else { continue }
            let margin = 24.0
            let width = Int(Double((r.x - l.x) / ls) + margin * 2)
            guard width > 0, width < 4000 else { continue }
            let left = l.x - CGFloat(margin) * ls
            func fighter(_ p: Placed, side: Double) -> Fighter {
                let sc = p.m.isLeader ? ls : cs
                let lift = p.m.isLeader ? 0 : (ls - cs) * 8
                return Fighter(weapon: p.m.weapon, x: Double((p.x - left) / ls), k: Double(sc / ls),
                               top: Double((CGFloat(Sprite.height) * (ls - sc) - lift) / ls), side: side, muzzle: p.m.cast.muzzle,
                               armoured: p.m.cast.armoured, pivot: p.m.cast.weaponPivot)
            }
            let c = PixelCanvas(width, Sprite.height)
            drawFightFX(c, t: t, left: fighter(l, side: 1), right: fighter(r, side: -1))
            if let img = c.makeImage() {
                items.append(Item(image: img, rect: CGRect(x: left.rounded(), y: base, width: CGFloat(width) * ls,
                                                           height: CGFloat(Sprite.height) * ls)))
            }
        }
        // The System Settings thumbnail is too small for words: just the crew there.
        if !isPreview { items += board(placed, ls: ls, cs: cs, base: base, now: t, cards: cards) }
        return items
    }

    /// Positions along the floor (body centres), pairs at fighting distance, everyone else a step apart.
    private func layout(_ groups: [[Member]], ls: CGFloat, cs: CGFloat) -> [Placed] {
        // How far each one reaches in front of and behind its body centre, from the window's numbers.
        func reach(_ m: Member) -> (fwd: CGFloat, back: CGFloat) { m.isLeader ? (35 * ls, 17 * ls) : (36 * cs, 14 * cs) }
        let gap = 5 * ls
        var out: [Placed] = []
        var x: CGFloat = 0
        for g in groups {
            if g.count == 2 {
                let (a, b) = (g[0], g[1])
                let sa = a.isLeader ? ls : cs, sb = b.isLeader ? ls : cs
                let ax = x + reach(a).back
                let distance = fightIsCloseQuarters(a.weapon, b.weapon)
                    ? 13.5 * (sa + sb) + 29.7 * min(sa, sb)
                    : reach(a).fwd + reach(b).fwd + gap * 2
                out.append(Placed(m: a, x: ax, facing: 1))
                out.append(Placed(m: b, x: ax + distance, facing: -1))
                x = ax + distance + reach(b).back + gap * 3
            } else {
                let m = g[0]
                // Not fighting: its weapon's reach doesn't need the room.
                out.append(Placed(m: m, x: x + reach(m).back, facing: 1))
                x += reach(m).back * 2 + (m.isLeader ? 10 * ls : 8 * cs) + gap * 2
            }
        }
        return out
    }

    private func mode(_ s: SaverFeed.Session) -> VaderMode {
        switch s.mood {
        case "working": return .working
        case "thinking": return .thinking
        case "waiting": return .waiting
        default: return .idle
        }
    }

    // MARK: Holograms

    /// Colours as in the window: the project's colour for the card, its title, its beam and its name tags; the status
    /// in its own colour (green working, blue thinking, red needs you, purple asleep, grey idle, amber no status).
    private struct Look {
        let accent: NSColor
        let status: String
        let statusColor: NSColor
        let alert: Bool
    }

    private static let dim = NSColor(white: 0.62, alpha: 1), soft = NSColor(white: 0.85, alpha: 1)

    private func look(_ s: SaverFeed.Session, now: Double) -> Look {
        let held = Self.duration(now - s.since)
        let accent = s.accent.map { h in
            NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
        } ?? NSColor(white: 0.5, alpha: 1)
        func l(_ status: String, _ r: CGFloat, _ g: CGFloat, _ b: CGFloat, alert: Bool = false) -> Look {
            Look(accent: accent, status: status, statusColor: NSColor(srgbRed: r, green: g, blue: b, alpha: 1), alert: alert)
        }
        if s.unknown { return l("NO LIVE STATUS", 1, 0.69, 0.24) }
        switch s.mood {
        case "working": return l("◉ WORKING · \(held)", 0.42, 0.9, 0.46)
        case "thinking": return l("◌ THINKING · \(held)", 0.42, 0.71, 1)
        case "waiting": return l((s.urgent ? "⚠ NEEDS YOU! · " : "⚠ NEEDS YOU · ") + held, 1, 0.35, 0.35, alert: true)
        default:
            if s.asleep { return l("z z  ASLEEP · \(held)", 0.63, 0.55, 1) }
            return Look(accent: accent, status: "IDLE · \(held)", statusColor: Self.dim, alert: false)
        }
    }

    /// The sessions left to right as they stand, each with its agents.
    private func lineUp(_ placed: [Placed]) -> [(p: Placed, agents: [Placed])] {
        placed.filter(\.m.isLeader).sorted { $0.x < $1.x }.map { l in
            (l, placed.filter { !$0.m.isLeader && $0.m.session.id == l.m.session.id }.sorted { $0.x < $1.x })
        }
    }

    private func title(_ p: Placed) -> String {
        let s = p.m.session
        let t = s.project.isEmpty ? p.m.cast.name.uppercased() : s.project.uppercased()
        return (s.assistant == "claude" || s.assistant == "claude-desktop" ? "" : s.assistant.uppercased() + " · ") + t
    }

    /// A session's details: title, status, what it's doing, your last prompt, and its agents.
    private func details(_ p: Placed, _ agents: [Placed], lk: Look, size: CGFloat = 1,
                         prompt: Bool = true) -> [Line] {
        let s = p.m.session
        var lines: [Line] = []
        if lk.alert { lines.append(("INCOMING TRANSMISSION", 13 * size, .heavy, lk.statusColor)) }
        lines.append((Self.clip(title(p), 26), 22 * size, .heavy, s.project.isEmpty ? .white : lk.accent))
        lines.append((lk.status + "   " + p.m.cast.name, 14 * size, .semibold, lk.statusColor))
        if let a = s.activity, !a.isEmpty { lines.append(((lk.alert ? "? " : "› ") + Self.clip(a, 40), 15 * size, .medium, Self.soft)) }
        if prompt, let pr = s.prompt, !pr.isEmpty, !lk.alert { lines.append(("“" + Self.clip(pr, 42) + "”", 13 * size, .regular, Self.dim)) }
        for a in agents { lines.append(("  └ " + a.m.cast.name + " · " + Self.clip(a.m.agent?.task ?? "", 30), 13 * size, .medium, Self.soft)) }
        return lines
    }

    private func sized(_ img: CGImage) -> CGSize { CGSize(width: CGFloat(img.width) / scale, height: CGFloat(img.height) / scale) }

    /// A small tag floating over a head.
    private func tag(_ text: String, over p: Placed, top: CGFloat, color: NSColor, avoid bodies: [CGRect],
                     taken: inout [CGRect]) -> Item {
        let img = chip(text, border: color, agent: !p.m.isLeader, big: p.m.isLeader && p.m.session.focused == true), size = sized(img)
        var r = CGRect(x: p.x - size.width / 2, y: top + (shifted ? size.height + 3 * u : 0), width: size.width, height: size.height)
        r.origin.x = min(max(r.minX, 8 * u), bounds.width - r.width - 8 * u)
        // Up past any other tag, and off anyone's head.
        while let hit = (taken.map { $0.insetBy(dx: -3 * u, dy: -2 * u) } + bodies).first(where: { $0.intersects(r) }) {
            r.origin.y = hit.maxY + 3 * u
        }
        taken.append(r)
        return Item(image: img, rect: r, alpha: 0.95, smooth: true)
    }

    /// Where its name tag sits: a fixed three art pixels over the top of this character's head, so characters of
    /// different heights carry their names at different heights.
    private func headTop(_ p: Placed, ls: CGFloat, cs: CGFloat, base: CGFloat) -> CGFloat {
        let k = p.m.isLeader ? ls : cs, feet = p.m.isLeader ? base : base + (ls - cs) * 8
        return feet + CGFloat(Sprite.height - p.m.cast.drawnTop() + 3) * k
    }

    /// The space a character takes up, column by column from its drawn outline (not what floats off it), for keeping
    /// name tags off heads: a box round each character was much wider than most of them, so a tag next to a tall
    /// neighbour was lifted right over it.
    private func body(_ p: Placed, ls: CGFloat, cs: CGFloat, base: CGFloat) -> [CGRect] {
        let k = p.m.isLeader ? ls : cs, feet = p.m.isLeader ? base : base + (ls - cs) * 8
        let mirrored = p.facing < 0
        let left = p.x - (mirrored ? CGFloat(Sprite.width) - CGFloat(Sprite.bodyCenterX) : CGFloat(Sprite.bodyCenterX)) * k
        let profile = p.m.cast.drawnProfile()
        return (0..<Sprite.width).compactMap { col in
            let top = profile[mirrored ? Sprite.width - 1 - col : col]
            guard top < Sprite.height else { return nil }
            return CGRect(x: left + CGFloat(col) * k, y: feet, width: k, height: CGFloat(Sprite.height - top) * k)
        }
    }

    /// The board: a card per session floating over the crew, in the crew's order and at uneven heights, each with a
    /// beam down to the name over its character; the agents are named too. When the cards won't fit side by side they
    /// overlap by half and stack (each beam drops straight down between the lower cards); narrower, they lose the prompt.
    private func board(_ placed: [Placed], ls: CGFloat, cs: CGFloat, base: CGFloat, now: Double, cards show: Bool = true) -> [Item] {
        let crew = lineUp(placed)
        guard !crew.isEmpty else { return [] }
        let looks = crew.map { look($0.p.m.session, now: now) }
        var tags: [Item] = [], taken: [CGRect] = [], targets: [CGRect] = []
        let bodies = placed.flatMap { body($0, ls: ls, cs: cs, base: base) }
        for (i, c) in crew.enumerated() {
            let s = c.p.m.session
            let name = (looks[i].alert ? "⚠ " : "") + Self.clip(s.project.isEmpty ? c.p.m.cast.name : s.project, 16)
            let t = tag(name, over: c.p, top: headTop(c.p, ls: ls, cs: cs, base: base), color: looks[i].accent,
                        avoid: bodies, taken: &taken)
            tags.append(t); targets.append(t.rect)
            for a in c.agents {
                tags.append(tag(a.m.cast.name, over: a, top: headTop(a, ls: ls, cs: cs, base: base),
                                color: looks[i].accent, avoid: bodies, taken: &taken))
            }
        }
        guard show else { return tags }      // the show's crew: names only, nothing to report

        let m = 40 * u, gap = 14 * u, full = 300 * u
        let n = CGFloat(crew.count), span = bounds.width - m * 2
        let stagger = span / n - gap < full
        // One row: n equal slots. Staggered: centres every half-step, so each lower card sits between two upper ones
        // and leaves a gap for their beams.
        let step = stagger ? span / (n + 1) : span / n
        let width = min(360 * u, stagger ? step * 2 - gap * 2 : step - gap)
        let compact = width < full
        let images = crew.indices.map { i in
            hologram(details(crew[i].p, crew[i].agents, lk: looks[i], size: compact ? 0.75 : 0.85, prompt: !compact),
                     color: looks[i].accent, width: width)
        }
        // Heights: a little above the names, each session lifted its own amount (from its id, so it keeps it), and
        // anything that would overlap a card already placed lifted clear of it. Lowest first.
        let tallest = images.map { sized($0).height }.max() ?? 0
        let floor = (taken.map(\.maxY).max() ?? base) + 40 * u + (shifted ? tallest + 16 * u : 0)
        var lift: [Int] = crew.map { c in c.p.m.session.id.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 9973 } % 4 }
        for i in lift.indices.dropFirst() where lift[i] == lift[i - 1] { lift[i] = (lift[i] + 1) % 4 }   // neighbours differ
        var cards = [CGRect](repeating: .zero, count: crew.count), done: [CGRect] = []
        for i in crew.indices.sorted(by: { lift[$0] < lift[$1] }) {
            let size = sized(images[i])
            let cx = m + step * (CGFloat(i) + (stagger ? 1 : 0.5))
            var r = CGRect(x: cx - width / 2, y: floor + CGFloat(lift[i]) * 36 * u, width: width, height: size.height)
            while let hit = done.first(where: { $0.insetBy(dx: 0, dy: -10 * u).intersects(r) }) { r.origin.y = hit.maxY + 12 * u }
            cards[i] = r; done.append(r)
        }
        let bottom = floor - 24 * u                      // the beams drop straight to here, then angle to the name

        var beams: [Item] = [], panels: [Item] = []
        for i in crew.indices {
            let card = cards[i], target = targets[i]
            beams.append(beam([CGPoint(x: card.midX, y: card.minY), CGPoint(x: card.midX, y: bottom),
                               CGPoint(x: target.midX, y: target.maxY + 2 * u)], color: looks[i].accent))
            let alpha = looks[i].alert ? 0.75 + 0.25 * CGFloat(sin(now * 5)) : 0.93
            panels.append(Item(image: images[i], rect: card, alpha: alpha, smooth: true))
        }
        // In the window, the card under the mouse again, half as big again and complete, over everything.
        var zoom: [Item] = []
        if inWindow, let m = mouse, let i = crew.indices.reversed().first(where: { cards[$0].contains(m) }) {
            let img = hologram(details(crew[i].p, crew[i].agents, lk: looks[i], size: (compact ? 0.75 : 0.85) * 1.5),
                               color: looks[i].accent, width: min(width * 1.5, bounds.width - 16 * u))
            let s = sized(img), card = cards[i]
            let x = min(max(card.midX - s.width / 2, 8 * u), bounds.width - s.width - 8 * u)
            let y = min(max(card.midY - s.height / 2, 8 * u), bounds.height - s.height - 8 * u)
            let r = CGRect(x: x, y: y, width: s.width, height: s.height)
            zoom.append(Item(image: solid(), rect: r, alpha: 1, smooth: true))   // nothing showing through it
            zoom.append(Item(image: img, rect: r, alpha: 1, smooth: true))
        }
        return beams + panels + tags + zoom
    }

    /// A thin dashed hologram line through `points`, with a dot where it lands.
    private func beam(_ points: [CGPoint], color: NSColor) -> Item {
        let xs = points.map(\.x), ys = points.map(\.y)
        let r = CGRect(x: xs.min()! - 4 * u, y: ys.min()! - 4 * u,
                       width: xs.max()! - xs.min()! + 8 * u, height: ys.max()! - ys.min()! + 8 * u)
        let key = "beam" + points.map { "\(Int($0.x)),\(Int($0.y))" }.joined(separator: ";") + color.description
        let img = textCache[key] ?? image(r.size) { ctx, _ in
            let local = points.map { CGPoint(x: $0.x - r.minX, y: $0.y - r.minY) }
            ctx.setLineWidth(1.5 * self.u)
            ctx.setStrokeColor(color.withAlphaComponent(0.55).cgColor)
            ctx.setLineDash(phase: 0, lengths: [6 * self.u, 4 * self.u])
            ctx.addLines(between: local); ctx.strokePath()
            ctx.setFillColor(color.withAlphaComponent(0.85).cgColor)
            let end = local.last!
            ctx.fillEllipse(in: CGRect(x: end.x - 3 * self.u, y: end.y - 3 * self.u, width: 6 * self.u, height: 6 * self.u))
        }
        remember(key, img)
        return Item(image: img, rect: r, alpha: 1, smooth: true)
    }

    /// A line of a card: text, size, weight, colour.
    private typealias Line = (String, CGFloat, NSFont.Weight, NSColor)

    /// A card: its lines on a dark panel framed in `color`.
    private func hologram(_ lines: [Line], color: NSColor, width: CGFloat? = nil) -> CGImage {
        let key = "holo" + lines.map { $0.0 + $0.3.description }.joined(separator: "\u{1}") + color.description + "\(u)\(scale)\(width ?? 0)"
        if let hit = textCache[key] { return hit }
        let texts = lines.map { l in
            NSAttributedString(string: l.0, attributes: [.font: NSFont.monospacedSystemFont(ofSize: l.1 * u, weight: l.2),
                                                        .foregroundColor: l.3])
        }
        let pad = 14 * u, lineGap = 6 * u
        let w = width ?? min(max(texts.map { $0.size().width }.max() ?? 0, 180 * u) + pad * 2, 560 * u)
        let h = texts.reduce(pad * 2 - lineGap) { $0 + $1.size().height + lineGap }
        let img = image(CGSize(width: w, height: h)) { ctx, size in
            let r = CGRect(origin: .zero, size: size)
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 0.86)); ctx.fill(r)
            ctx.setStrokeColor(color.withAlphaComponent(0.75).cgColor); ctx.setLineWidth(2 * u); ctx.stroke(r.insetBy(dx: u, dy: u))
            ctx.setFillColor(color.cgColor)
            let cw = 12 * u, chh = 3 * u
            for (x, y) in [(r.minX, r.minY), (r.maxX - cw, r.minY), (r.minX, r.maxY - chh), (r.maxX - cw, r.maxY - chh)] {
                ctx.fill(CGRect(x: x, y: y, width: cw, height: chh))
            }
            var y = size.height - pad
            for t in texts {
                y -= t.size().height
                t.draw(with: CGRect(x: pad, y: y, width: size.width - pad * 2, height: t.size().height),
                       options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
                y -= lineGap
            }
            ctx.setFillColor(color.withAlphaComponent(0.04).cgColor)
            var sy: CGFloat = 0
            while sy < size.height { ctx.fill(CGRect(x: 0, y: sy, width: size.width, height: 1.5 * u)); sy += 4 * u }
        }
        remember(key, img)
        return img
    }

    /// A name tag as the window draws them: white on dark (bluish for agents), rounded, framed in the project's colour.
    /// `big`: the project you're in, its name 15% larger.
    private func chip(_ s: String, border: NSColor, agent: Bool, big: Bool = false) -> CGImage {
        let key = "chip" + s + border.description + "\(agent)\(big)\(u)\(scale)"
        if let hit = textCache[key] { return hit }
        let t = NSAttributedString(string: Self.clip(s, 28), attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: (agent ? 12 : 13) * u * (big ? 1.15 : 1), weight: agent ? .semibold : .bold),
            .foregroundColor: NSColor.white])
        let ts = t.size()
        let img = image(CGSize(width: ts.width + 16 * u, height: ts.height + 6 * u)) { ctx, size in
            let box = CGPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 0.75 * self.u, dy: 0.75 * self.u),
                             cornerWidth: 4 * self.u, cornerHeight: 4 * self.u, transform: nil)
            ctx.addPath(box)
            ctx.setFillColor(agent ? CGColor(srgbRed: 0.05, green: 0.10, blue: 0.24, alpha: 0.82) : CGColor(gray: 0.08, alpha: 0.82))
            ctx.fillPath()
            ctx.addPath(box)
            ctx.setStrokeColor(border.withAlphaComponent(0.9).cgColor); ctx.setLineWidth(1.5 * self.u)
            ctx.strokePath()
            t.draw(at: NSPoint(x: 8 * self.u, y: 3 * self.u))
        }
        remember(key, img)
        return img
    }

    // MARK: HUD

    private static let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)

    /// The place and a head count top left, a clock top right, and what happened lately crawling along the bottom.
    private func hud(_ feed: SaverFeed?, location: Location, now: Double, idle: Bool = false) -> [Item] {
        var items: [Item] = []
        let m = 48 * u
        let sessions = feed?.sessions ?? []
        let agents = sessions.reduce(0) { $0 + $1.agents.count }, waiting = sessions.filter { $0.mood == "waiting" }.count
        var counts = ["\(sessions.count) SESSION\(sessions.count == 1 ? "" : "S")"]
        if agents > 0 { counts.append("\(agents) AGENT\(agents == 1 ? "" : "S")") }
        if waiting > 0 { counts.append("\(waiting) NEED\(waiting == 1 ? "S" : "") YOU") }
        let place = text([(location.name.uppercased(), inWindow ? 27 : 18, .heavy, NSColor(white: 0.88, alpha: 1), inWindow ? 6 : 4),
                          (idle ? "CLAWD WARS ISN'T RUNNING  ·  OPEN IT TO BRING YOUR CREW"
                                : feed == nil ? "" : counts.joined(separator: "  ·  "), 14, .semibold, NSColor(white: 0.65, alpha: 1), 2)],
                         right: shifted)
        let ps = sized(place)
        if !isPreview {
            items.append(Item(image: place, rect: rectFor(place, x: shifted ? bounds.width - m - ps.width : m, top: bounds.height - m * 0.9),
                              alpha: 0.95, smooth: true))
        }

        // The clock (not in the window: the menu bar has one).
        if !inWindow {
            let date = Date(timeIntervalSince1970: now)
            let f = DateFormatter()
            f.dateFormat = DateFormatter.dateFormat(fromTemplate: "jmm", options: 0, locale: .current)
            let clockFont = NSFont(name: "Futura-CondensedExtraBold", size: 96 * u) ?? .boldSystemFont(ofSize: 90 * u)
            f.locale = .current
            let day = DateFormatter()
            day.dateFormat = "EEEE d MMMM"
            let clock = text([(f.string(from: date), 0, .heavy, Self.yellow, 4)], font: clockFont,
                             second: (day.string(from: date).uppercased(), 14, .semibold, Self.yellow.withAlphaComponent(0.7), 3),
                             right: !shifted)
            let cs = CGSize(width: CGFloat(clock.width) / scale, height: CGFloat(clock.height) / scale)
            items.append(Item(image: clock, rect: CGRect(x: shifted ? m : bounds.width - m - cs.width, y: bounds.height - m * 0.6 - cs.height,
                                                         width: cs.width, height: cs.height), alpha: 0.95, smooth: true))
        }

        // The ticker: newest last, scrolling right to left.
        if let events = feed?.events, !events.isEmpty, !isPreview {
            let line = events.suffix(8).map { "◆ " + $0.text }.joined(separator: "        ")
            let strip = ticker(line)
            let size = CGSize(width: CGFloat(strip.width) / scale, height: CGFloat(strip.height) / scale)
            let speed = 60 * u
            let travel = size.width + bounds.width
            let x = bounds.width - CGFloat((now * Double(speed)).truncatingRemainder(dividingBy: Double(travel)))
            items.append(Item(image: tickerBar(), rect: CGRect(x: 0, y: 0, width: bounds.width, height: 44 * u), alpha: 1, smooth: true))
            items.append(Item(image: strip, rect: CGRect(x: x.rounded(), y: (44 * u - size.height) / 2, width: size.width, height: size.height),
                              alpha: 1, smooth: true))
        }
        return items
    }

    /// The show's crew for `place`: four to six characters in all, light against dark where it can, a local or two
    /// among them (whoever calls the place home), up to two of them agents at someone's side.
    private func cast(for place: Location, now: Double) -> [SaverFeed.Session] {
        let armed = (Array(0..<Leader.allCases.count) + Companion.allCases.map { StatusStore.heroBase + $0.rawValue })
            .filter { Cast(id: $0).weapon != .none }
        let locals = armed.filter { Cast(id: $0).home == place }.shuffled().prefix(2)
        var dark = armed.filter { StatusStore.isDark($0) && !locals.contains($0) }.shuffled()
        var light = armed.filter { !StatusStore.isDark($0) && !locals.contains($0) }.shuffled()
        for id in locals.reversed() { if StatusStore.isDark(id) { dark.insert(id, at: 0) } else { light.insert(id, at: 0) } }
        // Alternating sides, so each pair is a duel across them (the local first, whichever side it's on).
        var darkTurn = locals.first.map(StatusStore.isDark) ?? Bool.random()
        var leaders: [Int] = []
        let everyone = Int.random(in: 4...6), helpers = Int.random(in: 0...2)
        for _ in 0..<(everyone - helpers) {
            if darkTurn, !dark.isEmpty { leaders.append(dark.removeFirst()) } else if !light.isEmpty { leaders.append(light.removeFirst()) }
            darkTurn.toggle()
        }
        var spare = (dark + light).shuffled()
        let palette: [UInt32] = [0xFF8A3D, 0x3DD6FF, 0xFF4FD8, 0x9BE84A, 0xFFD23D, 0xA57BFF, 0x2EE6B0, 0xFF6B6B].shuffled()
        var owners = Array(leaders.indices.shuffled().prefix(helpers))
        return leaders.enumerated().map { i, id in
            var agents: [SaverFeed.Agent] = []
            if let k = owners.firstIndex(of: i), !spare.isEmpty {
                owners.remove(at: k)
                agents.append(SaverFeed.Agent(id: "show-a\(i)", cast: spare.removeFirst(), task: ""))
            }
            return SaverFeed.Session(id: "show-\(i)", cast: id, assistant: "claude", project: "", accent: palette[i % palette.count],
                                     mood: "working", since: now, agents: agents)
        }
    }

    private func ticker(_ s: String) -> CGImage {
        let key = "tick" + s + "\(u)\(scale)"
        if let hit = textCache[key] { return hit }
        let t = NSAttributedString(string: s, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 16 * u, weight: .semibold), .foregroundColor: Self.yellow, .kern: 0.5])
        let img = image(t.size()) { _, _ in t.draw(at: .zero) }
        remember(key, img)
        return img
    }

    private func shade() -> CGImage {
        if let hit = textCache["shade"] { return hit }
        let img = image(CGSize(width: 8, height: 256)) { ctx, size in
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                               colors: [CGColor(gray: 0, alpha: 0), CGColor(gray: 0, alpha: 0.55)] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        remember("shade", img)
        return img
    }

    /// The cards' dark, opaque: under the enlarged card.
    private func solid() -> CGImage {
        if let hit = textCache["solid"] { return hit }
        let img = image(CGSize(width: 4, height: 4)) { ctx, size in
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1)); ctx.fill(CGRect(origin: .zero, size: size))
        }
        remember("solid", img)
        return img
    }

    private func tickerBar() -> CGImage {
        let key = "bar\(u)\(scale)"
        if let hit = textCache[key] { return hit }
        let img = image(CGSize(width: 8, height: 44 * u)) { ctx, size in
            ctx.setFillColor(CGColor(gray: 0, alpha: 0.55)); ctx.fill(CGRect(origin: .zero, size: size))
        }
        remember(key, img)
        return img
    }

    /// Lines of text stacked top to bottom: (string, size, weight, colour, kern).
    private func text(_ lines: [(String, CGFloat, NSFont.Weight, NSColor, CGFloat)], font: NSFont? = nil,
                      second: (String, CGFloat, NSFont.Weight, NSColor, CGFloat)? = nil, right: Bool = false) -> CGImage {
        let all = lines + (second.map { [$0] } ?? [])
        let key = "text" + all.map { $0.0 }.joined(separator: "\u{1}") + "\(u)\(scale)\(right)"
        if let hit = textCache[key] { return hit }
        let texts = all.enumerated().filter { !$0.element.0.isEmpty }.map { i, l in
            NSAttributedString(string: l.0, attributes: [
                .font: i == 0 && font != nil ? font! : NSFont.monospacedSystemFont(ofSize: l.1 * u, weight: l.2),
                .foregroundColor: l.3, .kern: l.4 * u])
        }
        let w = texts.map { $0.size().width }.max() ?? 1, gap = 6 * u
        let h = texts.reduce(-gap) { $0 + $1.size().height + gap }
        let img = image(CGSize(width: w, height: max(h, 1))) { _, size in
            var y = size.height
            for t in texts {
                y -= t.size().height
                t.draw(at: NSPoint(x: right ? size.width - t.size().width : 0, y: y))
                y -= gap
            }
        }
        if textCache.count > 400 { textCache.removeAll() }
        textCache[key] = img
        return img
    }

    private func rectFor(_ img: CGImage, x: CGFloat, top: CGFloat) -> CGRect {
        let size = CGSize(width: CGFloat(img.width) / scale, height: CGFloat(img.height) / scale)
        return CGRect(x: x, y: top - size.height, width: size.width, height: size.height)
    }

    private func remember(_ key: String, _ img: CGImage) {
        if textCache.count > 400 { textCache.removeAll() }   // timers and prompts change; don't keep every look
        textCache[key] = img
    }

    /// Draw into an image at the display's resolution (`size` in points).
    private func image(_ size: CGSize, _ draw: (CGContext, CGSize) -> Void) -> CGImage {
        let k = scale
        let w = max(1, Int((size.width * k).rounded(.up))), h = max(1, Int((size.height * k).rounded(.up)))
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: k, y: k)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        draw(ctx, size)
        NSGraphicsContext.restoreGraphicsState()
        return ctx.makeImage()!
    }

    private static func clip(_ s: String, _ n: Int) -> String { s.count > n ? String(s.prefix(n - 1)) + "…" : s }

    /// "12s" for the first minute, then "3m", "2h 4m": as the window shows it.
    private static func duration(_ secs: Double) -> String {
        let s = max(0, Int(secs))
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }
}
