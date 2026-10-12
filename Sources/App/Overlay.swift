import AppKit
import ServiceManagement
import UserNotifications

/// Borderless, transparent, never-key panel that floats above every app (and full-screen spaces).
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

/// One character on screen. Positions are screen coordinates of the body centre.
private struct Actor {
    enum Kind { case leader(Cast), agent(Cast) }   // a whole session (drawn large) or an agent (small)
    let key: String
    var kind: Kind
    var x: CGFloat
    var targetX: CGFloat
    var facing: CGFloat          // +1 right, -1 left while standing
    var walkDir: CGFloat = 0     // non-zero while walking
    let born: Double
    var leaving: Double?
    let phase: Double
    var mood: Mood = .idle
    var mode: VaderMode = .idle
    var label = ""
    var pid: Int32?              // the Claude process (an agent carries its parent's)
    var assistant = "claude"     // which AI (its list group, e.g. "claude-desktop"): sets the outline colour; agents carry their session's
    var bubble: BubbleKind?
    var urgent = false           // "needs you" ignored for over a minute
    var accent: NSColor?         // project colour, shared with its agents
    var focused = false          // its terminal is the one in front
    var sitting = false          // idle 2+ minutes: sat down on the floor
    var detail: [String] = []    // hover card lines
    var exit: (landX: CGFloat, dir: CGFloat, startX: CGFloat)?   // Han's departure on the Falcon

    var isLeader: Bool { if case .leader = kind { return true } else { return false } }
    var cast: Cast { switch kind { case .leader(let c), .agent(let c): return c } }
}

private struct Fight { let a: String, b: String }

private let fadeIn = 0.5
private let fadeOut = 0.6
private let falconExit = 6.0      // Han's agent finishing: the Falcon lands, he boards, it flies off
private let fightLinger = 3.0      // keep fighting through brief gaps between tool calls

final class OverlayController: NSObject, NSMenuDelegate, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let panel: OverlayPanel
    private let view: OverlayView
    private var sessions: [SessionSnapshot] = []
    private var actors: [Actor] = []
    private var fights: [Fight] = []
    private var cheering: Set<String> = []
    /// Han shoots first (`GreedoShot`): who's who, when Han fired (it plays out from there) and Greedo's line after.
    private var greedoShot: (han: String, greedo: String, start: Double, line: String)?
    private var nextGreedoShot: Double?
    private var fightUntil: [String: Double] = [:]
    private var home = NSPoint.zero    // Vader's resting spot (between his feet)
    private var demo = CommandLine.arguments.contains("--demo")
    private var demoStart = 0.0
    // Playground: villains picked from the menu, in the order added (which decides who fights whom).
    private var playground: [Int]? = CommandLine.arguments.first { $0.hasPrefix("--playground=") }
        .map { $0.dropFirst(13).split(separator: ",").compactMap { Int($0) } }
    private var playgroundAgents: [Int] = CommandLine.arguments.first { $0.hasPrefix("--agents=") }
        .map { $0.dropFirst(9).split(separator: ",").compactMap { Int($0) } } ?? []
    /// `--ais=claude,codex`: which AI each playground session belongs to (cycled), to check outlines and grouping.
    private let playgroundAIs: [String] = CommandLine.arguments.first { $0.hasPrefix("--ais=") }
        .map { $0.dropFirst(6).split(separator: ",").map(String.init) } ?? []
    /// `--projects=clawd-wars,clawd-wars,tasuke`: each playground session's project (cycled), to check project trees.
    private let playgroundProjects: [String] = CommandLine.arguments.first { $0.hasPrefix("--projects=") }
        .map { $0.dropFirst(11).split(separator: ",").map(String.init) } ?? []
    private var playgroundMood: Mood = CommandLine.arguments.first { $0.hasPrefix("--mood=") }
        .flatMap { Mood(rawValue: String($0.dropFirst(7))) } ?? .working
    private var dragging = false
    private var dragOffset = NSPoint.zero
    private var lastTick = Date().timeIntervalSince1970
    private let start = Date().timeIntervalSince1970
    private var frameCount = 0
    private static let forcedHover = ProcessInfo.processInfo.environment["CLAWD_HOVER"]   // read once: it showed up in profiles
    private var refitting = false
    private let debug = ProcessInfo.processInfo.environment["VADER_DEBUG"] != nil
    private var lastDebug = 0
    private var processes: [ClaudeProcesses.Info] = []
    private var lastScan = 0.0
    private var cpuSamples: [Int32: (at: Double, cpu: Double)] = [:]
    private var busyUntil: [Int32: Double] = [:]
    var items: [DrawItem] = []
    // Status debounce (from agent-view): a new mood must hold for 2 refreshes, except "needs you", which is instant.
    private var debounce: [String: (confirmed: Mood, pending: Mood?, ticks: Int)] = [:]
    private var moodSince: [String: Double] = [:]
    private var focusedPid: Int32?
    private var focusCandidate: Int32??         // a different answer seen once; adopted if it repeats
    private var lastFocusCheck = 0.0
    private var lastShot = 0.0
    // Chaos test (--chaos[=seconds]): random sessions/agents/moods, with layout invariants checked continuously.
    private let chaosSeconds: Double? = CommandLine.arguments.first { $0.hasPrefix("--chaos") }
        .map { arg in arg.split(separator: "=").count == 2 ? Double(arg.split(separator: "=")[1]) ?? 120 : 120 }
    private var chaos: [SessionSnapshot] = []
    private var chaosAgentSerial = 0
    private var violations: [String: (count: Int, examples: [String])] = [:]
    private var walkingSince: [String: Double] = [:]
    private var missingSince: [String: Double] = [:]
    private var lastCheck = 0.0
    private var hasLaidOut = false          // after the first layout, newcomers walk in instead of appearing
    private var hoveredKey: String?
    private var busySince: [Int32: Double] = [:]
    private var offlineReason: String?
    private var lastHookCheck = 0.0
    private var hooksInstalled = true
    /// Something the user has to do so an AI that's on this Mac reports to us. Only AIs actually installed count.
    struct HookIssue { let text: String; let install: String?; let pid: Int32? }   // install = AI to hook up; pid = session to jump to
    private var hookIssues: [HookIssue] = []
    private var hooksSince: [String: Double] = [:]  // assistant → when its hook file last changed (only if our hooks are in it)
    private var missingHooks: [String] = []          // AIs on this Mac without our hooks
    /// AIs you've said you don't use with Clawd Wars: installed, not connected, and no reminders about it. Connecting
    /// one (Settings or the menu) takes it off the list; removing its hooks from Settings puts it on.
    static var ignoredHooks: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "ignoredHooks") ?? []) }
        set { UserDefaults.standard.set(newValue.sorted(), forKey: "ignoredHooks") }
    }
    private var notifiedSilent: Set<Int32> = []
    private var seenBusy: Set<Int32> = []            // pids seen working (a turn ran, so a working hook would have fired)
    private var reported: Set<Int32> = []            // pids whose hooks have fired: their hooks work, even once SessionEnd drops the record
    private var lastLive: [Int32: Double] = [:]      // when each pid last had a live record
    private let shotPath = ProcessInfo.processInfo.environment["CLAWD_SHOT"]     // "%d" in the path → numbered frames
    private let shotEvery = Double(ProcessInfo.processInfo.environment["CLAWD_SHOT_EVERY"] ?? "") ?? 5
    private var shotCount = 0
    private let dismissAfter = Double(ProcessInfo.processInfo.environment["CLAWD_DISMISS_AFTER"] ?? "")   // debug: Playground agents finish
    private var clawdWindow: ClawdWindow?
    private var windowMode: Bool {
        get { UserDefaults.standard.object(forKey: "windowMode") as? Bool ?? true }   // the window, until you choose
        set { UserDefaults.standard.set(newValue, forKey: "windowMode") }
    }

    /// The chosen size, shrunk in window mode when the crew is too wide for the window.
    private var zoom: CGFloat {
        get { windowMode ? Self.windowZoom * windowFit : baseZoom }
        set { UserDefaults.standard.set(newValue, forKey: "zoom") }
    }
    /// Window mode always uses the Small size (the scene backdrop's pixels match it: 2 pt).
    private static let windowZoom: CGFloat = 0.67
    /// Desktop size: Small until one is chosen.
    private var baseZoom: CGFloat { let z = UserDefaults.standard.double(forKey: "zoom"); return z > 0 ? z : 0.67 }
    private var windowFit: CGFloat = 1

    /// Project names over the Claudes, remembered per mode: on by default on the desktop, off in the window
    /// (its cards already name every project). Agents' task labels always show.
    private var showLabels: Bool {
        get { UserDefaults.standard.object(forKey: windowMode ? "labelsWindow" : "labels") as? Bool ?? !windowMode }
        set { UserDefaults.standard.set(newValue, forKey: windowMode ? "labelsWindow" : "labels") }
    }

    // Layout constants in points at zoom 1.
    private static let leaderScale: CGFloat = 3
    private static let companionScale: CGFloat = 2
    private static let leaderReach: (fwd: CGFloat, back: CGFloat) = (105, 50)
    private static let agentReach: (fwd: CGFloat, back: CGFloat) = (72, 28)
    private static let gap: CGFloat = 8
    /// How long a Claude keeps fighting after it stops working or thinking.
    private static let fightLinger: Double = 5
    private static let duelDistance: CGFloat = 170
    private static let walkSpeed: CGFloat = 150
    /// Example agent tasks for the Playground and Demo Mode.
    private static let sampleTasks = ["Find hook events", "Review Overlay.swift", "Run the test suite", "Plan the refactor",
                                      "Search for usages", "Fix failing build", "Write changelog", "Audit permissions",
                                      "Explore codebase", "Check git history", "Draft README", "Profile CPU usage",
                                      "Verify the fix"]
    /// Canvas rows under the feet that may hang off the bottom of the screen: 8 empty rows minus the one
    /// holding the feet's white outline, which should sit on the screen edge, not just below it.
    private static let footroom: CGFloat = 7 * leaderScale

    override init() {
        // The hook only knows the cast sizes; a villain or hero added without bumping them would never be picked.
        assert(StatusStore.leaderCount == Leader.allCases.count && StatusStore.companionCount == Companion.allCases.count)
        panel = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        view = OverlayView()
        super.init()
        view.controller = self
        // Menus in the top bar need a Dock icon. Without "Show Dock Icon", the window still gets them while it's in front.
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateFrontPolicy(active: true)
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateFrontPolicy(active: false)
        }
        // A monitor unplugged, the lid closed, a resolution or arrangement change: put the crew back on a screen.
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.screensChanged()
        }
        // Nothing to draw for while the displays sleep or the screen is locked (the desktop panel still counts as visible).
        let ws = NSWorkspace.shared.notificationCenter
        for (name, asleep) in [(NSWorkspace.screensDidSleepNotification, true), (NSWorkspace.screensDidWakeNotification, false),
                               (NSWorkspace.sessionDidResignActiveNotification, true), (NSWorkspace.sessionDidBecomeActiveNotification, false)] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.screensAsleep = asleep }
        }
        // Set early, so clicking a notification left over from an earlier run still reaches us. Needs an app bundle.
        if Bundle.main.bundleIdentifier != nil { UNUserNotificationCenter.current().delegate = self }

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentView = view

        home = clampHome(savedHome())     // re-applies the edge snap, so positions saved under older rules are corrected
        if windowMode { openWindow() }
        refreshStatus()
        snapActors()
        tick()
        if !windowMode { panel.orderFrontRegardless() }
        installStatusItem()
        applyDockPolicy()
        offerHooksOnFirstLaunch()

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refreshStatus() }
        let frame = Timer(timeInterval: 1.0 / 15, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(frame, forMode: .common)
    }

    // MARK: Placement

    private func savedHome() -> NSPoint {
        let d = UserDefaults.standard
        if d.object(forKey: "anchorX") != nil {
            let p = NSPoint(x: d.double(forKey: "anchorX"), y: d.double(forKey: "anchorY"))
            let feet = NSPoint(x: p.x, y: p.y + Self.footroom * zoom)
            if NSScreen.screens.contains(where: { $0.frame.insetBy(dx: -20, dy: -20).contains(feet) }) { return p }
        }
        let mouse = NSEvent.mouseLocation
        // No screen at all (a headless Mac, or the lid closed at login): any spot will do until one appears.
        guard let vf = (NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        else { return NSPoint(x: 200, y: 0) }
        return NSPoint(x: vf.maxX - 140 * zoom, y: vf.minY - Self.footroom * zoom)
    }

    private func screensChanged() {
        guard !windowMode else { return }   // the window keeps itself on screen
        home = clampHome(savedHome())
        relayout()
        snapActors()
    }

    private func saveHome() {
        UserDefaults.standard.set(home.x, forKey: "anchorX")
        UserDefaults.standard.set(home.y, forKey: "anchorY")
    }

    /// The screen the crew is standing on. `p` is the home point (bottom of the canvas); the feet are
    /// `footroom` above it, and that's what counts — the empty rows under the feet may hang off the edge.
    private func screen(at p: NSPoint) -> NSScreen? {
        let feet = NSPoint(x: p.x, y: p.y + Self.footroom * zoom + 1)
        return NSScreen.screens.first { $0.frame.contains(feet) } ?? NSScreen.main
    }

    /// Keep the lead villain fully on its screen, with the feet allowed right down to the bottom edge.
    /// While dragging, the screen under the cursor wins, so on stacked monitors the crew can stand on the
    /// bottom edge of the upper one instead of tipping over onto the lower one. Feet dropped within
    /// 12 pt of a bottom edge snap onto it.
    private func clampHome(_ p: NSPoint, cursor: NSPoint? = nil) -> NSPoint {
        let byCursor = cursor.flatMap { c in NSScreen.screens.first { $0.frame.contains(c) } }
        guard let f = (byCursor ?? screen(at: p) ?? NSScreen.main)?.frame else { return p }
        let s = Self.leaderScale * zoom
        let floor = f.minY - Self.footroom * zoom
        var y = min(max(p.y, floor), f.maxY - CGFloat(Sprite.height) * s)
        if y - floor < 12 { y = floor }
        return NSPoint(x: min(max(p.x, f.minX + 18 * s), f.maxX - 18 * s), y: y)
    }

    /// Where the crew stands. On the desktop: the screen under the saved spot. In window mode: the
    /// window's scene strip, so the same layout and drawing code works in both.
    private var stage: NSRect {
        if windowMode, let w = clawdWindow { return w.sceneScreenRect }
        return screen(at: home)?.frame ?? NSRect(x: -1e5, y: 0, width: 2e5, height: 1e5)
    }

    /// The first villain's spot (bottom of its canvas).
    private var anchor: NSPoint {
        guard windowMode else { return home }
        let st = stage
        return NSPoint(x: st.minX + 60 * zoom, y: st.minY + windowFloor - Self.footroom * zoom)
    }

    /// Where the window's scene is set: chosen in the Location menu, Random (somewhere new every ten minutes), or
    /// (Automatic) the home of the first-spawned Claude — Vader on the Death Star, Boba at the sarlacc pit, Jabba in
    /// his palace…
    var location: Location {
        let raw = UserDefaults.standard.string(forKey: "location")
        if raw == Self.randomLocation { return randomPlace() }
        if let raw, let l = Location(rawValue: raw) { return l }
        return sessions.first.map { Cast(id: $0.leader).home } ?? .cantina
    }

    static let randomLocation = "random"
    private var random: (place: Location, slot: Int)?

    /// The Random location: a new place (never the one before) at each ten minutes of the clock.
    private func randomPlace() -> Location {
        let slot = Int(Date().timeIntervalSince1970 / 600)
        if let r = random, r.slot == slot { return r.place }
        let place = Location.allCases.filter { $0 != random?.place }.randomElement() ?? .cantina
        random = (place, slot)
        return place
    }

    /// Height of the cantina floor in the window's scene strip; feet stand a little way into it.
    static let cantinaFloor: CGFloat = 20
    var windowFloor: CGFloat { 16 }

    // MARK: Status

    private func refreshStatus() {
        let now = Date().timeIntervalSince1970
        if chaosSeconds != nil {
            offlineReason = nil
            sessions = chaosStep(now)
        } else if let playground {
            offlineReason = nil
            if let d = dismissAfter, now - start > d { playgroundAgents = [] }
            sessions = playgroundSessions(playground)
        } else if demo {
            offlineReason = nil
            sessions = demoSessions(now - demoStart)
        } else {
            if lastScan == 0 {
                // The first scan is done here and now, so the crew is there from the first frame.
                lastScan = now
                if let found = ClaudeProcesses.runningOrNil() { processes = found; sampleCPU(now, cpu: Self.cpuTimes(found)) }
            } else if now - lastScan > 3 && !scanning {
                // Later ones run in the background: a process scan is a handful of system calls per process, and the
                // main thread draws the animation. Only this queue ever calls `runningOrNil` after the first scan.
                lastScan = now
                scanning = true
                Self.scanQueue.async { [weak self] in
                    let found = ClaudeProcesses.runningOrNil()
                    let cpu = found.map(Self.cpuTimes) ?? [:]
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.scanning = false
                        // A failed scan keeps the last list rather than dropping every session.
                        guard let found else { return }
                        self.processes = found
                        self.sampleCPU(Date().timeIntervalSince1970, cpu: cpu)
                    }
                }
            }
            let file = StatusStore.load()   // read once: it also tells us whether the file is readable
            sessions = StatusStore.snapshot(file ?? StatusFile(), now: now, processes: processes)
            // A session that quits drops its record at SessionEnd, but the process lingers a moment while it shuts down.
            // Don't let it come back as a new character (a fresh villain walking in only to fade out): it has left.
            for s in sessions where s.live { if let pid = s.pid { lastLive[pid] = now } }
            sessions.removeAll { s in !s.live && s.pid.flatMap { lastLive[$0] }.map { now - $0 < 30 } ?? false }
            lastLive = lastLive.filter { now - $0.value < 30 }
            // Sessions without hooks can't report status, but a busy Claude burns CPU (idle ≈ 0.3%,
            // working ≈ 5–10%), so treat sustained CPU as "working" for them.
            for i in sessions.indices where !sessions[i].live {
                if let pid = sessions[i].pid, (busyUntil[pid] ?? 0) > now { sessions[i].mood = .working }
            }
            // Not reporting: the hooks say idle, but the process has been busy for over a minute and no
            // agent has reported in that time — the hooks have stopped firing for it.
            for i in sessions.indices where sessions[i].live {
                guard let pid = sessions[i].pid, let rec = sessions[i].record, rec.state == "idle",
                      let busy = busySince[pid], now - busy > 60, now - rec.updated > 60,
                      !sessions[i].agents.contains(where: { now - $0.lastSeen < 60 }) else { continue }
                sessions[i].stalled = true
            }
            // No hook fires when a permission request is approved, so "waiting" would last the whole tool run.
            // CPU busy for two samples in a row (about 6 s) since the request went up means it's running again.
            for i in sessions.indices where sessions[i].mood == .waiting {
                guard let pid = sessions[i].pid, let asked = sessions[i].record?.since, let busy = busySince[pid],
                      busy > asked, now - busy >= 6, (busyUntil[pid] ?? 0) > now else { continue }
                sessions[i].mood = .working
            }
            if now - lastHookCheck > 10 {
                lastHookCheck = now
                hooksInstalled = HookInstaller.isInstalled
                func changed(_ url: URL) -> Double? {
                    (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date)?.timeIntervalSince1970
                }
                hooksSince = [:]
                missingHooks = []
                if hooksInstalled { hooksSince["claude"] = changed(HookInstaller.settingsURL) }
                else if HookInstaller.claudeAvailable { missingHooks.append("claude") }
                for ai in HookInstaller.others where HookInstaller.available(ai) {
                    if HookInstaller.installed(ai) { hooksSince[ai.name] = changed(ai.file) } else { missingHooks.append(ai.name) }
                }
            }
            // A session that started after our hooks were in place and has run a turn, but never reported, has its
            // hook switched off — for Codex that means it hasn't been approved in /hooks yet.
            // A session that quits drops its record at SessionEnd but lingers (busy) for a moment while it shuts down:
            // having reported once, it isn't silent.
            let startedAt = Dictionary(processes.map { ($0.pid, $0.started) }, uniquingKeysWith: { a, _ in a })
            reported.formUnion(sessions.filter(\.live).compactMap(\.pid))
            for i in sessions.indices where !sessions[i].live {
                guard let pid = sessions[i].pid, !reported.contains(pid) else { continue }
                if sessions[i].mood == .working { seenBusy.insert(pid) }
                if let since = hooksSince[sessions[i].assistant], let st = startedAt[pid], st > since + 2, seenBusy.contains(pid) {
                    sessions[i].hookSilent = true
                }
            }
            hookIssues = missingHooks.filter { !Self.ignoredHooks.contains($0) }.map {
                HookIssue(text: "\(HookInstaller.displayName($0)) isn't connected — live status is off. Connect it from the menu.",
                          install: $0, pid: nil)
            } + sessions.filter(\.hookSilent).map {
                HookIssue(text: "\(HookInstaller.displayName($0.assistant))\($0.project.isEmpty ? "" : " (\($0.project))") isn't reporting — "
                              + HookInstaller.silentFix($0.assistant), install: nil, pid: $0.pid)
            }
            for s in sessions where s.hookSilent { if let pid = s.pid { notifySilent(pid: pid, assistant: s.assistant, project: s.project) } }
            offlineReason = nil
            if file == nil && FileManager.default.fileExists(atPath: StatusPaths.state.path) {
                offlineReason = "OFFLINE — can't read the status file"
            }
            if now - lastFocusCheck >= 1 {
                lastFocusCheck = now
                // Sticky: only switch when the same answer comes back twice, so a momentary miss doesn't flicker.
                let seen = Jump.focusedSession(among: sessions.compactMap { s in
                    s.pid.map { ($0, s.cwd.map { ($0 as NSString).lastPathComponent } ?? s.project) }
                })
                if seen == focusedPid { focusCandidate = nil }
                else if seen == focusCandidate { focusedPid = seen; focusCandidate = nil }
                else { focusCandidate = seen }
            }
        }
        debounceMoods(now)
        Accents.update(visible: sessions.map(\.project))
        relayout()
        // Automatic follows the first session and Random moves on every ten minutes: when the place changes, the
        // scene, the cards' tint, the header's name and tint must follow.
        if location != shownLocation {
            shownLocation = location
            clawdWindow?.sceneView.showFrame()
            clawdWindow?.cardsView.needsDisplay = true
            clawdWindow?.header.needsDisplay = true
            clawdWindow?.redrawScroller()
        }
        if windowMode && onScreen { updateCards(now) }
        publishSaverFeed(now)
    }

    private var shownLocation: Location?

    // MARK: Screen saver feed

    private var lastFeed = 0.0, lastSaverCheck = -100.0, saverInstalled = false
    private var feedEvents: [SaverFeed.Event] = []
    /// What each session and agent looked like at the last publish, to tell what happened since.
    private var feedSeen: [String: (mood: String, asleep: Bool, name: String, project: String, prompt: String?)] = [:]
    private var feedAgents: [String: (name: String, task: String, leader: String)] = [:]

    /// The latest feed, for the window's screen-saver view.
    private(set) var saverFeed: SaverFeed?

    /// About once a second, while the screen saver is installed or the window shows its view: what it should show
    /// (see `SaverFeed`). Only real sessions are written to the file; the Playground, demo and test runs leave it alone.
    private func publishSaverFeed(_ now: Double) {
        let real = playground == nil && !demo && chaosSeconds == nil && shotPath == nil
        if real && now - lastSaverCheck > 10 { lastSaverCheck = now; saverInstalled = SaverFeed.installedSaver != nil }
        let board = windowMode && ClawdWindow.view == .board
        guard (real && saverInstalled) || board, now - lastFeed >= 1 else { return }
        lastFeed = now
        var out: [SaverFeed.Session] = []
        var seenNow: [String: (mood: String, asleep: Bool, name: String, project: String, prompt: String?)] = [:]
        var agentsNow: [String: (name: String, task: String, leader: String)] = [:]
        for s in sessions where s.id != "home" {
            let actor = actors.first { $0.key == "L:" + s.id }
            let cast = Cast(id: s.leader)
            let asleep = actor?.bubble == .sleeping
            let hex = Accents.color(for: s.project).flatMap { $0.usingColorSpace(.sRGB) }.map {
                UInt32($0.redComponent * 255) << 16 | UInt32($0.greenComponent * 255) << 8 | UInt32($0.blueComponent * 255)
            }
            let agents = s.agents.map { a in
                SaverFeed.Agent(id: a.id, cast: Cast.of(a).id, task: a.label.isEmpty ? "Agent" : a.label)
            }
            out.append(SaverFeed.Session(
                id: s.id, cast: cast.id, assistant: s.group, project: s.project, remote: s.pid == nil ? nil : (s.remote ?? "Local"),
                accent: hex, mood: s.mood.rawValue, urgent: actor?.urgent ?? false, asleep: asleep, sitting: actor?.sitting ?? false,
                unknown: !s.live || s.hookSilent, focused: s.pid != nil && s.pid == focusedPid, since: since(s, now: now),
                activity: s.mood == .idle ? nil : s.record?.activity, prompt: s.record?.prompt, agents: agents))
            seenNow[s.id] = (s.mood.rawValue, asleep, cast.name, s.project, s.record?.prompt)
            for (a, fa) in zip(s.agents, agents) { agentsNow[a.id] = (Cast.of(a).name, fa.task, cast.name) }
        }
        // What happened since last time, for the saver's ticker.
        func event(_ text: String) { feedEvents.append(SaverFeed.Event(at: now, text: text)) }
        func short(_ s: String) -> String { s.count > 48 ? String(s.prefix(47)) + "…" : s }
        let first = feedSeen.isEmpty && feedAgents.isEmpty
        for (id, n) in seenNow where !first {
            let place = n.project.isEmpty ? "" : " in \(n.project)"
            guard let was = feedSeen[id] else { event("\(n.name) arrived\(place)"); continue }
            if n.mood == "waiting" && was.mood != "waiting" { event("\(n.name) is waiting on you\(place)") }
            else if n.mood == "idle" && (was.mood == "working" || was.mood == "thinking") {
                event("\(n.name) finished\(n.prompt.map { " “" + short($0) + "”" } ?? "")\(place)")
            } else if n.asleep && !was.asleep { event("\(n.name) fell asleep\(place)") }
        }
        for (id, was) in feedSeen where seenNow[id] == nil && !first {
            event("\(was.name) left\(was.project.isEmpty ? "" : " " + was.project)")
        }
        for (id, a) in agentsNow where feedAgents[id] == nil && !first { event("\(a.name) joined \(a.leader): \(short(a.task))") }
        for (id, a) in feedAgents where agentsNow[id] == nil && !first { event("\(a.name) is done: \(short(a.task))") }
        feedSeen = seenNow
        feedAgents = agentsNow
        feedEvents = Array(feedEvents.suffix(12))
        let feed = SaverFeed(at: now, location: location.rawValue, sessions: out, events: feedEvents)
        saverFeed = feed
        if real && saverInstalled { feed.save() }
    }

    private func debounceMoods(_ now: Double) {
        var next: [String: (confirmed: Mood, pending: Mood?, ticks: Int)] = [:]
        for i in sessions.indices {
            let id = sessions[i].id, raw = sessions[i].mood
            var e = debounce[id] ?? (raw, nil, 0)
            if debounce[id] == nil { moodSince[id] = now }
            if raw == e.confirmed {
                e.pending = nil; e.ticks = 0
            } else if raw == .waiting {
                e = (raw, nil, 0); moodSince[id] = now          // the raised hand is the whole point: no delay
            } else if e.pending == raw {
                e.ticks += 1
                if e.ticks >= 2 { e = (raw, nil, 0); moodSince[id] = now }
            } else {
                e.pending = raw; e.ticks = 1
            }
            sessions[i].mood = e.confirmed
            next[id] = e
        }
        debounce = next
        moodSince = moodSince.filter { next[$0.key] != nil }
    }

    /// How long a session has been in its current mood (hooks know exactly; otherwise we count from when we saw it).
    private func since(_ s: SessionSnapshot, now: Double) -> Double {
        if let rec = s.record, let t = rec.since, rec.state == s.mood.rawValue { return t }
        return moodSince[s.id] ?? now
    }

    private static let scanQueue = DispatchQueue(label: "clawdwars.process-scan", qos: .utility)
    private var scanning = false

    /// Each process's CPU time so far, in seconds.
    private static func cpuTimes(_ processes: [ClaudeProcesses.Info]) -> [Int32: Double] {
        var out: [Int32: Double] = [:]
        for p in processes { out[p.pid] = ClaudeProcesses.cpuSeconds(p.pid) }
        return out
    }

    private func sampleCPU(_ now: Double, cpu times: [Int32: Double]) {
        var next: [Int32: (at: Double, cpu: Double)] = [:]
        for p in processes {
            guard let cpu = times[p.pid] else { continue }
            if let prev = cpuSamples[p.pid], now > prev.at {
                let usage = (cpu - prev.cpu) / (now - prev.at)
                if usage > 0.03 {
                    busyUntil[p.pid] = now + 6
                    if busySince[p.pid] == nil { busySince[p.pid] = now }
                }
            }
            next[p.pid] = (now, cpu)
        }
        cpuSamples = next
        busyUntil = busyUntil.filter { $0.value > now }
        busySince = busySince.filter { busyUntil[$0.key] != nil }
    }

    /// Build the formation and give every actor a target position.
    ///
    /// Leaders pair up (1st & 2nd Claude, 3rd & 4th…) facing each other so they can fight; each leader's
    /// agents stand on its outer side. The whole line extends toward the side of the screen with more room,
    /// and if it still doesn't fit, everyone walks along until it does.
    private func relayout() {
        let now = Date().timeIntervalSince1970
        let z = zoom

        struct Unit { let key: String; let kind: Actor.Kind; var facing: CGFloat; let fwd, back: CGFloat
            var fixedDistance: CGFloat?; var session: SessionSnapshot?; var agent: AgentRecord? }
        var units: [Unit] = []
        var newFights: [Fight] = []

        func agentUnit(_ a: AgentRecord, _ facing: CGFloat) -> Unit {
            Unit(key: "A:" + a.id, kind: .agent(Cast.of(a)),
                 facing: facing, fwd: Self.agentReach.fwd * z, back: Self.agentReach.back * z, agent: a)
        }
        func leaderUnit(_ s: SessionSnapshot, _ facing: CGFloat) -> Unit {
            Unit(key: "L:" + s.id, kind: .leader(Cast(id: s.leader)), facing: facing,
                 fwd: Self.leaderReach.fwd * z, back: Self.leaderReach.back * z, session: s)
        }

        // Everyone on screen, in their natural order (each villain followed by its agents).
        struct Member { var unit: Unit; let weapon: Weapon; let isLeader: Bool; let order: Int }
        var members: [Member] = []
        for s in sessions {
            members.append(Member(unit: leaderUnit(s, 1), weapon: Cast(id: s.leader).weapon, isLeader: true,
                                  order: members.count))
            for ag in s.agents {
                members.append(Member(unit: agentUnit(ag, 1), weapon: Cast.of(ag).weapon, isLeader: false, order: members.count))
            }
        }

        // Who fights whom. Only Claudes that are working or thinking fight (with a short linger, so one that pauses
        // between tools doesn't walk in and out); idle ones and ones waiting for you step aside, to sit and sleep.
        //  1. Claudes fight Claudes (saber duels first).
        //  2. Agents fight agents — their own or other Claudes' (saber duels first).
        //  3. A leftover Claude and a leftover agent fight each other (one Claude + one agent = Vader vs Luke).
        //  4. Anyone still left over cheers the fighters on. R2-D2 and C-3PO are unarmed bystanders.
        // A lone Claude with nobody to fight just practises its kata when working.
        var pairs: [(Member, Member)] = []
        func pairUp(_ pool: inout [Member]) {
            for saberFirst in [true, false] {
                var k = 0
                while k < pool.count {
                    let eligible = { (a: Member, b: Member) in !saberFirst || (a.weapon == .saber && b.weapon == .saber) }
                    guard let m = pool.indices.dropFirst(k + 1).first(where: { eligible(pool[k], pool[$0]) }) else { k += 1; continue }
                    pairs.append((pool[k], pool[m]))
                    pool.remove(at: m); pool.remove(at: k)
                }
            }
        }
        for s in sessions where s.mood == .working || s.mood == .thinking { fightUntil["L:" + s.id] = now + Self.fightLinger }
        let active = { (m: Member) in !m.isLeader || (self.fightUntil[m.unit.key] ?? 0) > now }
        var villains = members.filter { $0.isLeader && $0.weapon != .none && active($0) }
        let unarmedVillains = members.filter { $0.isLeader && $0.weapon == .none && active($0) }
        var agents = members.filter { !$0.isLeader && $0.weapon != .none }
        // 0. Han and Greedo always face off when both are fighting, Claude or agent, wherever they are in the line: everyone between them
        //    walks over to make room (and now and then Han shoots first, see `GreedoShot`).
        func cast(_ m: Member) -> Cast { switch m.unit.kind { case .leader(let c), .agent(let c): return c } }
        if let han = (villains + agents).first(where: { cast($0).isHan }),
           let greedo = (villains + agents).first(where: { cast($0).isGreedo }) {
            pairs.append((han, greedo))
            villains.removeAll { $0.unit.key == han.unit.key || $0.unit.key == greedo.unit.key }
            agents.removeAll { $0.unit.key == han.unit.key || $0.unit.key == greedo.unit.key }
        }
        pairUp(&villains)
        pairUp(&agents)
        if let v = villains.first, let a = agents.first {
            pairs.append((v, a))
            villains.removeFirst(); agents.removeFirst()
        }
        var pool = agents
        if !pairs.isEmpty { pool += villains + unarmedVillains }   // a lone Claude with no opponents practises instead
        cheering = Set(pool.map(\.unit.key))
        let paired = Set(pairs.flatMap { [$0.0.unit.key, $0.1.unit.key] })

        // Lay out pairs and everyone else, keeping roughly the natural order so the line is stable.
        var groups: [[Member]] = pairs.map { [$0.0, $0.1] }
        groups += members.filter { !paired.contains($0.unit.key) }.map { [$0] }
        groups.sort { $0.map(\.order).min()! < $1.map(\.order).min()! }

        for g in groups {
            if g.count == 1 {
                units.append(g[0].unit)
                continue
            }
            var a = g[0].unit, b = g[1].unit
            a.facing = 1; b.facing = -1
            newFights.append(Fight(a: a.key, b: b.key))
            if fightIsCloseQuarters(g[0].weapon, g[1].weapon) {
                // Close enough that the two blades cross, whatever the sprite sizes.
                let sa = g[0].isLeader ? Self.leaderScale : Self.companionScale
                let sb = g[1].isLeader ? Self.leaderScale : Self.companionScale
                b.fixedDistance = (13.5 * (sa + sb) + 29.7 * min(sa, sb)) * z
            }
            units.append(a)
            units.append(b)
        }
        fights = newFights
        fightUntil = fightUntil.filter { $0.value > now - 60 }

        // Positions along the formation axis (f), Vader at 0.
        func left(_ u: Unit) -> CGFloat { u.facing > 0 ? u.back : u.fwd }
        func right(_ u: Unit) -> CGFloat { u.facing > 0 ? u.fwd : u.back }
        var f: [CGFloat] = []
        for (k, u) in units.enumerated() {
            if k == 0 { f.append(0); continue }
            f.append(f[k - 1] + (u.fixedDistance ?? (right(units[k - 1]) + Self.gap * z + left(u))))
        }
        // The first-spawned villain stands on the saved spot; everyone else lines up from there.
        let vaderIndex = units.firstIndex { u in u.session?.id == sessions.first?.id } ?? 0
        let origin = f.isEmpty ? 0 : f[vaderIndex]
        f = f.map { $0 - origin }

        // Direction: toward the side of the screen with more room.
        let sf = stage, origin0 = anchor
        let dir: CGFloat = windowMode ? 1 : ((sf.maxX - origin0.x) >= (origin0.x - sf.minX) ? 1 : -1)
        var lo = CGFloat.greatestFiniteMagnitude, hi = -CGFloat.greatestFiniteMagnitude
        for (k, u) in units.enumerated() {
            let x = origin0.x + dir * f[k]
            let ext = (dir * u.facing > 0) ? (u.back, u.fwd) : (u.fwd, u.back)
            lo = min(lo, x - ext.0); hi = max(hi, x + ext.1)
        }
        // Window mode: shrink the whole crew to fit the window (grow back when there's room again).
        // (Nobody left: nothing to measure, and leaving the fit alone lets the last ones fade out at their size.)
        if windowMode && !refitting && !units.isEmpty && hi > lo {
            let needed = hi - lo, avail = sf.width - 8
            var fit = windowFit
            if needed > avail { fit = max(0.35, windowFit * avail / needed) }
            else if windowFit < 1 && needed < avail * 0.8 { fit = min(1, windowFit * avail * 0.9 / needed) }
            if abs(fit - windowFit) > 0.01 {
                windowFit = fit
                refitting = true
                relayout()
                refitting = false
                snapActors()
                return
            }
        }
        var shift: CGFloat = 0
        if windowMode && hi - lo <= sf.width - 8 {
            shift = sf.midX - (lo + hi) / 2          // centred in the window when it fits
        } else {
            if hi > sf.maxX - 4 { shift = sf.maxX - 4 - hi }
            if lo + shift < sf.minX + 4 { shift = sf.minX + 4 - lo }
        }
        let projectOf = Dictionary(sessions.map { ($0.id, $0.project) }, uniquingKeysWith: { a, _ in a })
        let pidOf = Dictionary(sessions.map { ($0.id, $0.pid) }, uniquingKeysWith: { a, _ in a })
        let aiOf = Dictionary(sessions.map { ($0.id, $0.group) }, uniquingKeysWith: { a, _ in a })

        // Reconcile actors.
        var seen = Set<String>()
        for (k, u) in units.enumerated() {
            seen.insert(u.key)
            let target = origin0.x + dir * f[k] + shift
            let facing = dir * u.facing
            var mood = Mood.idle, mode = VaderMode.idle, label = ""
            var pid = u.session?.pid
            var assistant = u.session?.group ?? "claude"
            var bubble: BubbleKind?, urgent = false, accent: NSColor?
            if let s = u.session {
                mood = s.mood
                mode = s.mood == .idle && !s.agents.isEmpty ? .standGuard : VaderMode(s.mood)
                label = s.project.isEmpty ? (s.id == "home" ? "" : Cast(id: s.leader).name) : s.project
                let held = now - since(s, now: now)
                switch s.mood {
                case .thinking: bubble = .thinking
                case .waiting: bubble = .waiting; urgent = held > 60
                case .idle:
                    if (!s.live && s.pid != nil) || s.stalled { bubble = .unknown }  // no live status: say so, don't fake idle
                    else if s.record != nil && held > 300 { bubble = .sleeping }    // idle 5+ min
                case .working: break
                }
                accent = Accents.color(for: s.project)
            }
            if let a = u.agent {
                label = a.label
                accent = Accents.color(for: projectOf[a.session] ?? "")
                pid = pidOf[a.session] ?? nil
                assistant = aiOf[a.session] ?? "claude"
            }
            let focused = pid != nil && pid == focusedPid && u.session != nil
            // Idle a while: sit down after 2 minutes (the zZz comes at 5).
            var sitting = false
            if let s = u.session, s.mood == .idle, s.record != nil, !s.stalled { sitting = now - since(s, now: now) > 120 }
            let detail = hoverDetail(u.session, u.agent, now: now)
            if let idx = actors.firstIndex(where: { $0.key == u.key && $0.leaving == nil }) {
                actors[idx].targetX = target
                actors[idx].facing = facing
                actors[idx].kind = u.kind
                actors[idx].mood = mood; actors[idx].mode = mode; actors[idx].label = label
                actors[idx].pid = pid; actors[idx].assistant = assistant
                actors[idx].bubble = bubble; actors[idx].urgent = urgent
                actors[idx].accent = accent; actors[idx].focused = focused
                actors[idx].sitting = sitting; actors[idx].detail = detail
            } else {
                // Newcomers walk in from the side, one at a time (from agent-view's walk-in through the door).
                var startX = target, born = now
                if hasLaidOut && !dragging {
                    let fromRight = target >= sf.midX
                    startX = target + (fromRight ? 1 : -1) * 240 * z
                    let queued = actors.filter { $0.born > now - 0.6 }.count
                    born = now + Double(queued) * 0.6
                }
                var a = Actor(key: u.key, kind: u.kind, x: startX, targetX: target, facing: facing,
                              born: born, phase: Double(abs(u.key.hashValue) % 1000) / 97)
                a.mood = mood; a.mode = mode; a.label = label; a.pid = pid; a.assistant = assistant
                a.bubble = bubble; a.urgent = urgent; a.accent = accent; a.focused = focused
                a.sitting = sitting; a.detail = detail
                actors.append(a)
            }
        }
        for idx in actors.indices where actors[idx].leaving == nil && !seen.contains(actors[idx].key) {
            actors[idx].leaving = now
            // Han doesn't just fade out: the Falcon comes to pick him up.
            if actors[idx].cast.isHan {          // Han, as an agent or a whole session
                let st = stage, hx = actors[idx].x
                let dir: CGFloat = hx < st.midX ? 1 : -1
                actors[idx].exit = (hx + dir * 70 * zoom, dir, hx)
            }
        }
        if !sessions.isEmpty { hasLaidOut = true }
    }

    private func snapActors() {
        for i in actors.indices {
            actors[i].x = actors[i].targetX
            actors[i].walkDir = 0
        }
    }

    /// Playground agent tags from here up are villains that are only ever agents (the cast id added on).
    private static let playgroundVillainAgent = 1000

    private func playgroundSessions(_ villains: [Int]) -> [SessionSnapshot] {
        let activities = ["Read Overlay.swift", "Grep fightRoles", "Bash: swift build", "Edit Leaders.swift",
                          "Fetch github.com", "Glob **/*.swift", "Bash: run the tests", "Read README.md"]
        // Heroes by `Companion` index; the agent-only villains as `playgroundVillainAgent` + their cast id.
        let crew = playgroundAgents.enumerated().map { i, c in
            AgentRecord(id: "pg-a\(c)", session: "pg", type: "playground", character: c >= Self.playgroundVillainAgent ? 0 : c,
                        cast: c >= Self.playgroundVillainAgent ? c - Self.playgroundVillainAgent : nil, started: start - Double(30 + i * 47),
                        lastSeen: 0, task: Self.sampleTasks[c % Self.sampleTasks.count],
                        activity: activities[(c + i) % activities.count], tools: 3 + (c * 7) % 23)
        }
        guard !villains.isEmpty else {
            return [SessionSnapshot(id: "home", leader: 0, project: "", mood: .idle, agents: crew)]
        }
        // Sample details so the Playground's cards look like live ones.
        let prompts = ["add a tauntaun", "make the window resize to fit the Claudes", "why does the duel not start?",
                       "write a nice README with screenshots", "fix the portrait crop for wide characters"]
        let nowActs = ["Edit WindowMode.swift", "Bash: swift build", "Read Locations.swift", "Grep opaqueBounds", "Agent: Review the diff"]
        // Agents join the first villain. Empty project → the label shows the villain's name.
        return villains.enumerated().map { i, l in
            var rec = SessionRecord(state: playgroundMood.rawValue, updated: start, leader: l, project: "")
            rec.created = start - Double(600 + i * 1700)
            // On "Idle", spread them over the idle stages: standing, sitting (2 min+), asleep (5 min+).
            rec.since = playgroundMood == .idle ? start - Double(60 + i * 160) : start - Double(20 + i * 35)
            rec.model = "claude-opus-5-5"
            rec.prompt = prompts[i % prompts.count]
            rec.activity = nowActs[i % nowActs.count]
            rec.reply = "Done. The crew now fits the window and everyone still gets a fight."
            rec.prompts = 4 + i * 3
            rec.tools = 38 + i * 21
            let project = playgroundProjects.isEmpty ? "" : playgroundProjects[i % playgroundProjects.count]
            var snap = SessionSnapshot(id: "pg-\(l)", leader: l, project: project, mood: playgroundMood, agents: i == 0 ? crew : [],
                                       record: rec)
            if !playgroundAIs.isEmpty {
                snap.assistant = playgroundAIs[i % playgroundAIs.count]
                // a sample model name that matches the AI, for screenshots
                let models = ["codex": "gpt-5-codex", "qwen": "qwen3-coder", "gemini": "gemini-3-pro", "copilot": "copilot-cli"]
                if let m = models[snap.assistant] { snap.record?.model = m }
            }
            return snap
        }
    }

    private func demoSessions(_ t: Double) -> [SessionSnapshot] {
        func agents(_ chars: [Int], session: String) -> [AgentRecord] {
            chars.map { AgentRecord(id: "demo-\($0)", session: session, type: "demo", character: $0,
                                    started: demoStart, lastSeen: 0, task: Self.sampleTasks[$0 % Self.sampleTasks.count]) }
        }
        func s(_ leader: Int, _ mood: Mood, _ crew: [Int] = []) -> SessionSnapshot {
            SessionSnapshot(id: "demo-\(leader)", leader: leader, project: "project-\(leader + 1)",
                            mood: mood, agents: agents(crew, session: "demo-\(leader)"))
        }
        switch Int(t / 6) % 10 {
        case 0: return [s(0, .idle)]
        case 1: return [s(0, .thinking)]
        case 2: return [s(0, .working)]
        case 3: return [s(0, .waiting)]
        case 4: return [s(0, .working, [0, 1, 2])]
        case 5: return [s(0, .working, [0]), s(1, .working)]                                   // Vader vs Kylo: duel
        case 6: return [s(0, .working), s(3, .working, [1])]                                   // Boba shoots, Vader deflects
        case 7: return [s(0, .thinking, [4]), s(1, .working), s(2, .working), s(5, .working)]  // Maul vs Emperor
        case 8: return [s(0, .working, [3]), s(4, .working, [5])]                             // Stormtrooper vs Vader
        default: return [s(0, .idle, [0, 3, 4])]
        }
    }

    // MARK: Frame loop

    private func tick() {
        let now = Date().timeIntervalSince1970
        let dt = CGFloat(min(0.1, now - lastTick))
        lastTick = now
        actors.removeAll { a in a.leaving.map { now - $0 > (a.exit == nil ? fadeOut : falconExit) } ?? false }

        for i in actors.indices {
            if now < actors[i].born { continue }        // waiting for its turn to walk in
            let d = actors[i].targetX - actors[i].x
            if dragging || abs(d) < 0.5 {
                actors[i].x = actors[i].targetX
                actors[i].walkDir = 0
            } else {
                let stepLen = min(abs(d), Self.walkSpeed * zoom * dt)
                actors[i].x += d > 0 ? stepLen : -stepLen
                actors[i].walkDir = d > 0 ? 1 : -1
            }
        }

        // Which character is the mouse over? (desktop and window alike: both work in screen coordinates)
        var mouseNow = NSEvent.mouseLocation
        if windowMode, let w = clawdWindow { mouseNow = w.toStage(mouseNow) }   // the window may be drawn smaller
        // In the window the list below shows the sessions, so their hover cards only appear when it's hidden. Agents
        // always get one: a card folds away all but its first few.
        let listShowsSessions = windowMode && (clawdWindow?.window.isVisible != true || ClawdWindow.listShown)
        var hovered = hitRects().first { $0.1.contains(mouseNow) && !(listShowsSessions && !$0.0.hasPrefix("A:")) }?.0
        if windowMode && ClawdWindow.view == .board { hovered = nil }   // the scene is hidden behind the board
        if let forced = Self.forcedHover {   // debug: pretend to hover a character
            hovered = actors.first { $0.key.contains(forced) }?.key
        }
        let hoverChanged = hovered != hoveredKey
        hoveredKey = hovered

        // Idle scenes only breathe, so 7.5 fps is plenty; 15 fps when anything is moving (chunky pixel art needs no more).
        frameCount += 1
        let busy = dragging || !fights.isEmpty || actors.contains {
            $0.walkDir != 0 || $0.leaving != nil || now - $0.born < fadeIn || !$0.isLeader
                || $0.mode == .working || $0.mode == .waiting
        }
        guard busy || hoverChanged || frameCount % 2 == 0 else { return }
        guard onScreen || shotPath != nil else { return }   // hidden or fully covered: nothing would show

        items = buildItems(now: now)
        if let shotPath, now - lastShot > shotEvery {
            lastShot = now
            shotCount += 1
            writeShot(to: shotPath.replacingOccurrences(of: "%d", with: String(format: "%02d", shotCount)))
        }
        if chaosSeconds != nil, now - lastCheck > 0.25 { lastCheck = now; checkInvariants(now) }

        if windowMode {
            clawdWindow?.sceneView.showFrame()
            return
        }

        // Fit the window around everything that's drawn.
        var bounds = NSRect.null
        for item in items { bounds = bounds.union(item.rect) }
        if bounds.isNull { bounds = NSRect(x: home.x, y: home.y, width: 1, height: 1) }
        bounds = bounds.insetBy(dx: -4, dy: -4).integral
        if bounds != panel.frame { panel.setFrame(bounds, display: false) }

        let mouse = NSEvent.mouseLocation
        let passThrough = !(dragging || hitRects().contains { $0.1.contains(mouse) })
        if panel.ignoresMouseEvents != passThrough { panel.ignoresMouseEvents = passThrough }

        view.showFrame()
    }

    /// Where each character can be hovered or clicked (villains first, so they win overlaps).
    private func hitRects() -> [(String, NSRect)] {
        let s = Self.leaderScale * zoom, c = Self.companionScale * zoom
        return actors.filter { $0.leaving == nil }.sorted { $0.isLeader && !$1.isLeader }.map {
            $0.isLeader ? ($0.key, NSRect(x: $0.x - 16 * s, y: anchor.y + 5 * s, width: 32 * s, height: 35 * s))
                        : ($0.key, NSRect(x: $0.x - 16 * c, y: anchor.y + (s - c) * 8 + 5 * c, width: 32 * c, height: 35 * c))
        }
    }

    /// Lines for the hover card.
    private func hoverDetail(_ s: SessionSnapshot?, _ a: AgentRecord?, now: Double) -> [String] {
        if let a {
            let who = Cast.of(a)
            var lines = ["\(who.name) — \(a.label.isEmpty ? "Agent" : a.label)"]
            var info = [a.activity ?? "Starting…", Self.duration(now - a.started)]
            if let n = a.tools { info.append("\(n) tool call\(n == 1 ? "" : "s")") }
            lines.append(info.joined(separator: "  ·  "))
            if let owner = sessions.first(where: { $0.id == a.session }) {
                let p = owner.project.isEmpty ? "" : " (\(owner.project))"
                lines.append("Agent of \(Cast(id: owner.leader).name)\(p) · \(owner.aiLabel)")
            }
            return lines
        }
        guard let s else { return [] }
        var lines = [Cast(id: s.leader).name + (s.project.isEmpty ? "" : " — " + s.project) + (s.id == "home" ? "" : " · " + s.aiLabel)]
        let held = Self.duration(now - since(s, now: now))
        switch s.mood {
        case _ where s.stalled: lines.append("Not reporting — restart this Claude session")
        case _ where s.hookSilent: lines.append("Not reporting — " + HookInstaller.silentFix(s.assistant))
        case _ where !s.live: lines.append(s.mood == .working ? "Busy (no live status — no hooks)" : "No live status — no hooks")
        case .working: lines.append("Working · \(held)")
        case .thinking: lines.append("Thinking · \(held)")
        case .waiting: lines.append("Needs you · \(held)")
        case .idle: lines.append((now - since(s, now: now) > 300 ? "Asleep · " : "Idle · ") + held)
        }
        if let r = s.record {
            if let act = r.activity, s.mood != .idle { lines.append("Now: " + act) }
            if let p = r.prompt { lines.append("You: “" + (p.count > 60 ? String(p.prefix(59)) + "…" : p) + "”") }
        }
        if !s.agents.isEmpty { lines.append("\(s.agents.count) agent\(s.agents.count == 1 ? "" : "s") at work") }
        lines.append("Click to jump to this session")
        return lines
    }

    struct DrawItem {
        var image: CGImage?
        var text: NSAttributedString?
        let rect: NSRect
        var mirrored = false
        var alpha: CGFloat = 1
        var boxed = false      // text drawn on a dark rounded box so it reads on any wallpaper
        var agentBox = false   // agents' task boxes get a blue tint to tell them from project names
        var accent: NSColor?   // project colour for the box border
    }

    private func buildItems(now: Double) -> [DrawItem] {
        let t = now - start
        let z = zoom
        let ls = Self.leaderScale * z, cs = Self.companionScale * z
        var out: [DrawItem] = []
        var overlay: [DrawItem] = []

        // Fight roles for pairs that have arrived (not walking); the odd one out cheers.
        func weapon(_ a: Actor) -> Weapon {
            a.cast.weapon
        }
        var roles: [String: FightRole] = [:]
        var fx: [(Actor, Actor)] = []
        var incoming: [String: Double] = [:]   // blaster-vs-blaster: each defender → its shooter's clock offset
        for fight in fights {
            guard let a = actors.first(where: { $0.key == fight.a && $0.leaving == nil }),
                  let b = actors.first(where: { $0.key == fight.b && $0.leaving == nil }),
                  a.walkDir == 0, b.walkDir == 0 else { continue }
            let (l, r) = a.x <= b.x ? (a, b) : (b, a)
            let (lRole, rRole) = fightRoles(weapon(l), weapon(r))
            roles[l.key] = lRole; roles[r.key] = rRole
            fx.append((l, r))
            if case .shoot(let lo) = lRole, case .shoot(let ro) = rRole { incoming[l.key] = ro; incoming[r.key] = lo }
        }
        for a in actors where cheering.contains(a.key) && a.walkDir == 0 && a.leaving == nil { roles[a.key] = .cheer }

        // Han shoots first: while the two stand facing off, now and then his bolt gets through. It starts on one of
        // Han's own shots, so the bolt leaves his blaster; anyone walking off or leaving calls it off.
        var shot: (han: String, greedo: String, e: Double, line: String)?
        if let pair = fx.first(where: { ($0.0.cast.isHan && $0.1.cast.isGreedo) || ($0.0.cast.isGreedo && $0.1.cast.isHan) }) {
            let han = pair.0.cast.isHan ? pair.0 : pair.1, greedo = pair.0.cast.isHan ? pair.1 : pair.0
            if let s = greedoShot, s.han != han.key || s.greedo != greedo.key { greedoShot = nil }
            if let s = greedoShot, now - s.start > GreedoShot.done {
                greedoShot = nil
                nextGreedoShot = now + GreedoShot.delay(first: false)
            }
            if greedoShot == nil {
                if let next = nextGreedoShot, now >= next, case .shoot(let offset)? = roles[han.key] {
                    let fire = (floor((t + offset) / blasterPeriod) + 1) * blasterPeriod - offset
                    greedoShot = (han.key, greedo.key, start + fire, GreedoShot.greedoSays.randomElement() ?? "That hurt!")
                    nextGreedoShot = nil
                } else if nextGreedoShot == nil {
                    nextGreedoShot = now + GreedoShot.delay(first: true)
                }
            }
            if let s = greedoShot, now >= s.start {
                let e = now - s.start
                shot = (s.han, s.greedo, e, s.line)
                incoming[s.han] = nil; incoming[s.greedo] = nil   // nobody ducks: Greedo doesn't see it coming
                if e > GreedoShot.hit + 0.3 { roles[s.han] = .rest }   // blaster down, job done
            }
        } else {
            greedoShot = nil
            nextGreedoShot = nil
        }

        if debug, Int(now * 2) != lastDebug {
            lastDebug = Int(now * 2)
            let line = actors.map { a in
                "\(a.key) x=\(Int(a.x)) tgt=\(Int(a.targetX)) walk=\(Int(a.walkDir)) face=\(Int(a.facing)) mood=\(a.mood) role=\(roles[a.key].map { "\($0)" } ?? "-")"
            }.joined(separator: " | ")
            FileHandle.standardError.write("fights=\(fights.count) \(line)\n".data(using: .utf8)!)
        }

        let screenFrame = stage, ground = anchor.y
        var labels: [(item: DrawItem, leader: Bool, focused: Bool, key: String)] = []
        // Speech bubbles are placed after the names (see below), so they're kept here till then.
        var bubbles: [(key: String, x: CGFloat, y: CGFloat, kind: BubbleKind, urgent: Bool, preferRight: Bool, alpha: CGFloat)] = []
        var speeches: [(key: String, item: DrawItem)] = []   // lines said over a head, placed above its name tag
        // Companions first so leaders (and their sabers) draw on top.
        var falconItems: [DrawItem] = []
        for var actor in actors.sorted(by: { !$0.isLeader && $1.isLeader }) {
            var walking = actor.walkDir != 0
            var facing = walking ? actor.walkDir : actor.facing
            var aboard = false
            if let exit = actor.exit, let left = actor.leaving {
                // Falcon departure, by phase: fly in (0–0.3), ramp down, Han walks up (0.36–0.62),
                // ramp up, lift off and away (0.72–1).
                let p = min(1, (now - left) / falconExit)
                let cs0 = Self.companionScale * z
                let rampFoot = exit.landX - exit.dir * 14 * cs0
                if p >= 0.36 && p < 0.62 {
                    let k = (p - 0.36) / 0.26
                    actor.x = exit.startX + (rampFoot - exit.startX) * CGFloat(k)
                    walking = true; facing = exit.dir
                } else if p >= 0.62 {
                    aboard = true
                } else {
                    actor.x = exit.startX
                    facing = exit.dir
                }
                falconItems.append(falconItem(exit, p: p, ground: ground + (ls - cs0) * 8 + 8 * cs0, scale: cs0))
            }
            if aboard { continue }
            if now < actor.born { continue }             // not on stage yet: don't draw what won't be shown
            var canvas = PixelCanvas(Sprite.width, Sprite.height)
            let scale: CGFloat
            let y: CGFloat
            switch actor.kind {
            case .leader(let who):
                let role = roles[actor.key]
                who.draw(canvas, t: t, mode: role != nil ? .working : actor.mode, walking: walking, role: role ?? .none,
                         urgent: actor.urgent && role == nil, sitting: actor.sitting, asSession: true)
                scale = ls; y = ground
            case .agent(let who):
                let role = roles[actor.key]
                who.draw(canvas, t: role != nil ? t : t + actor.phase, mode: .working, walking: walking,
                         role: role ?? .none, asSession: false)
                scale = cs; y = ground + (ls - cs) * 8
            }
            // Greedo, shot: knocked head over heels, flat on his back, back on his feet (his own, bigger canvas).
            var pivotX = Sprite.bodyCenterX, knockedTop: Int?, lift: CGFloat = 0
            if let s = shot, actor.key == s.greedo, s.e >= GreedoShot.hit {
                let pose = GreedoShot.pose(s.e), who = actor.cast
                let knocked = GreedoShot.sprite(e: s.e, t: t) { c in
                    who.draw(c, t: t, mode: .idle, walking: pose.walking, role: .none, asSession: true)
                }
                canvas = knocked.canvas; knockedTop = knocked.top; pivotX = GreedoShot.pivotX
                actor.x -= facing * CGFloat(pose.back) * scale
                lift = CGFloat(pose.lift) * scale
                walking = pose.walking
            }
            canvas.addOutline(AIStyle.outline(actor.assistant))
            guard let img = canvas.makeImage() else { continue }
            var alpha = min(1, (now - actor.born) / 0.25)
            var drop = 0.0
            if let left = actor.leaving, actor.exit == nil {
                let f = min(1, (now - left) / fadeOut)
                alpha = min(alpha, 1 - f)
                drop = -f * 30
            }
            let mirrored = facing < 0
            let bodyX = (mirrored ? CGFloat(canvas.w) - CGFloat(pivotX) : CGFloat(pivotX)) * scale
            // Ducking a bolt in a shoot-out: squat (squashed from the feet up).
            let duck = incoming[actor.key].map { CGFloat(duckAmount(t: t, shooterOffset: $0, armoured: actor.cast.armoured)) } ?? 0
            let rect = NSRect(x: (actor.x - bodyX).rounded(), y: y + CGFloat(drop) * z + lift,
                              width: CGFloat(canvas.w) * scale, height: (CGFloat(canvas.h) * scale * (1 - 0.22 * duck)).rounded())
            out.append(DrawItem(image: img, rect: rect, mirrored: mirrored, alpha: CGFloat(alpha)))

            // Speech bubble on whichever side of the head fits on screen (Claudes only).
            var bubbleSpan: (minX: CGFloat, maxX: CGFloat, maxY: CGFloat)?
            if actor.isLeader, let kind = actor.bubble {
                let w = CGFloat(Bubble.width) * ls
                let rightX = actor.x + 13 * ls, leftX = actor.x - 13 * ls - w
                // On the side away from the nearest neighbour (so it's clearly this Claude's),
                // unless that side is off screen.
                let nearest = actors.filter { $0.key != actor.key && $0.leaving == nil }
                    .min { abs($0.x - actor.x) < abs($1.x - actor.x) }
                let preferRight = nearest.map { $0.x < actor.x } ?? true
                let onRight = preferRight ? rightX + w <= screenFrame.maxX : leftX < screenFrame.minX
                let h = CGFloat(Bubble.height) * ls
                let by = y + CGFloat(Sprite.height - 1 - Bubble.height) * ls
                let bx = onRight ? rightX : leftX
                bubbleSpan = (bx, bx + w, by + h)
                bubbles.append((actor.key, actor.x, by, kind, actor.urgent, onRight, CGFloat(alpha)))
            }

            // Some sessions have a line they say now and then (`Cast.callout`). Han and Greedo have words after a shot.
            var line: String?, overHead = false   // Han's and Greedo's lines go over their heads, clear of the fight
            if case .leader(let who) = actor.kind, let said = who.callout, actor.walkDir == 0,
               (t / 5 + actor.phase).truncatingRemainder(dividingBy: 1) < 0.3 { line = said }
            if let s = shot {
                if actor.key == s.han, s.e >= GreedoShot.hanLine.from, s.e < GreedoShot.hanLine.to { line = GreedoShot.hanSays; overHead = true }
                if actor.key == s.greedo, s.e >= GreedoShot.standing { line = s.line; overHead = true }
            }
            if let line {
                let sc = actor.isLeader ? ls : cs
                let callout = NSAttributedString(string: line, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: max(9, 10 * z), weight: .heavy),
                    .foregroundColor: NSColor(calibratedRed: 1, green: 0.85, blue: 0.4, alpha: 1),
                    .strokeColor: NSColor.black,
                    .strokeWidth: -4.0,
                ])
                let size = callout.size()
                // On the side away from the speech bubble, level with the head.
                let onLeft = bubbleSpan.map { $0.minX > actor.x } ?? (facing > 0)
                var cx = onLeft ? actor.x - 16 * sc - size.width : actor.x + 16 * sc, cy = y + 33 * sc
                if overHead {
                    // Over the head; once the name tags are placed, it moves up above this one's (see below).
                    cx = actor.x - size.width / 2
                    cy = y + CGFloat(Sprite.height - actor.cast.drawnTop()) * sc + 8 * z
                }
                cx = min(max(cx, screenFrame.minX + 2), screenFrame.maxX - size.width - 2)
                let item = DrawItem(text: callout, rect: NSRect(x: cx.rounded(), y: cy, width: size.width, height: size.height),
                                    alpha: CGFloat(alpha))
                if overHead { speeches.append((actor.key, item)) } else { overlay.append(item) }
            }

            // Project name (Claudes) or task (agents) just above the head, centred on it. Speech bubbles make way for it.
            if (showLabels || !actor.isLeader) && !actor.label.isEmpty {
                // The project you're in (its terminal in front) gets its name 15% larger.
                let big: CGFloat = actor.isLeader && actor.focused ? 1.15 : 1
                let font = actor.isLeader ? NSFont.monospacedSystemFont(ofSize: max(9, 10 * z) * big, weight: .bold)
                                          : NSFont.monospacedSystemFont(ofSize: max(8, 8.5 * z), weight: .semibold)
                let centered = NSMutableParagraphStyle()
                centered.alignment = .center
                let lines = wrapLabel(actor.label, font: font, maxWidth: (actor.isLeader ? 110 * big : 88) * z)
                let text = NSAttributedString(string: lines.joined(separator: "\n"), attributes: [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .paragraphStyle: centered,
                ])
                let textSize = text.size()
                let size = NSSize(width: textSize.width + 10 * z, height: textSize.height + 4 * z)
                var lx = actor.x - size.width / 2
                // Never past the screen edge.
                lx = min(max(lx, screenFrame.minX + 2), screenFrame.maxX - size.width - 2)
                var headTop: CGFloat
                switch actor.kind {
                case .leader(let who):
                    // Its drawn top (the tauntaun's horns), lower when it's sitting down.
                    let seated = actor.sitting && roles[actor.key] == nil && !walking && (actor.mode == .idle || actor.mode == .standGuard)
                    headTop = CGFloat(Sprite.height - who.drawnTop(sitting: seated)) * ls + 8 * z
                case .agent(let who): headTop = CGFloat(Sprite.height - who.drawnTop()) * cs + 5 * z
                }
                if let top = knockedTop { headTop = CGFloat(canvas.h - top) * scale + (actor.isLeader ? 8 : 5) * z + lift }
                do {
                    let ly = y + CGFloat(drop) * z + headTop
                    labels.append((DrawItem(text: text, rect: NSRect(x: lx.rounded(), y: ly,
                                                                     width: size.width, height: size.height),
                                            alpha: CGFloat(alpha), boxed: true, agentBox: !actor.isLeader, accent: actor.accent),
                                   actor.isLeader, actor.focused, actor.key))
                }
            }
        }

        overlay += falconItems

        // Bolts, deflections, lightning and sparks between fighters.
        for (l, r) in fx {
            let margin = 24.0
            let dist = Double((r.x - l.x) / ls)
            let width = Int(dist + margin * 2)
            guard width > 0, width < 4000 else { continue }
            let left = l.x - CGFloat(margin) * ls
            func fighter(_ a: Actor, side: Double) -> Fighter {
                let sc = a.isLeader ? ls : cs
                let lift = a.isLeader ? 0 : (ls - cs) * 8
                var muzzle = (x: 52.0, y: 32.0)
                muzzle = a.cast.muzzle
                return Fighter(weapon: weapon(a), x: Double((a.x - left) / ls), k: Double(sc / ls),
                               top: Double((CGFloat(Sprite.height) * (ls - sc) - lift) / ls), side: side, muzzle: muzzle,
                               armoured: a.cast.armoured, pivot: a.cast.weaponPivot)
            }
            let fl = fighter(l, side: 1), fr = fighter(r, side: -1)
            let shotHere = shot.flatMap { s in Set([l.key, r.key]) == [s.han, s.greedo] ? s : nil }
            guard shotHere != nil || fightFXVisible(t: t, fl.weapon, fr.weapon) else { continue }   // e.g. a duel between clashes
            let c = PixelCanvas(width, Sprite.height)
            if let s = shotHere {
                GreedoShot.drawFX(c, e: s.e, t: t, han: l.key == s.han ? fl : fr, greedo: l.key == s.han ? fr : fl)
            } else {
                drawFightFX(c, t: t, left: fl, right: fr)
            }
            if let img = c.makeImage() {
                overlay.append(DrawItem(image: img, rect: NSRect(x: left.rounded(), y: ground,
                                                                 width: CGFloat(width) * ls,
                                                                 height: CGFloat(Sprite.height) * ls)))
            }
        }

        // Names never overlap (from agent-view): Claudes' get first pick, then agents'; one that would collide with
        // another moves up a row. Speech bubbles don't move names: they're placed after, round them.
        var placed: [NSRect] = []
        var named: [(item: DrawItem, focused: Bool, key: String)] = []
        for l in labels.sorted(by: { $0.leader && !$1.leader }) {
            var r = l.item.rect
            var tries = 0
            while tries < 6, placed.contains(where: { $0.insetBy(dx: -2 * z, dy: -1 * z).intersects(r) }) {
                r.origin.y += r.height + 2 * z
                tries += 1
            }
            placed.append(r)
            let item = l.item
            named.append((DrawItem(text: item.text, rect: r, alpha: item.alpha, boxed: true, agentBox: item.agentBox, accent: item.accent),
                          l.focused, l.key))
        }
        // Each speech bubble beside its Claude's head, on the side away from its nearest neighbour; else the other
        // side; else just above its own name. Whichever first stays on screen and clear of every name and bubble.
        var taken = placed
        for b in bubbles {
            let w = CGFloat(Bubble.width) * ls, h = CGFloat(Bubble.height) * ls
            let right = NSRect(x: b.x + 13 * ls, y: b.y, width: w, height: h)
            let left = NSRect(x: b.x - 13 * ls - w, y: b.y, width: w, height: h)
            let own = named.first { $0.key == b.key }?.item.rect
            let above = NSRect(x: b.x - w / 2, y: max(b.y, (own?.maxY ?? b.y) + 2 * z), width: w, height: h)
            let free = { (r: NSRect) in
                r.minX >= screenFrame.minX && r.maxX <= screenFrame.maxX
                    && !taken.contains { $0.insetBy(dx: -2 * z, dy: -1 * z).intersects(r) }
            }
            let sides = b.preferRight ? [right, left] : [left, right]
            let r = sides.first(where: free) ?? above
            taken.append(r)
            let bc = PixelCanvas(Bubble.width, Bubble.height)
            drawBubble(bc, kind: b.kind, t: t, urgent: b.urgent, tailRight: r.midX < b.x)
            if let bimg = bc.makeImage() {
                overlay.append(DrawItem(image: bimg, rect: NSRect(x: r.minX.rounded(), y: r.minY, width: w, height: h), alpha: b.alpha))
            }
        }
        for n in named {
            overlay.append(n.item)
            if n.focused {
                // Bobbing marker over the Claude whose terminal you're in.
                let r = n.item.rect
                let caret = PixelCanvas(3, 3)
                drawFocusCaret(caret)
                if let img = caret.makeImage() {
                    let cw = 3 * 2.5 * z, bob = (sin(t * 3.3) * 1.5 * z).rounded()
                    overlay.append(DrawItem(image: img, rect: NSRect(x: (r.midX - cw / 2).rounded(), y: r.maxY + 3 * z + bob,
                                                                     width: cw, height: cw)))
                }
            }
        }
        for sp in speeches {
            var r = sp.item.rect
            if let tag = named.first(where: { $0.key == sp.key })?.item.rect { r.origin.y = max(r.minY, tag.maxY + 2 * z) }
            overlay.append(DrawItem(text: sp.item.text, rect: r, alpha: sp.item.alpha))
        }
        // Hover card (from agent-view's hover-for-details): next to the character, kept on screen.
        if let key = hoveredKey, let actor = actors.first(where: { $0.key == key && $0.leaving == nil }), !actor.detail.isEmpty {
            let text = NSMutableAttributedString()
            for (i, line) in actor.detail.enumerated() {
                let last = i == actor.detail.count - 1 && actor.isLeader
                text.append(NSAttributedString(string: (i == 0 ? "" : "\n") + line, attributes: [
                    .font: i == 0 ? NSFont.systemFont(ofSize: 12, weight: .bold) : NSFont.systemFont(ofSize: 11, weight: last ? .regular : .medium),
                    .foregroundColor: i == 0 ? NSColor.white : (last ? NSColor(white: 0.6, alpha: 1) : NSColor(white: 0.85, alpha: 1)),
                ]))
            }
            let ts = text.size()
            let size = NSSize(width: ts.width + 16, height: ts.height + 10)
            let s = actor.isLeader ? ls : cs
            var x = actor.x + 18 * s, y = ground + (actor.isLeader ? 10 : 18) * ls
            if x + size.width > screenFrame.maxX - 4 { x = actor.x - 18 * s - size.width }
            x = min(max(x, screenFrame.minX + 4), screenFrame.maxX - size.width - 4)
            y = min(y, screenFrame.maxY - size.height - 4)
            overlay.append(DrawItem(text: text, rect: NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height),
                                    alpha: 1, boxed: true, accent: actor.accent ?? NSColor(white: 0.6, alpha: 1)))
        }

        // OFFLINE banner on the desktop (the window shows it above the cards): never show stale data silently.
        if let reason = offlineReason ?? hookBanner, !windowMode, let first = actors.first(where: { $0.isLeader && $0.leaving == nil }) {
            let text = NSAttributedString(string: reason, attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: NSColor(srgbRed: 1, green: 0.72, blue: 0.72, alpha: 1)])
            let ts = text.size()
            let size = NSSize(width: ts.width + 16, height: ts.height + 8)
            let x = min(max(first.x - size.width / 2, screenFrame.minX + 4), screenFrame.maxX - size.width - 4)
            let y = ground + CGFloat(Sprite.height) * ls + 26 * z
            overlay.append(DrawItem(text: text, rect: NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height),
                                    alpha: 0.75 + 0.25 * CGFloat(sin(t * 4)), boxed: true, accent: NSColor(srgbRed: 0.9, green: 0.2, blue: 0.2, alpha: 1)))
        }
        return out + overlay
    }

    /// The Millennium Falcon at phase `p` of Han's departure. `feet` is the ground line in screen coordinates.
    private func falconItem(_ exit: (landX: CGFloat, dir: CGFloat, startX: CGFloat), p: Double, ground feet: CGFloat,
                            scale s: CGFloat) -> DrawItem {
        let z = zoom
        var x = exit.landX, lift: CGFloat = 0
        var ramp = 0.0, engines = false, gear = true
        if p < 0.3 {                                   // swoops in over Han's head and settles
            let e = CGFloat(1 - pow(1 - p / 0.3, 2))
            x = exit.landX - exit.dir * 260 * z * (1 - e)
            lift = 150 * z * (1 - e) * (1 - e)
            engines = true; gear = p > 0.22
        } else if p < 0.72 {                           // landed: ramp down, Han boards, ramp up
            ramp = p < 0.36 ? (p - 0.3) / 0.06 : (p < 0.64 ? 1 : max(0, 1 - (p - 0.64) / 0.06))
            engines = p > 0.66
        } else {                                       // lift off and away
            let e = CGFloat(pow((p - 0.72) / 0.28, 2))
            x = exit.landX + exit.dir * 320 * z * e
            lift = 170 * z * e
            engines = true; gear = p < 0.78
        }
        let c = PixelCanvas(66, 29)
        drawFalcon(c, ramp: ramp, engines: engines, gear: gear)
        c.addOutline(C(0xFFFFFF, 0.92))
        let w = 66 * s, h = 29 * s
        return DrawItem(image: c.makeImage(), rect: NSRect(x: (x - w / 2).rounded(), y: (feet - 1 * s + lift).rounded(), width: w, height: h),
                        mirrored: exit.dir < 0, alpha: 1)
    }

    /// Word-wrap a project name onto at most two lines of `maxWidth`; whatever still doesn't fit gets "…".
    /// Wrapped labels by text, font and width: measuring them was done for every label on every frame.
    private var wrapCache: [String: [String]] = [:]

    private func wrapLabel(_ label: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        let key = "\(label)\u{1}\(font.fontName)\u{1}\(font.pointSize)\u{1}\(maxWidth)"
        if let hit = wrapCache[key] { return hit }
        if wrapCache.count > 200 { wrapCache.removeAll() }
        let lines = wrapLabelUncached(label, font: font, maxWidth: maxWidth)
        wrapCache[key] = lines
        return lines
    }

    private func wrapLabelUncached(_ label: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        func width(_ s: String) -> CGFloat { (s as NSString).size(withAttributes: [.font: font]).width }
        guard width(label) > maxWidth else { return [label] }
        // Break on spaces, dashes and underscores (keeping the dash/underscore at the end of the line).
        var words: [String] = []
        var current = ""
        for ch in label {
            current.append(ch)
            if ch == " " || ch == "-" || ch == "_" { words.append(current); current = "" }
        }
        if !current.isEmpty { words.append(current) }

        var lines: [String] = [""]
        for w in words {
            let candidate = lines[lines.count - 1] + w
            if width(candidate.trimmingCharacters(in: .whitespaces)) <= maxWidth || lines[lines.count - 1].isEmpty {
                lines[lines.count - 1] = candidate
            } else {
                lines.append(w)
            }
        }
        lines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        // Hard-split a single long word, and squeeze anything past two lines into the second with an ellipsis.
        if width(lines[0]) > maxWidth {
            // One word too long for a line: fill the first line with as much as fits.
            let all = lines.joined(separator: " ")
            var n = all.count
            while n > 1 && width(String(all.prefix(n))) > maxWidth { n -= 1 }
            lines = [String(all.prefix(n)), String(all.dropFirst(n))]
        }
        var second = ""
        for line in lines.dropFirst() {
            let joiner = second.isEmpty || second.hasSuffix("-") || second.hasSuffix("_") ? "" : " "
            second += joiner + line
        }
        if width(second) > maxWidth {
            while !second.isEmpty && width(second + "…") > maxWidth { second.removeLast() }
            second = second.trimmingCharacters(in: .whitespaces) + "…"
        }
        return [lines[0], second]
    }

    // MARK: Dragging

    private var dragStart = NSPoint.zero

    func beginDrag() {
        dragging = true
        let m = NSEvent.mouseLocation
        dragStart = m
        dragOffset = NSPoint(x: m.x - home.x, y: m.y - home.y)
    }

    func continueDrag() {
        let m = NSEvent.mouseLocation
        home = clampHome(NSPoint(x: (m.x - dragOffset.x).rounded(), y: (m.y - dragOffset.y).rounded()), cursor: m)
        relayout()
        snapActors()
    }

    func endDrag() {
        dragging = false
        let m = NSEvent.mouseLocation
        if hypot(m.x - dragStart.x, m.y - dragStart.y) < 4 {
            jump(at: m)    // a click, not a drag
        } else {
            saveHome()
        }
    }

    /// Clicking a villain brings its Claude session's terminal/editor window to the front.
    private func jump(at point: NSPoint) {
        let s = Self.leaderScale * zoom
        let c = Self.companionScale * zoom
        guard let actor = actors.first(where: {
            $0.isLeader && $0.leaving == nil
                && NSRect(x: $0.x - 16 * s, y: anchor.y + 5 * s, width: 32 * s, height: 35 * s).contains(point)
        }) ?? actors.first(where: {   // an agent jumps to its Claude
            !$0.isLeader && $0.leaving == nil
                && NSRect(x: $0.x - 16 * c, y: anchor.y + (s - c) * 8 + 5 * c, width: 32 * c, height: 35 * c).contains(point)
        }) else { return }
        guard let pid = actor.pid else { NSSound.beep(); return }
        Jump.toSession(pid: pid)
    }

    /// Installed from a download (Homebrew) rather than build.sh: offer once to connect every AI that's on this
    /// Mac but not hooked up yet (also catches Codex / Qwen Code added after Claude was already connected).
    private func offerHooksOnFirstLaunch() {
        guard playground == nil, !demo, shotPath == nil, chaosSeconds == nil else { return }
        SaverInstaller.refreshIfOutdated()
        // The app was moved since the hooks went in: point them here (already agreed to, so no need to ask).
        for ai in HookInstaller.repairMoved() { NSLog("Clawd Wars: re-pointed \(HookInstaller.displayName(ai)) hooks at \(HookInstaller.hookBinary)") }
        let d = UserDefaults.standard
        let ignored = Self.ignoredHooks
        let claude = HookInstaller.claudeAvailable && !HookInstaller.isInstalled && !d.bool(forKey: "offeredHooks")
            && !ignored.contains("claude")
        let others = HookInstaller.others.filter {
            HookInstaller.available($0) && !HookInstaller.installed($0) && !d.bool(forKey: "offeredHooks.\($0.name)")
                && !ignored.contains($0.name)
        }
        guard claude || !others.isEmpty else { return }
        if claude { d.set(true, forKey: "offeredHooks") }
        for ai in others { d.set(true, forKey: "offeredHooks.\(ai.name)") }
        let names = (claude ? ["Claude Code"] : []) + others.map { HookInstaller.displayName($0.name) }
        let list = names.count > 1 ? names.dropLast().joined(separator: ", ") + " and " + names.last! : names[0]
        let codex = others.contains { $0.name == "codex" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.activate(ignoringOtherApps: true)
            let a = NSAlert()
            a.messageText = "Connect Clawd Wars to \(list)?"
            a.informativeText = """
                Clawd Wars learns what your sessions are doing from hooks. This adds a small hook to each one's \
                settings (a backup is kept). Sessions already running pick it up after a restart.\(codex ? """


                Codex asks you to approve new hooks once: type /hooks in Codex and approve Clawd Wars. \
                You'll get a reminder if a Codex session isn't reporting yet.
                """ : "")

                You can do this later from Settings in the menu bar helmet.
                """
            a.addButton(withTitle: "Connect")
            a.addButton(withTitle: "Not Now")
            if a.runModal() == .alertFirstButtonReturn {
                // Each on its own: one that fails doesn't stop the others, and every failure is listed.
                let errors = HookInstaller.installAll((claude ? ["claude"] : []) + others.map(\.name)).errors
                if !errors.isEmpty { self.alert("Couldn't install some hooks", errors.joined(separator: "\n")) }
                self.lastHookCheck = 0
            }
        }
    }

    // MARK: Chaos test

    /// One random step: Claudes and agents come and go and change mood, much faster than real use.
    private func chaosStep(_ now: Double) -> [SessionSnapshot] {
        if let limit = chaosSeconds, now - start > limit { finishChaos() }
        func roll(_ p: Double) -> Bool { Double.random(in: 0..<1) < p }
        let moods: [Mood] = [.working, .working, .thinking, .waiting, .idle]
        if chaos.isEmpty || (chaos.count < 7 && roll(0.15)) {
            let used = Set(chaos.map(\.leader))
            if let l = StatusStore.leaderCast.filter({ !used.contains($0) }).randomElement() {
                chaos.append(SessionSnapshot(id: "chaos-\(l)-\(Int(now * 1000))", leader: l, project: "project-\(l)",
                                             mood: moods.randomElement()!, agents: []))
            }
        }
        if chaos.count > 1 && roll(0.08) { chaos.remove(at: Int.random(in: 0..<chaos.count)) }
        if roll(0.4), !chaos.isEmpty { chaos[Int.random(in: 0..<chaos.count)].mood = moods.randomElement()! }
        let agentCount = chaos.reduce(0) { $0 + $1.agents.count }
        if agentCount < 12 && roll(0.25), !chaos.isEmpty {
            chaosAgentSerial += 1
            let i = Int.random(in: 0..<chaos.count)
            chaos[i].agents.append(AgentRecord(id: "chaos-a\(chaosAgentSerial)", session: chaos[i].id, type: "chaos",
                                               character: 0,
                                               cast: (StatusStore.darkCast + StatusStore.lightCast).randomElement(),
                                               started: now, lastSeen: now,
                                               task: Self.sampleTasks.randomElement()))
        }
        if roll(0.2), let i = chaos.indices.filter({ !chaos[$0].agents.isEmpty }).randomElement() {
            chaos[i].agents.remove(at: Int.random(in: 0..<chaos[i].agents.count))
        }
        return chaos
    }

    private func violation(_ kind: String, _ example: String) {
        var v = violations[kind] ?? (0, [])
        v.count += 1
        if v.examples.count < 3 { v.examples.append(example) }
        violations[kind] = v
    }

    /// The rules the layout must keep, whatever happens.
    private func checkInvariants(_ now: Double) {
        let st = stage
        let onStage = actors.filter { $0.leaving == nil && now >= $0.born }
        for a in onStage {
            // Off screen: once it has had time to walk in, every character's body stays on the stage.
            if now - a.born > 4, a.walkDir == 0, a.x < st.minX - 1 || a.x > st.maxX + 1 {
                violation("character off screen", "\(a.key) at x=\(Int(a.x)) (stage \(Int(st.minX))…\(Int(st.maxX)))")
            }
            // Stuck walking: nobody walks for more than 8 s without arriving.
            if a.walkDir != 0 {
                let since = walkingSince[a.key] ?? now
                walkingSince[a.key] = since
                if now - since > 8 { violation("stuck walking", "\(a.key) walking \(Int(now - since))s toward \(Int(a.targetX)) from \(Int(a.x))") }
            } else {
                walkingSince[a.key] = nil
            }
        }
        // Missing: every session and agent shows up within 3 s.
        var wanted: [String] = []
        for s in sessions { wanted.append("L:" + s.id); wanted += s.agents.map { "A:" + $0.id } }
        let present = Set(actors.filter { $0.leaving == nil }.map(\.key))
        for key in wanted where !present.contains(key) {
            let since = missingSince[key] ?? now
            missingSince[key] = since
            if now - since > 3 { violation("missing character", key) }
        }
        missingSince = missingSince.filter { !present.contains($0.key) && wanted.contains($0.key) }
        if present.count > wanted.count { violation("extra characters", "\(present.count) on stage for \(wanted.count) wanted") }
        // Labels: on screen, and never on top of each other.
        let boxes = items.filter { $0.boxed && $0.alpha > 0.5 }.map(\.rect)
        for r in boxes where r.minX < st.minX - 1 || r.maxX > st.maxX + 1 {
            violation("label off screen", "x \(Int(r.minX))…\(Int(r.maxX))")
        }
        for (i, a) in boxes.enumerated() {
            for b in boxes.dropFirst(i + 1) where a.insetBy(dx: 1, dy: 1).intersects(b.insetBy(dx: 1, dy: 1)) {
                violation("labels overlap", "\(Int(a.minX)),\(Int(a.minY)) and \(Int(b.minX)),\(Int(b.minY))")
            }
        }
    }

    private func finishChaos() {
        var report = "Chaos test: \(Int(chaosSeconds ?? 0)) s, \(chaosAgentSerial) agents spawned, \(windowMode ? "window" : "desktop") mode\n"
        if violations.isEmpty { report += "✓ no violations\n" }
        for (kind, v) in violations.sorted(by: { $0.value.count > $1.value.count }) {
            report += "✗ \(kind): \(v.count)×  e.g. \(v.examples.joined(separator: " | "))\n"
        }
        FileHandle.standardOutput.write(report.data(using: .utf8)!)
        exit(violations.isEmpty ? 0 : 1)
    }

    // MARK: Notifications

    /// The first hook issue, for the banner (with a count when there are more).
    private var hookBanner: String? {
        guard let first = hookIssues.first else { return nil }
        return hookIssues.count > 1 ? first.text + "  (+\(hookIssues.count - 1) more in the menu)" : first.text
    }

    /// Once per session: a macOS notification saying what to do; clicking it jumps to that session.
    private func notifySilent(pid: Int32, assistant: String, project: String) {
        guard !notifiedSilent.contains(pid), playground == nil, !demo, chaosSeconds == nil, shotPath == nil else { return }
        notifiedSilent.insert(pid)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            let name = HookInstaller.displayName(assistant)
            content.title = assistant == "codex" ? "Approve Clawd Wars in Codex" : "\(name) isn't reporting to Clawd Wars"
            let fix = HookInstaller.silentFix(assistant)
            content.body = fix.prefix(1).uppercased() + fix.dropFirst()
                + "\(project.isEmpty ? "" : " (\(project))") to see its live status. Click to jump there."
            content.userInfo = ["pid": Int(pid)]
            center.add(UNNotificationRequest(identifier: "silent-\(pid)", content: content, trigger: nil))
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        if let pid = response.notification.request.content.userInfo["pid"] as? Int {
            DispatchQueue.main.async { Jump.toSession(pid: Int32(pid)) }
        }
        done()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }

    // MARK: Menu bar

    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    /// Hidden from the menu bar helmet (double-click): neither the crew nor the window shows. Not remembered across launches.
    private(set) var hidden = false
    /// The displays are asleep or the screen is locked.
    private var screensAsleep = false

    /// Whether anything we draw can be seen: not hidden, and the window not fully covered or minimised.
    /// The desktop panel only counts as visible once it shows something, so asking it would never draw a first frame.
    private var onScreen: Bool {
        guard !hidden, !screensAsleep else { return false }
        guard windowMode else { return panel.isVisible }
        return clawdWindow?.window.occlusionState.contains(.visible) ?? false
    }

    /// A Vader Clawd helmet in the menu bar, opening the same menu as right-clicking a villain.
    /// Double-clicking it hides or shows Clawd Wars, so a single click opens the menu only once the
    /// double-click time has passed; right-click (or ⌃-click) opens it straight away.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = statusIcon(mono: monoMenuBarIcon)
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.toolTip = "Clawd Wars — double-click to hide or show"
        statusMenu.delegate = self
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        if debug {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let w = item.button?.window
                FileHandle.standardError.write("status item: visible=\(item.isVisible) window=\(w?.frame ?? .zero) onscreen=\(w?.isVisible ?? false)\n".data(using: .utf8)!)
            }
        }
    }

    /// Settings → Monochrome Menu Bar Icon: the helmet as a template image, tinted by macOS like the system icons.
    private var monoMenuBarIcon: Bool {
        get { UserDefaults.standard.bool(forKey: "menuBarMono") }
        set { UserDefaults.standard.set(newValue, forKey: "menuBarMono") }
    }

    @objc private func toggleMonoMenuBarIcon() {
        monoMenuBarIcon.toggle()
        statusItem?.button?.image = statusIcon(mono: monoMenuBarIcon)
    }

    /// Vader's helmet for the menu bar. In colour it gets a white outline (the black helmet would vanish on a dark
    /// menu bar); monochrome keeps only its dark pixels, so the face under the helmet is cut out with its eyes left
    /// in, and macOS tints what's left to match the menu bar.
    private func statusIcon(mono: Bool) -> NSImage? {
        let c = PixelCanvas(Sprite.width, Sprite.height)
        drawLeader(c, .vader, t: 0, mode: .idle, walking: false)
        var icon = c
        if mono {
            icon = PixelCanvas(c.w, c.h)
            let b = c.buf
            for y in 0..<c.h {
                for x in 0..<c.w {
                    let i = (y * c.w + x) * 4
                    let luma = (Int(b[i]) * 3 + Int(b[i + 1]) * 6 + Int(b[i + 2])) / 10
                    if b[i + 3] > 0, luma < 60 { icon.px(x, y, Px(r: 0, g: 0, b: 0, a: b[i + 3])) }
                }
            }
        } else {
            c.addOutline(C(0xFFFFFF, 0.92))
        }
        guard let cg = icon.makeImage()?.cropping(to: CGRect(x: 14, y: 13, width: 28, height: 26)) else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: 19, height: 18))
        img.isTemplate = mono
        return img
    }

    /// A click on the helmet this soon after the menu opened counts as a double-click. Our own, not the system's
    /// double-click time (that can be set to seconds), and the status item reports every click with a clickCount
    /// of 1 anyway. The menu takes ~0.35 s to open and close again on a quick double-click.
    private static let statusDoubleClick: TimeInterval = 0.6
    private var ignoreStatusClickUntil: TimeInterval = 0

    @objc private func statusItemClicked() {
        // The mouse-up of a double-click that already closed the menu and hid us: don't reopen the menu.
        if ProcessInfo.processInfo.systemUptime < ignoreStatusClickUntil { return }
        showStatusMenu()
    }

    /// The menu opens at once. Clicking the helmet again right away closes it and hides (or shows) Clawd Wars.
    private func showStatusMenu() {
        guard let item = statusItem, let button = item.button else { return }
        let opened = ProcessInfo.processInfo.systemUptime
        item.menu = statusMenu   // attached only while it opens, so clicks keep coming to `statusItemClicked`
        button.performClick(nil)   // returns once the menu closes
        item.menu = nil
        let now = ProcessInfo.processInfo.systemUptime
        // Closed by a left click on the helmet itself (not on a menu item, not by Escape)?
        let closer = NSApp.currentEvent
        let onHelmet = button.window.map { $0.convertToScreen(button.convert(button.bounds, to: nil)) }?
            .contains(NSEvent.mouseLocation) ?? false
        if now - opened < Self.statusDoubleClick, onHelmet,
           closer?.type == .leftMouseDown || closer?.type == .leftMouseUp {
            ignoreStatusClickUntil = now + 0.5
            toggleHidden()
        }
    }

    @objc func toggleHidden() {
        hidden.toggle()
        if hidden {
            panel.orderOut(nil)
            clawdWindow?.window.orderOut(nil)
        } else if windowMode, let window = clawdWindow?.window {
            window.orderFrontRegardless()   // back on screen without taking focus from the app you're in
        } else if windowMode {
            openWindow()
        } else {
            panel.orderFrontRegardless()
        }
    }

    /// Rebuild the menu bar and Crew menus from the live state each time they open.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let fresh = self.menu()
        let items = fresh.items
        fresh.removeAllItems()
        items.forEach { menu.addItem($0) }
    }

    // MARK: Window mode

    @objc func toggleWindowMode() {
        hidden = false   // switching where it shows means you want to see it
        windowMode.toggle()
        if windowMode {
            openWindow()
            panel.orderOut(nil)
        } else {
            clawdWindow?.window.orderOut(nil)
            clawdWindow = nil
            applyDockPolicy()
            panel.orderFrontRegardless()
        }
        NSApp.mainMenu = makeMainMenu()
        refreshStatus()
        snapActors()
    }

    private func openWindow() {
        if clawdWindow == nil {
            let w = ClawdWindow(controller: self, sceneHeight: sceneHeight)
            w.onClose = { [weak self] in self?.toggleWindowMode() }
            w.header.onClose = { NSApp.terminate(nil) }   // × quits; window mode is remembered for next launch
            w.header.onToggleList = { [weak self] in self?.cycleWindowView() }
            w.board.feedSource = { [weak self] in self?.saverFeed }
            w.board.contextMenu = { [weak self] in self?.menu() }
            w.onGeometryChange = { [weak self] in
                guard let self else { return }
                self.relayout()
                self.snapActors()
            }
            clawdWindow = w
            if ClawdWindow.view == .board { w.applyBoard() } else if !ClawdWindow.listShown { w.applyListShown() }
        }
        applyDockPolicy()
        clawdWindow?.window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var showInDock: Bool {
        get { UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showInDock") }
    }

    /// Dock icon (and an app menu bar with the Crew menu) in both modes, or neither — then the
    /// menu bar helmet is the way in.
    private func applyDockPolicy() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        NSApp.mainMenu = makeMainMenu()
    }

    /// With the Dock icon off: a Dock icon (and so the top-bar menus) only while the window is the app in front.
    private func updateFrontPolicy(active: Bool) {
        guard !showInDock else { return }
        let want: NSApplication.ActivationPolicy = active && windowMode && clawdWindow?.window.isVisible == true ? .regular : .accessory
        guard NSApp.activationPolicy() != want else { return }
        NSApp.setActivationPolicy(want)
        if want == .regular {
            NSApp.mainMenu = makeMainMenu()
        } else {
            // Dropping the Dock icon can take our windows down with it; keep them up, without stealing focus.
            if hidden { return }
            if windowMode { clawdWindow?.window.orderFrontRegardless() } else { panel.orderFrontRegardless() }
        }
    }

    @objc private func toggleDock() {
        showInDock.toggle()
        applyDockPolicy()
        // Changing the activation policy can hide our windows; bring them back.
        DispatchQueue.main.async {
            guard !self.hidden else { return }
            if self.windowMode {
                self.clawdWindow?.window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                self.panel.orderFrontRegardless()
            }
        }
    }

    /// Clicking the Dock icon brings the window forward in window mode.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if hidden { toggleHidden() }
        else if windowMode { clawdWindow?.window.makeKeyAndOrderFront(nil) }
        return true
    }

    private var sceneHeight: CGFloat { max(170, (CGFloat(Sprite.height) * Self.leaderScale + 70) * Self.windowZoom + windowFloor) }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let app = NSMenu()
        app.addItem(withTitle: "About Clawd Wars", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(action: windowMode ? "Show on Desktop" : "Show in Window", #selector(toggleWindowMode), target: self)
        app.addItem(.separator())
        app.addItem(withTitle: "Quit Clawd Wars", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = app
        main.addItem(appItem)
        // The same options as right-clicking a villain, as a "Crew" menu.
        let crewItem = NSMenuItem()
        let crew = NSMenu(title: "Crew")
        crew.delegate = self
        crewItem.submenu = crew
        main.addItem(crewItem)
        let winItem = NSMenuItem()
        let win = NSMenu(title: "Window")
        win.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winItem.submenu = win
        main.addItem(winItem)
        return main
    }

    /// Click in the window's scene strip.
    func click(at point: NSPoint) { jump(at: point) }

    private var portraitCache: [String: CGImage] = [:]
    private var spriteColorCache: [Int: NSColor] = [:]

    /// A character's main colour (its costume: Yoda green, Vader black…), measured from its sprite, leaving out
    /// the Clawd body underneath and the eyes. Cached per character.
    private func spriteColor(_ who: Cast) -> NSColor {
        if let c = spriteColorCache[who.id] { return c }
        let canvas = PixelCanvas(Sprite.width, Sprite.height)
        who.draw(canvas, t: 0.1, mode: .idle, walking: false, role: .rest, asSession: true)
        let d = canvas.dominantColor(excluding: [clawdOrange, clawdShade, ink]) ?? (0.6, 0.6, 0.6)
        let c = NSColor(srgbRed: CGFloat(d.r), green: CGFloat(d.g), blue: CGFloat(d.b), alpha: 1)
        spriteColorCache[who.id] = c
        return c
    }

    private func portrait(_ key: String, assistant: String, _ draw: (PixelCanvas) -> Void) -> CGImage? {
        let key = key + ":" + assistant
        if let img = portraitCache[key] { return img }
        let c = PixelCanvas(Sprite.width, Sprite.height)
        draw(c)
        c.addOutline(AIStyle.outline(assistant))
        // Crop to the character's actual outline (walkers and Jabba are much wider than a Clawd).
        let img = c.opaqueBounds().flatMap { c.makeImage()?.cropping(to: $0) }
        portraitCache[key] = img
        return img
    }

    /// Seconds only for the first minute, then whole minutes: a card with a ticking second counter redraws every second.
    private static func duration(_ seconds: Double) -> String {
        let s = Int(max(0, seconds))
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }

    /// Build the window's cards from everything the hooks recorded (model, title, prompt, reply, current tool…).
    private func updateCards(_ now: Double) {
        guard let w = clawdWindow else { return }
        let dim = NSColor(white: 0.62, alpha: 1), soft = NSColor(white: 0.85, alpha: 1)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let compact = ClawdWindow.scale < 1          // Compact Window: no project path, one line of conversation
        var cards: [CardModel] = []
        // Grouped by AI (stable within a group); with more than one AI each group gets a small header.
        var listed = sessions.enumerated()
            .filter { $0.element.id != "home" || !$0.element.agents.isEmpty }
            .sorted { (AIStyle.rank($0.element.group), $0.offset) < (AIStyle.rank($1.element.group), $1.offset) }
            .map(\.element)
        // Several sessions of one AI in the same project sit together, under the first one's spot, as a tree.
        func projectKey(_ s: SessionSnapshot) -> String? {
            s.project.isEmpty ? nil : s.group + "\u{1}" + s.project + "\u{1}" + (s.remote ?? "")
        }
        var firstSeen: [String: Int] = [:]
        for (i, s) in listed.enumerated() { if let k = projectKey(s), firstSeen[k] == nil { firstSeen[k] = i } }
        listed = listed.enumerated()
            .sorted { (projectKey($0.element).flatMap { firstSeen[$0] } ?? $0.offset, $0.offset)
                    < (projectKey($1.element).flatMap { firstSeen[$0] } ?? $1.offset, $1.offset) }
            .map(\.element)
        let perProject = Dictionary(grouping: listed.compactMap(projectKey), by: { $0 }).mapValues(\.count)
        let severalAIs = Set(listed.map(\.group)).count > 1
        var lastAI: String?
        for (index, s) in listed.enumerated() {
            let leader = Cast(id: s.leader)
            let actor = actors.first { $0.key == "L:" + s.id }
            let held = Self.duration(now - since(s, now: now))
            var status: String, color: NSColor
            switch (s.mood, actor?.bubble) {
            case (_, _) where s.hookSilent: status = s.assistant == "codex" ? "APPROVE IN /hooks" : "NOT REPORTING"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (_, _) where s.stalled: status = "NOT REPORTING"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.working, _) where !s.live: status = "BUSY (CPU)"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.working, _): status = "WORKING · \(held)"; color = NSColor(srgbRed: 0.42, green: 0.9, blue: 0.46, alpha: 1)
            case (.thinking, _): status = "THINKING · \(held)"; color = NSColor(srgbRed: 0.42, green: 0.71, blue: 1, alpha: 1)
            case (.waiting, _): status = (actor?.urgent == true ? "NEEDS YOU! · " : "NEEDS YOU · ") + held
                color = NSColor(srgbRed: 1, green: 0.35, blue: 0.35, alpha: 1)
            case (.idle, .some(.unknown)): status = "NO LIVE STATUS"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.idle, .some(.sleeping)): status = "ASLEEP · \(held)"; color = NSColor(srgbRed: 0.63, green: 0.55, blue: 1, alpha: 1)
            case (.idle, _): status = "IDLE · \(held)"; color = dim
            }

            var lines: [(String, NSColor)] = []
            if let r = s.record {
                let meta = [r.model, r.title].compactMap { $0 }.joined(separator: "  ·  ")
                if !meta.isEmpty { lines.append((meta, dim)) }
                if let a = r.activity, s.mood != .idle { lines.append(("Now: " + a, .white)) }
                let reply = s.mood == .idle ? r.reply.map { s.aiLabel.components(separatedBy: " · ")[0] + ": “" + $0 + "”" } : nil
                if compact {
                    // Compact Window: one line of the conversation — the reply once it's done, otherwise your prompt.
                    if let line = reply ?? r.prompt.map({ "You: “" + $0 + "”" }) { lines.append((line, soft)) }
                } else {
                    if let p = r.prompt { lines.append(("You: “" + p + "”", soft)) }
                    if let reply { lines.append((reply, soft)) }
                }
                var stats: [String] = []
                if let n = r.prompts { stats.append("\(n) prompt\(n == 1 ? "" : "s")") }
                if let n = r.tools { stats.append("\(n) tool call\(n == 1 ? "" : "s")") }
                if let c = r.created { stats.append("up " + Self.duration(now - c)) }
                if let cwd = s.cwd, !compact { stats.append(cwd.hasPrefix(home) ? "~" + cwd.dropFirst(home.count) : cwd) }
                if !stats.isEmpty { lines.append((stats.joined(separator: "  ·  "), dim)) }
            } else if s.hookSilent {
                lines.append(("The Clawd Wars hook isn't running in this session, so it can't report what it's doing.", soft))
                let fix = HookInstaller.silentFix(s.assistant)
                lines.append((fix.prefix(1).uppercased() + fix.dropFirst() + " — click this card to jump there.", dim))
            } else if !s.live {
                lines.append(("Started before the hooks were installed, so it can't report what it's doing.", soft))
                lines.append((s.assistant == "claude" ? "Restart it for live status: /exit, then claude --continue"
                                                      : "Restart this \(s.assistant.capitalized) session for live status.", dim))
                if let cwd = s.cwd, !compact { lines.append((cwd.hasPrefix(home) ? "~" + cwd.dropFirst(home.count) : cwd, dim)) }
            }

            let agents: [CardModel.Agent] = s.agents.map { a in
                let who = Cast.of(a)
                var detail = [a.activity ?? "Starting…", Self.duration(now - a.started)]
                if let n = a.tools { detail.append("\(n) tool call\(n == 1 ? "" : "s")") }
                if a.type != "general-purpose" && a.type != "playground" && a.type != "demo" { detail.append(a.type) }
                return CardModel.Agent(name: who.name, task: a.label.isEmpty ? "Agent" : a.label,
                                       detail: detail.joined(separator: "  ·  "),
                                       portrait: portrait("a\(who.id)", assistant: s.group) { who.draw($0, t: 0.3, mode: .idle, walking: false, role: .rest, asSession: true) })
            }
            cards.append(CardModel(
                // which AI it is shows in the section header above, so the card only names the character
                villain: leader.name, project: s.project, accent: Accents.color(for: s.project) ?? NSColor(white: 0.5, alpha: 1),
                status: status, statusColor: color, focused: s.pid != nil && s.pid == focusedPid,
                lines: lines, agents: agents,
                portrait: portrait("l\(leader.id)", assistant: s.group) { leader.draw($0, t: 0.1, mode: .idle, walking: false, role: .none, asSession: true) },
                pid: s.pid))
            cards[cards.count - 1].id = s.id
            cards[cards.count - 1].spriteColor = spriteColor(leader)
            if s.pid != nil { cards[cards.count - 1].remote = s.remote ?? "Local" }
            if severalAIs && s.group != lastAI {
                cards[cards.count - 1].group = (HookInstaller.displayName(s.group), AIStyle.color(s.group))
            }
            if let k = projectKey(s), let n = perProject[k], n > 1 {
                let first = index == 0 || projectKey(listed[index - 1]) != k
                let last = index == listed.count - 1 || projectKey(listed[index + 1]) != k
                cards[cards.count - 1].tree = CardModel.Tree(sessions: first ? n : nil, last: last)
            }
            lastAI = s.group
        }
        let banner: String? = offlineReason.map { $0 + " — live status is off. Fix it from Settings in the menu." } ?? hookBanner
        // An AI that isn't connected can be waved off with the banner's ×; other problems can't.
        let dismissible = offlineReason == nil ? hookIssues.first?.install : nil
        w.cardsView.update(cards: cards, banner: banner, dismiss: dismissible.map { ai in { [weak self] in self?.ignoreHooks(for: ai) } })
        w.fitToContent()
    }

    /// CLAWD_SHOT=/path.png: write the rendered scene (or the whole window) every 5 s — for checking
    /// visuals without screen-recording permission (from agent-view's AGENTVIEW_SHOT).
    private func writeShot(to path: String) {
        var rep: NSBitmapImageRep?
        if windowMode, let content = clawdWindow?.window.contentView {
            rep = content.bitmapImageRepForCachingDisplay(in: content.bounds)
            if let rep { content.cacheDisplay(in: content.bounds, to: rep) }
        } else {
            var bounds = NSRect.null
            for item in items { bounds = bounds.union(item.rect) }
            guard !bounds.isNull else { return }
            bounds = bounds.insetBy(dx: -10, dy: -10).integral
            guard let r = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(bounds.width) * 2, pixelsHigh: Int(bounds.height) * 2,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                  let gc = NSGraphicsContext(bitmapImageRep: r) else { return }
            r.size = bounds.size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = gc
            let ctx = gc.cgContext
            ctx.scaleBy(x: 2, y: 2)
            ctx.setFillColor(CGColor(red: 0.17, green: 0.18, blue: 0.23, alpha: 1))   // a dark "desktop"
            ctx.fill(CGRect(origin: .zero, size: bounds.size))
            OverlayView.render(items, origin: bounds.origin, in: ctx)
            NSGraphicsContext.restoreGraphicsState()
            rep = r
        }
        if let data = rep?.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    // MARK: Menu

    func menu() -> NSMenu {
        let m = NSMenu()
        for issue in hookIssues {
            let title: String
            if let ai = issue.install { title = "⚠︎ Connect \(HookInstaller.displayName(ai))…" }
            else { title = "⚠︎ " + issue.text.replacingOccurrences(of: " — ", with: ": ") }
            let item = NSMenuItem(title: title, action: #selector(fixHookIssue(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = issue.install ?? issue.pid.map { "jump:\($0)" }
            m.addItem(item)
            if let ai = issue.install {
                let ignore = NSMenuItem(title: "Don't Remind Me About \(HookInstaller.displayName(ai))", action: #selector(ignoreHookIssue(_:)),
                                        keyEquivalent: "")
                ignore.target = self
                ignore.representedObject = ai
                ignore.indentationLevel = 1
                m.addItem(ignore)
            }
        }
        if !hookIssues.isEmpty { m.addItem(.separator()) }
        // No session list here: the window's list and the desktop's hover cards already show every session.
        if demo { m.addItem(disabled: "(demo mode)") }
        if playground != nil { m.addItem(disabled: "(playground)") }
        if demo || playground != nil { m.addItem(.separator()) }

        let size = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (title, z) in [("Small", 0.67), ("Medium", 1.0), ("Large", 1.33), ("Huge", 1.75)] {
            let item = NSMenuItem(title: title, action: #selector(setZoom(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = z
            item.state = abs(baseZoom - z) < 0.01 ? .on : .off
            sub.addItem(item)
        }
        size.submenu = sub
        m.addItem(action: hidden ? "Show Clawd Wars" : "Hide Clawd Wars", #selector(toggleHidden), target: self)
        m.addItem(action: windowMode ? "Show on Desktop" : "Show in Window", #selector(toggleWindowMode), target: self)
        if windowMode { m.addItem(locationMenu()) }
        m.addItem(settingsMenu(size: size))
        m.addItem(.separator())
        // Developer toys: only with ⌘ held while opening the menu (or while one is running, so you can leave it).
        if NSEvent.modifierFlags.contains(.command) || playground != nil || demo {
            m.addItem(playgroundMenu())
            m.addItem(action: "Demo Mode", #selector(toggleDemo), target: self, on: demo)
        }
        m.addItem(action: "Forget Idle Sessions", #selector(forgetIdle), target: self)
        if !windowMode { m.addItem(action: "Reset Position", #selector(resetPosition), target: self) }
        m.addItem(.separator())
        m.addItem(action: "Quit", #selector(quit), target: self)
        return m
    }

    @objc private func setZoom(_ sender: NSMenuItem) {
        zoom = sender.representedObject as? Double ?? 1
        home = clampHome(home)
        relayout()
        snapActors()
    }

    @objc private func toggleLabels() { showLabels.toggle() }

    /// Preferences, gathered in one place.
    private func settingsMenu(size: NSMenuItem) -> NSMenuItem {
        let root = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let sm = NSMenu()
        sm.addItem(statusSymbolsMenu())
        sm.addItem(.separator())
        // In the window the crew always fits the window, so Size only applies on the desktop.
        if windowMode { sm.addItem(disabled: "Size (desktop only)") } else { sm.addItem(size) }
        sm.addItem(action: windowMode ? "Show Project Names in Window" : "Show Project Names on Desktop",
                   #selector(toggleLabels), target: self, on: showLabels)
        sm.addItem(.separator())
        sm.addItem(disabled: "Window mode")
        sm.addItem(action: "Keep Window on Top", #selector(togglePin), target: self,
                   on: UserDefaults.standard.bool(forKey: "windowPinned"))
        sm.addItem(action: "Compact Window", #selector(toggleSmallWindow), target: self,
                   on: ClawdWindow.small)
        sm.addItem(action: "Show Session List in Window", #selector(toggleWindowList), target: self,
                   on: ClawdWindow.listShown && ClawdWindow.view != .board)
        sm.addItem(action: "Screen Saver View in Window", #selector(toggleBoard), target: self, on: ClawdWindow.view == .board)
        sm.addItem(action: "Fit Window Height to Sessions", #selector(toggleAutoHeight), target: self,
                   on: UserDefaults.standard.object(forKey: "autoHeight") as? Bool ?? true)
        sm.addItem(.separator())
        sm.addItem(action: "Show Dock Icon", #selector(toggleDock), target: self, on: showInDock)
        sm.addItem(action: "Monochrome Menu Bar Icon", #selector(toggleMonoMenuBarIcon), target: self, on: monoMenuBarIcon)
        sm.addItem(action: "Launch at Login", #selector(toggleLogin), target: self,
                   on: SMAppService.mainApp.status == .enabled)
        sm.addItem(.separator())
        if HookInstaller.isInstalled {
            sm.addItem(action: "Remove Claude Code Hooks", #selector(removeHooks), target: self)
        } else {
            sm.addItem(action: "Install Claude Code Hooks", #selector(installHooks), target: self)
        }
        for ai in HookInstaller.others where HookInstaller.available(ai) {
            let on = HookInstaller.installed(ai)
            let item = NSMenuItem(title: "\(on ? "Remove" : "Install") \(HookInstaller.displayName(ai.name)) Hooks",
                                  action: on ? #selector(removeOtherHooks(_:)) : #selector(installOtherHooks(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ai.name
            sm.addItem(item)
        }
        if SaverInstaller.bundled != nil {
            sm.addItem(.separator())
            if SaverInstaller.isInstalled {
                sm.addItem(action: "Remove Screen Saver", #selector(removeSaver), target: self)
            } else {
                sm.addItem(action: "Install Screen Saver…", #selector(installSaver), target: self)
            }
        }
        root.submenu = sm
        return root
    }

    /// Settings → Status Symbols: a key to the bubbles, poses and colours (`Legend`). Nothing to pick, so its rows are
    /// enabled only to keep their text at full strength.
    private func statusSymbolsMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Status Symbols", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        sub.autoenablesItems = false
        for (i, section) in Legend.sections.enumerated() {
            if i > 0 { sub.addItem(.separator()) }
            section.forEach { sub.addItem(Legend.menuItem($0)) }
        }
        root.submenu = sub
        return root
    }

    @objc private func togglePin() {
        let on = !UserDefaults.standard.bool(forKey: "windowPinned")
        UserDefaults.standard.set(on, forKey: "windowPinned")
        clawdWindow?.applyPin()
    }

    @objc private func toggleSmallWindow() {
        ClawdWindow.small.toggle()
        clawdWindow?.applySmall()
    }

    /// The header's view button: the scene with the list ↔ just the scene; from the screen-saver view (Settings
    /// only), back to the scene with the list.
    private func cycleWindowView() { toggleWindowList() }

    private func setBoard(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: "windowBoard")
        lastFeed = 0                     // a feed straight away, not up to a second later
        if on { publishSaverFeed(Date().timeIntervalSince1970) }
        clawdWindow?.applyBoard()
    }

    @objc private func toggleBoard() { setBoard(ClawdWindow.view != .board) }

    /// Settings → Show Session List in Window (and the view button's last step): from the screen-saver view, back to
    /// the scene with the list.
    @objc private func toggleWindowList() {
        if ClawdWindow.view == .board {
            setBoard(false)
            if !ClawdWindow.listShown { UserDefaults.standard.set(true, forKey: "windowList"); clawdWindow?.applyListShown() }
            return
        }
        let show = !ClawdWindow.listShown
        if !show, let w = clawdWindow?.window { UserDefaults.standard.set(Double(w.frame.height), forKey: "windowListHeight") }
        UserDefaults.standard.set(show, forKey: "windowList")
        clawdWindow?.applyListShown()
    }

    @objc private func toggleAutoHeight() {
        let on = !(UserDefaults.standard.object(forKey: "autoHeight") as? Bool ?? true)
        UserDefaults.standard.set(on, forKey: "autoHeight")
        if on { clawdWindow?.fitToContent() }
    }

    private func locationMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Location: \(location.name)", action: nil, keyEquivalent: "")
        let lm = NSMenu()
        let picked = UserDefaults.standard.string(forKey: "location")
        let auto = NSMenuItem(title: "Automatic (where the first Claude belongs)", action: #selector(setLocation(_:)), keyEquivalent: "")
        auto.target = self
        auto.state = picked == nil ? .on : .off
        lm.addItem(auto)
        let random = NSMenuItem(title: "Random (somewhere new every 10 minutes)", action: #selector(setLocation(_:)), keyEquivalent: "")
        random.target = self
        random.representedObject = Self.randomLocation
        random.state = picked == Self.randomLocation ? .on : .off
        lm.addItem(random)
        lm.addItem(.separator())
        let owners: [Location: [String]] = Dictionary(grouping: Leader.allCases.map { (Location.home(of: $0), $0.name) }
            + Companion.allCases.map { (Location.home(of: $0), $0.name) }, by: \.0).mapValues { $0.map(\.1) }
        for l in Location.allCases {
            let who = owners[l]?.joined(separator: ", ") ?? ""
            let item = NSMenuItem(title: who.isEmpty ? l.name : "\(l.name)  —  \(who)", action: #selector(setLocation(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = l.rawValue
            item.state = picked == l.rawValue ? .on : .off
            lm.addItem(item)
        }
        root.submenu = lm
        return root
    }

    @objc private func setLocation(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String {
            UserDefaults.standard.set(raw, forKey: "location")
        } else {
            UserDefaults.standard.removeObject(forKey: "location")
        }
        clawdWindow?.sceneView.showFrame()
        clawdWindow?.cardsView.needsDisplay = true
        clawdWindow?.header.needsDisplay = true
        clawdWindow?.redrawScroller()
    }

    private func playgroundMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Playground", action: nil, keyEquivalent: "")
        let pm = NSMenu()
        let picked = playground ?? []
        pm.addItem(disabled: "Villains — they pair up in the order you add them")
        func weaponLabel(_ l: Leader) -> String {
            switch l {
            case .vader: return "red saber"
            case .kylo: return "crossguard saber"
            case .maul: return "double saber"
            case .boba: return "EE-3 blaster"
            case .trooper: return "E-11 blaster"
            case .emperor: return "Force lightning"
            case .rogr: return "E-5 blaster"
            case .dooku: return "curved-hilt saber"
            case .gamorrean: return "vibro-axe"
            case .jabba: return "unarmed — laughs"
            case .ig88: return "blaster rifle"
            case .atst: return "chin blasters"
            case .atat: return "heavy chin cannons"
            case .rancor: return "long clawed arms"
            case .greedo: return "blaster pistol"
            case .royalGuard: return "force pike"
            case .sebulba: return "pod racer flame jet"
            case .salacious: return "unarmed — cackles"
            case .grievous: return "four sabers"
            case .tusken: return "gaffi stick"
            case .cadBane: return "twin blasters"
            case .thrawn: return "blaster pistol"
            case .hammerhead: return "unarmed"
            case .mse6, .id9: return "agent only"
            case .baylan, .shinHati: return "orange saber"
            case .grandInquisitor, .secondSister: return "spinning double saber"
            case .bantha: return "unarmed — Tusken mount"
            case .bibFortuna: return "unarmed"
            case .watto: return "unarmed — haggles"
            case .moffGideon: return "the Darksaber"
            case .deathTrooper: return "E-11D blaster"
            case .scoutTrooper: return "speeder bike cannon"
            case .ventress: return "twin red sabers"
            case .savageOpress: return "double saber"
            case .jangoFett: return "twin pistols"
            case .bossk: return "blaster rifle"
            case .dengar: return "long blaster rifle"
            case .droideka: return "twin blasters, shield"
            case .phasma: return "chrome blaster"
            case .krennic: return "blaster pistol"
            case .tarkin: return "unarmed — fires when ready"
            case .fifthBrother, .reva: return "spinning double saber"
            }
        }
        for l in Leader.allCases where !StatusStore.agentOnly.contains(l.rawValue) {
            let order = picked.firstIndex(of: l.rawValue).map { "   #\($0 + 1)" } ?? ""
            let item = NSMenuItem(title: "\(l.name) (\(weaponLabel(l)))\(order)",
                                  action: #selector(togglePlaygroundVillain(_:)), keyEquivalent: "")
            item.target = self
            item.tag = l.rawValue
            item.state = picked.contains(l.rawValue) ? .on : .off
            pm.addItem(item)
        }
        pm.addItem(.separator())
        pm.addItem(disabled: "Agents — they join the first villain")
        for c in Companion.allCases {
            let item = NSMenuItem(title: c.name, action: #selector(togglePlaygroundAgent(_:)), keyEquivalent: "")
            item.target = self
            item.tag = c.rawValue
            item.state = playground != nil && playgroundAgents.contains(c.rawValue) ? .on : .off
            pm.addItem(item)
        }
        for id in StatusStore.agentOnly.sorted() {
            let tag = Self.playgroundVillainAgent + id
            let item = NSMenuItem(title: Leader(index: id).name, action: #selector(togglePlaygroundAgent(_:)), keyEquivalent: "")
            item.target = self
            item.tag = tag
            item.state = playground != nil && playgroundAgents.contains(tag) ? .on : .off
            pm.addItem(item)
        }
        pm.addItem(.separator())
        let moodItem = NSMenuItem(title: "Villains Are…", action: nil, keyEquivalent: "")
        let mm = NSMenu()
        for (title, mood) in [("Working (fighting)", Mood.working), ("Thinking", .thinking),
                              ("Waiting for you", .waiting), ("Idle", .idle)] {
            let item = NSMenuItem(title: title, action: #selector(setPlaygroundMood(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mood.rawValue
            item.state = playgroundMood == mood ? .on : .off
            mm.addItem(item)
        }
        moodItem.submenu = mm
        pm.addItem(moodItem)
        pm.addItem(.separator())
        pm.addItem(action: "Add All Villains", #selector(addAllVillains), target: self)
        if playground != nil {
            pm.addItem(action: "Exit Playground", #selector(exitPlayground), target: self)
        }
        root.submenu = pm
        return root
    }

    private func enterPlayground() {
        if playground == nil {
            playground = []
            playgroundAgents = []
            demo = false
        }
    }

    @objc private func togglePlaygroundVillain(_ sender: NSMenuItem) {
        enterPlayground()
        if let i = playground!.firstIndex(of: sender.tag) { playground!.remove(at: i) } else { playground!.append(sender.tag) }
        refreshStatus()
    }

    @objc private func togglePlaygroundAgent(_ sender: NSMenuItem) {
        enterPlayground()
        if let i = playgroundAgents.firstIndex(of: sender.tag) { playgroundAgents.remove(at: i) } else { playgroundAgents.append(sender.tag) }
        refreshStatus()
    }

    @objc private func setPlaygroundMood(_ sender: NSMenuItem) {
        enterPlayground()
        playgroundMood = Mood(rawValue: sender.representedObject as? String ?? "") ?? .working
        refreshStatus()
    }

    @objc private func addAllVillains() {
        enterPlayground()
        for l in Leader.allCases where !playground!.contains(l.rawValue) && !StatusStore.agentOnly.contains(l.rawValue) { playground!.append(l.rawValue) }
        refreshStatus()
    }

    @objc private func exitPlayground() {
        playground = nil
        refreshStatus()
    }

    @objc private func toggleDemo() {
        playground = nil
        demo.toggle()
        demoStart = Date().timeIntervalSince1970
        refreshStatus()
    }

    @objc private func forgetIdle() {
        StatusStore.forgetIdleSessions()
        refreshStatus()
    }

    @objc private func resetPosition() {
        UserDefaults.standard.removeObject(forKey: "anchorX")
        UserDefaults.standard.removeObject(forKey: "anchorY")
        home = clampHome(savedHome())     // re-applies the edge snap, so positions saved under older rules are corrected
        relayout()
        snapActors()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert("Couldn't change Launch at Login", error.localizedDescription)
        }
    }

    /// Menu fix for a hook issue: connect the AI, or jump to the silent session.
    @objc private func fixHookIssue(_ sender: NSMenuItem) {
        guard let what = sender.representedObject as? String else { return }
        if what.hasPrefix("jump:"), let pid = Int32(what.dropFirst(5)) { Jump.toSession(pid: pid); return }
        if what == "claude" { installHooks() } else { installOther(what) }
        lastHookCheck = 0
    }

    @objc private func installSaver() {
        do { try SaverInstaller.install() } catch {
            alert("Couldn't install the screen saver", error.localizedDescription)
            return
        }
        lastSaverCheck = -100   // start publishing as soon as it's in place
        SaverInstaller.openSettings()
        alert("Clawd Wars screen saver installed",
              "In the Wallpaper settings that just opened, go to Screen Saver and pick Clawd Wars (with the other screen savers, near the end of the list). Clawd Wars needs to be running for the crew to show.")
    }

    @objc private func removeSaver() {
        if !SaverInstaller.remove() {
            alert("Couldn't remove the screen saver", "Delete /Library/Screen Savers/Clawd Wars.saver in Finder (it asks for an admin password).")
        }
        lastSaverCheck = -100
    }

    @objc private func ignoreHookIssue(_ sender: NSMenuItem) {
        if let ai = sender.representedObject as? String { ignoreHooks(for: ai) }
    }

    /// Stop nagging about an AI that's installed but deliberately not connected (the banner's ×, or the menu).
    func ignoreHooks(for ai: String) {
        Self.ignoredHooks.insert(ai)
        hookIssues.removeAll { $0.install == ai }
        if windowMode { updateCards(Date().timeIntervalSince1970) }
    }

    @objc private func installHooks() {
        Self.ignoredHooks.remove("claude")
        do { try HookInstaller.install() } catch { alert("Couldn't install hooks", error.localizedDescription) }
    }

    @objc private func installOtherHooks(_ sender: NSMenuItem) { installOther(sender.representedObject as? String ?? "") }

    private func installOther(_ name: String) {
        guard let ai = HookInstaller.other(name) else { return }
        let display = HookInstaller.displayName(name)
        Self.ignoredHooks.remove(name)
        do {
            try HookInstaller.install(ai)
            alert("\(display) hooks installed", name == "codex"
                  ? "Codex only runs new hooks after you trust them: run /hooks in Codex and approve them. Codex sessions that are already open pick them up after a restart."
                  : "\(display) sessions that are already open pick them up after a restart.")
        } catch { alert("Couldn't install \(display) hooks", error.localizedDescription) }
    }

    @objc private func removeOtherHooks(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String, let ai = HookInstaller.other(name) else { return }
        Self.ignoredHooks.insert(name)   // removed on purpose: no "isn't connected" reminders
        do { try HookInstaller.uninstall(ai) } catch { alert("Couldn't remove \(HookInstaller.displayName(name)) hooks", error.localizedDescription) }
    }

    @objc private func removeHooks() {
        Self.ignoredHooks.insert("claude")
        do { try HookInstaller.uninstall() } catch { alert("Couldn't remove hooks", error.localizedDescription) }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func alert(_ title: String, _ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        a.runModal()
    }

    fileprivate var panelOrigin: NSPoint { panel.frame.origin }
}

private extension VaderMode {
    init(_ mood: Mood) {
        switch mood {
        case .idle: self = .idle
        case .thinking: self = .thinking
        case .working: self = .working
        case .waiting: self = .waiting
        }
    }
}

private extension NSMenu {
    func addItem(disabled title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        addItem(item)
    }

    func addItem(action title: String, _ selector: Selector, target: AnyObject, on: Bool = false) {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = target
        item.state = on ? .on : .off
        addItem(item)
    }
}

final class OverlayView: NSView {
    weak var controller: OverlayController?

    private let sprites = SpriteLayers()

    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}

    /// A new frame: the crew as Core Animation layers, scaled and composited on the GPU.
    func showFrame() {
        guard let controller else { return }
        wantsLayer = true
        guard let host = layer else { return }
        sprites.update(controller.items, origin: controller.panelOrigin, in: host,
                       pixelsPerPoint: window?.backingScaleFactor ?? 2)
    }

    /// Draw the scene's items (in screen coordinates) into the current context, offset by `origin`.
    /// Shared by the desktop overlay, the window's scene strip and the CLAWD_SHOT frame dump.
    static func render(_ items: [OverlayController.DrawItem], origin o: NSPoint, in ctx: CGContext) {
        ctx.interpolationQuality = .none
        for item in items {
            let r = item.rect.offsetBy(dx: -o.x, dy: -o.y)
            if let text = item.text {
                // Text is built opaque and faded here as a whole (as a layer's opacity does), so a fading label's
                // look doesn't change from frame to frame and `SpriteLayers` can cache it.
                ctx.saveGState()
                ctx.setAlpha(item.alpha)
                defer { ctx.restoreGState() }
                if item.boxed {
                    let box = NSBezierPath(roundedRect: r, xRadius: 4, yRadius: 4)
                    (item.agentBox ? NSColor(calibratedRed: 0.05, green: 0.10, blue: 0.24, alpha: 0.82)
                                   : NSColor(white: 0.08, alpha: 0.82)).setFill()
                    box.fill()
                    if let accent = item.accent {
                        accent.withAlphaComponent(0.9).setStroke()
                        box.lineWidth = 1.5
                    } else {
                        (item.agentBox ? NSColor(calibratedRed: 0.45, green: 0.65, blue: 1, alpha: 0.5)
                                       : NSColor(white: 1, alpha: 0.35)).setStroke()
                        box.lineWidth = 1
                    }
                    box.stroke()
                    // Rounded up, plus a point: drawn into exactly its measured (fractional) width, a line could
                    // wrap onto one that doesn't fit and be cut off.
                    let ts = text.size(), tw = ts.width.rounded(.up) + 1, th = ts.height.rounded(.up) + 1
                    text.draw(in: NSRect(x: r.midX - tw / 2, y: r.midY - th / 2, width: tw, height: th))
                    continue
                }
                text.draw(at: r.origin)
                continue
            }
            guard let image = item.image else { continue }
            ctx.saveGState()
            ctx.setAlpha(item.alpha)
            if item.mirrored {
                ctx.translateBy(x: r.maxX, y: r.minY)
                ctx.scaleBy(x: -1, y: 1)
                ctx.draw(image, in: NSRect(origin: .zero, size: r.size))
            } else {
                ctx.draw(image, in: r)
            }
            ctx.restoreGState()
        }
    }

    override func mouseDown(with event: NSEvent) { controller?.beginDrag() }
    override func mouseDragged(with event: NSEvent) { controller?.continueDrag() }
    override func mouseUp(with event: NSEvent) { controller?.endDrag() }

    override func rightMouseDown(with event: NSEvent) {
        guard let controller else { return }
        NSMenu.popUpContextMenu(controller.menu(), with: event, for: self)
    }
}
