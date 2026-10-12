import AppKit
import AVFoundation

// Renders the promo with the app's own sprite code: a storyboard sheet of key frames, or the video
// (1920×1080, 30 fps). Build it, then run it from the repo root (it reads docs/icon.png):
//   swiftc -O -swift-version 5 Sources/App/Pixel.swift Sources/App/Characters.swift Sources/App/Leaders.swift \
//          Sources/App/Cast.swift Sources/App/Habits.swift Sources/App/Cantina.swift Sources/App/Locations.swift Sources/Shared/*.swift \
//          Tools/RenderPromo/main.swift -o /tmp/renderpromo
//   /tmp/renderpromo storyboard promo     → storyboard.png + one PNG per key frame
//   /tmp/renderpromo video promo          → clawd-wars-promo.mp4 (H.264 + AAC soundtrack)
//   /tmp/renderpromo audio promo          → clawd-wars-promo.wav (just the soundtrack)
//   /tmp/renderpromo frame promo 9.5      → a single frame at 9.5 s

let W = 1920, H = 1080, fps = 30.0, duration = 45.7

// The stage the crew stands on. The whole frame by default; window mode narrows it to the scene strip.
var S = 6.0                      // screen pixels per sprite pixel for a session; agents are 2/3 of that
var groundY = 150.0              // fx-row of the floor line (the fx canvas is stageW/S × stageH/S, y down)
var stageW = Double(W), stageH = Double(H)

/// Runs `body` with the stage moved into `rect` (screen coordinates, y up), at `scale`, floor on fx-row `ground`.
func onStage(_ ctx: CGContext, _ rect: CGRect, scale: Double, ground: Double, _ body: () -> Void) {
    let saved = (S, groundY, stageW, stageH)
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.clip(to: CGRect(origin: .zero, size: rect.size))
    (S, groundY, stageW, stageH) = (scale, ground, Double(rect.width), Double(rect.height))
    body()
    (S, groundY, stageW, stageH) = saved
    ctx.restoreGState()
}

// MARK: Palette

let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
let claudeOrange = CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)
func hexColor(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

/// Every AI Clawd Wars supports, with its outline colour from `AIStyle`.
enum AI: CaseIterable { case claude, desktop, codex, qwen, gemini, copilot
    var hex: UInt32 {
        switch self {
        case .claude: return 0xFFFFFF; case .desktop: return 0xFF9E7A; case .codex: return 0x6FD3FF
        case .qwen: return 0xC08CFF; case .gemini: return 0xFFD166; case .copilot: return 0x7CF5A4
        }
    }
    var ns: NSColor { hexColor(hex) }
    var name: String {
        switch self {
        case .claude: return "Claude Code"; case .desktop: return "Claude Desktop"; case .codex: return "OpenAI Codex"
        case .qwen: return "Qwen Code"; case .gemini: return "Gemini CLI"; case .copilot: return "GitHub Copilot CLI"
        }
    }
    var tag: String {
        switch self {
        case .claude: return "CLAUDE"; case .desktop: return "DESKTOP"; case .codex: return "CODEX"
        case .qwen: return "QWEN"; case .gemini: return "GEMINI"; case .copilot: return "GITHUB\nCOPILOT CLI"
        }
    }
}

// MARK: Easing

func clamp(_ v: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(max(v, a), b) }
func easeOut(_ v: Double) -> Double { let x = clamp(v); return 1 - pow(1 - x, 3) }
func easeIn(_ v: Double) -> Double { let x = clamp(v); return x * x * x }
func backOut(_ v: Double) -> Double { let x = clamp(v), c = 1.9; return 1 + (c + 1) * pow(x - 1, 3) + c * pow(x - 1, 2) }
func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

// MARK: Actors

struct Actor {
    var cast: Cast
    var x: Double                         // body centre, fx units
    var facing: Double = 1                // +1 right, -1 left
    var session = true                    // sessions are drawn large, agents at 2/3
    var mode: VaderMode = .working
    var role: FightRole = .none
    var walking = false
    var urgent = false
    var bubble: BubbleKind? = nil
    var label: String? = nil
    var labelSize: CGFloat? = nil
    var ai: AI = .claude
    var lift = 0.0                        // fx units off the floor (jumps, drop-ins)
    var alpha = 1.0
    var grow = 1.0                        // extra size (Claude stands a head taller in the line-up)
    var k: Double { (session ? 1 : 2.0 / 3) * grow }
    var top: Double { groundY - 44 * k - lift }
    var fighter: Fighter {
        Fighter(weapon: cast.weapon, x: x, k: k, top: top, side: facing, muzzle: cast.muzzle)
    }
}

/// A character's sprite with its AI's outline, for portraits.
func portrait(_ who: Cast, ai: AI, t: Double = 0.4) -> CGImage? {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: .working, walking: false, role: .none, asSession: true)
    c.addOutline(C(ai.hex, 0.92))
    guard let b = c.opaqueBounds() else { return nil }
    return c.makeImage()?.cropping(to: b)
}

/// Draws one actor (sprite, speech bubble, label) into a CG context whose units are screen pixels, y up.
func draw(_ a: Actor, _ ctx: CGContext, t: Double) {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    a.cast.draw(c, t: t, mode: a.mode, walking: a.walking, role: a.role, urgent: a.urgent, asSession: a.session)
    if a.facing < 0 { c.flipHorizontally() }
    c.addOutline(C(a.ai.hex, 0.92))
    guard let img = c.makeImage() else { return }
    let px = S * a.k
    let x0 = (a.facing > 0 ? a.x - Sprite.bodyCenterX * a.k : a.x - (Double(Sprite.width) - Sprite.bodyCenterX) * a.k) * S
    let yTop = a.top * S
    ctx.saveGState(); ctx.setAlpha(CGFloat(a.alpha))
    ctx.draw(img, in: CGRect(x: x0, y: stageH - yTop - Double(Sprite.height) * px,
                             width: Double(Sprite.width) * px, height: Double(Sprite.height) * px))
    // Speech bubble beside the head, tail pointing back at it.
    if let kind = a.bubble {
        let bc = PixelCanvas(Bubble.width, Bubble.height)
        drawBubble(bc, kind: kind, t: t, urgent: a.urgent, tailRight: a.facing < 0)
        if let bi = bc.makeImage() {
            let headRow = a.top + Double(a.cast.headTop) * a.k
            let bx = a.facing > 0 ? a.x + 7 * a.k : a.x - 7 * a.k - Double(Bubble.width)
            let by = headRow - Double(Bubble.height) + 2
            ctx.draw(bi, in: CGRect(x: bx * S, y: stageH - (by + Double(Bubble.height)) * S,
                                    width: Double(Bubble.width) * S, height: Double(Bubble.height) * S))
        }
    }
    if let l = a.label {
        let headRow = a.top + Double(a.cast.headTop) * a.k
        let z = S / 6
        chip(l, ctx, centerX: a.x * S, bottomY: stageH - headRow * S + (a.session ? 22 : 16) * z,
             size: a.labelSize ?? max(15, (a.session ? 30 : 23) * z), agent: !a.session, accent: a.ai)
    }
    ctx.restoreGState()
}

/// The overlay's label: monospaced white text in a dark rounded box (agents: navy box, blue border).
func chip(_ s: String, _ ctx: CGContext, centerX: Double, bottomY: Double, size: CGFloat, agent: Bool, accent: AI = .claude) {
    let font = NSFont.monospacedSystemFont(ofSize: size, weight: agent ? .semibold : .bold)
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let text = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: p])
    let ts = text.size()
    let r = CGRect(x: centerX - ts.width / 2 - size * 0.5, y: bottomY, width: ts.width + size, height: ts.height + size * 0.4)
    let path = CGPath(roundedRect: r, cornerWidth: size * 0.3, cornerHeight: size * 0.3, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(agent ? CGColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 0.92) : CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.88))
    ctx.fillPath()
    ctx.addPath(path); ctx.setLineWidth(size * 0.1)
    let border = agent ? CGColor(red: 0.30, green: 0.48, blue: 0.85, alpha: 1)
                       : (accent == .claude ? CGColor(gray: 0.55, alpha: 1) : accent.ns.cgColor)
    ctx.setStrokeColor(border); ctx.strokePath()
    text.draw(in: CGRect(x: r.minX, y: r.minY + size * 0.2, width: r.width, height: ts.height))
}

/// Bolts, sparks and lightning between pairs, drawn on one fx-resolution pixel canvas over the whole stage.
func drawFX(_ pairs: [(Actor, Actor)], _ ctx: CGContext, t: Double) {
    guard !pairs.isEmpty else { return }
    let c = PixelCanvas(Int(stageW / S) + 1, Int(stageH / S) + 1)
    for (l, r) in pairs { drawFightFX(c, t: t, left: l.fighter, right: r.fighter) }
    if let img = c.makeImage() {
        ctx.draw(img, in: CGRect(x: 0, y: stageH - Double(c.h) * S, width: Double(c.w) * S, height: Double(c.h) * S))
    }
}

// MARK: Text

func attributed(_ s: String, size: CGFloat, weight: NSFont.Weight = .heavy, color: NSColor = .white, alpha: Double = 1,
                font: NSFont? = nil, kern: CGFloat = 0) -> NSAttributedString {
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.6 * alpha)
    shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -3)
    return NSAttributedString(string: s, attributes: [.font: font ?? NSFont.systemFont(ofSize: size, weight: weight),
                                                      .foregroundColor: color.withAlphaComponent(alpha), .kern: kern, .shadow: shadow])
}

func text(_ s: String, _ ctx: CGContext, x: Double? = nil, y: Double, size: CGFloat, weight: NSFont.Weight = .heavy,
          color: NSColor = .white, alpha: Double = 1, font: NSFont? = nil, kern: CGFloat = 0) {
    let a = attributed(s, size: size, weight: weight, color: color, alpha: alpha, font: font, kern: kern)
    a.draw(at: NSPoint(x: x ?? (Double(W) - a.size().width) / 2, y: y))
}

/// A caption that slides up and fades in at `start` (shot-local seconds).
func caption(_ s: String, _ ctx: CGContext, local: Double, start: Double = 0.1, y: Double = 900, size: CGFloat = 64,
             color: NSColor = .white, weight: NSFont.Weight = .heavy) {
    let f = easeOut((local - start) / 0.35)
    guard f > 0 else { return }
    text(s, ctx, y: y - 30 * (1 - f), size: size, weight: weight, color: color, alpha: f)
}

/// A small pill naming the mode on show ("DESKTOP MODE", "WINDOW MODE"), top-left.
func modeBadge(_ s: String, _ ctx: CGContext, local: Double) {
    let f = easeOut((local - 0.2) / 0.3)
    guard f > 0 else { return }
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 26, weight: .heavy),
                                                       .foregroundColor: NSColor.black, .kern: 3])
    let sz = a.size()
    let r = CGRect(x: 60 - 40 * (1 - f), y: 980, width: sz.width + 36, height: sz.height + 16)
    ctx.saveGState(); ctx.setAlpha(CGFloat(f))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: r.height / 2, cornerHeight: r.height / 2, transform: nil))
    ctx.setFillColor(yellow.cgColor); ctx.fillPath()
    a.draw(at: NSPoint(x: r.minX + 18, y: r.minY + 8))
    ctx.restoreGState()
}

// MARK: Backgrounds

/// The user's desktop: a dusky wallpaper with three terminal windows (dimmed once the battle starts).
func desktop(_ ctx: CGContext, dim: Double, floor: Bool = true) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.20, green: 0.21, blue: 0.29, alpha: 1),
                                CGColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    // menu bar
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.35)); ctx.fill(CGRect(x: 0, y: H - 34, width: W, height: 34))
    let lines = [["claude ▸ refactor the hook installer", "● Reading HookInstaller.swift", "● Editing 3 files…", "✻ Thinking…"],
                 ["codex ▸ write the changelog", "● Bash(git log --oneline)", "", "Allow this command?  ❯ Yes   No"],
                 ["gemini ▸ add a tauntaun", "✓ Done in 4m 12s", "", "> _"]]
    for i in 0..<3 {
        let r = CGRect(x: 110 + Double(i) * 580, y: 330 + Double(i % 2) * 70, width: 540, height: 360)
        ctx.saveGState(); ctx.setAlpha(CGFloat(1 - dim * 0.75))
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: CGColor(gray: 0, alpha: 0.5))
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 14, cornerHeight: 14, transform: nil))
        ctx.setFillColor(CGColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0)
        trafficLights(ctx, x: r.minX + 18, y: r.maxY - 30)
        for (j, l) in lines[i].enumerated() {
            let col: NSColor = j > 0 ? NSColor(white: 0.8, alpha: 1) : (i == 0 ? NSColor(cgColor: claudeOrange)! : [AI.codex, .gemini][i - 1].ns)
            NSAttributedString(string: l, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 21, weight: .medium),
                                                       .foregroundColor: col])
                .draw(at: NSPoint(x: r.minX + 24, y: r.maxY - 90 - Double(j) * 44))
        }
        ctx.restoreGState()
    }
    // the dark floor band the battle stands on
    if floor {
        ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.14, alpha: dim * 0.55))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: Int(Double(H) - groundY * S + 6)))
    }
}

func trafficLights(_ ctx: CGContext, x: Double, y: Double, d: Double = 14) {
    for (j, col) in [CGColor(red: 1, green: 0.37, blue: 0.34, alpha: 1), CGColor(red: 1, green: 0.74, blue: 0.18, alpha: 1),
                     CGColor(red: 0.16, green: 0.79, blue: 0.25, alpha: 1)].enumerated() {
        ctx.setFillColor(col); ctx.fillEllipse(in: CGRect(x: x + Double(j) * d * 1.7, y: y, width: d, height: d))
    }
}

func space(_ ctx: CGContext, t: Double) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<220 {
        let big = noise(i * 3 + 2) > 0.85
        let tw = 0.6 + 0.4 * sin(t * 3 + Double(i))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: (big ? 0.9 : 0.45) * tw))
        let s = big ? 6.0 : 3.0
        let x = (noise(i * 3) * Double(W) - t * (big ? 40 : 20)).truncatingRemainder(dividingBy: Double(W))
        ctx.fill(CGRect(x: x < 0 ? x + Double(W) : x, y: 250 + noise(i * 3 + 1) * Double(H - 250), width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 240))
    ctx.setFillColor(claudeOrange); ctx.fill(CGRect(x: 0, y: 236, width: W, height: 6))
}

let appIcon: CGImage? = NSImage(contentsOfFile: "docs/icon.png")?.cgImage(forProposedRect: nil, context: nil, hints: nil)

// MARK: Window mode

/// One card in the window, as the app draws it: portrait, name · project, status pill, a few lines, agents.
struct Card {
    var who: Cast; var ai: AI; var name: String; var project: String
    var status: String; var statusColor: NSColor
    var lines: [(String, NSColor)]
    var agents: [(Cast, String, String, String)] = []   // portrait, name, task, detail
}

let dimText = NSColor(white: 0.62, alpha: 1), bodyText = NSColor(white: 0.9, alpha: 1)

/// Draws a card with its top-left at (x, top); returns its height. `z` scales the app's point sizes.
@discardableResult
func drawCard(_ c: Card, _ ctx: CGContext, x: Double, top: Double, width: Double, panel: NSColor, z: Double) -> Double {
    let pad = 14 * z, lineH = 19 * z, agentH = 36 * z
    let h = pad * 2 + 22 * z + Double(c.lines.count) * lineH + (c.agents.isEmpty ? 0 : 6 * z + Double(c.agents.count) * agentH)
    let r = CGRect(x: x, y: top - h, width: width, height: h)
    let box = CGPath(roundedRect: r, cornerWidth: 8 * z, cornerHeight: 8 * z, transform: nil)
    ctx.addPath(box); ctx.setFillColor((panel.blended(withFraction: 0.35, of: .black) ?? panel).withAlphaComponent(0.94).cgColor); ctx.fillPath()
    ctx.addPath(box); ctx.setStrokeColor(c.ai.ns.withAlphaComponent(0.55).cgColor); ctx.setLineWidth(1.5 * z); ctx.strokePath()

    func put(_ s: NSAttributedString, _ px: Double, _ py: Double) { s.draw(at: NSPoint(x: px, y: py)) }
    func str(_ s: String, _ size: Double, _ w: NSFont.Weight, _ col: NSColor, mono: Bool = false) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [.font: mono ? NSFont.monospacedSystemFont(ofSize: size * z, weight: w)
                                                                : NSFont.systemFont(ofSize: size * z, weight: w), .foregroundColor: col])
    }
    // portrait, pixel-crisp, bottom-centred in a 96×80 (app points) box
    if let img = portrait(c.who, ai: c.ai) {
        let k = (min(96 * z / Double(img.width), 80 * z / Double(img.height), 2 * z)).rounded(.down)
        let w = Double(img.width) * k, ih = Double(img.height) * k
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: r.minX + 10 * z + (96 * z - w) / 2, y: r.maxY - pad - 80 * z, width: w, height: ih))
        ctx.restoreGState()
    }
    let tx = r.minX + 26 * z + 96 * z
    var ty = r.maxY - pad - 18 * z
    let status = str(c.status, 11, .bold, c.statusColor, mono: true)
    let sw = status.size().width
    let pill = CGRect(x: r.maxX - 12 * z - sw - 14 * z, y: ty - 3 * z, width: sw + 14 * z, height: 19 * z)
    ctx.addPath(CGPath(roundedRect: pill, cornerWidth: 9.5 * z, cornerHeight: 9.5 * z, transform: nil))
    ctx.setFillColor(c.statusColor.withAlphaComponent(0.16).cgColor); ctx.fillPath()
    put(status, pill.minX + 7 * z, pill.minY + 2 * z)
    let header = NSMutableAttributedString(attributedString: str(c.name, 14, .bold, .white))
    header.append(str("  ·  " + c.project, 13, .semibold, c.ai.ns))
    put(header, tx, ty)
    ty -= 22 * z
    for (l, col) in c.lines { put(str(l, 11.5, .regular, col), tx, ty); ty -= lineH }
    if !c.agents.isEmpty {
        ty -= 6 * z
        for (who, name, task, detail) in c.agents {
            if let img = portrait(who, ai: c.ai) {
                let k = (min(36 * z / Double(img.width), 30 * z / Double(img.height))).rounded(.down)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: tx - 4 * z, y: ty - 14 * z, width: Double(img.width) * k, height: Double(img.height) * k))
                ctx.restoreGState()
            }
            let title = NSMutableAttributedString(attributedString: str(name, 11.5, .semibold, .white))
            title.append(str("  ·  " + task, 11.5, .regular, c.ai.ns))
            put(title, tx + 40 * z, ty)
            put(str(detail, 10.5, .regular, dimText), tx + 40 * z, ty - 16 * z)
            ty -= agentH
        }
    }
    return h
}

/// The "Show in Window" window: themed title bar, the cantina with the crew in it, a card per session.
func windowMode(_ ctx: CGContext, frame r: CGRect, local: Double, t: Double) {
    let loc = Location.cantina
    let panel = loc.panel
    let z = 2.0, cz = 1.5                         // app points → screen pixels (window chrome, cards)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.6))
    let outline = CGPath(roundedRect: r, cornerWidth: 22, cornerHeight: 22, transform: nil)
    ctx.addPath(outline); ctx.setFillColor((panel.blended(withFraction: 0.45, of: .black) ?? panel).cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(outline); ctx.clip()
    // title bar
    let barH = 30 * z
    trafficLights(ctx, x: r.minX + 20, y: r.maxY - barH / 2 - 7, d: 15)
    let where_ = NSAttributedString(string: loc.name.uppercased(), attributes: [
        .font: NSFont.systemFont(ofSize: 10.5 * z, weight: .semibold), .foregroundColor: NSColor(white: 0.78, alpha: 1), .kern: 1.2 * z])
    where_.draw(at: NSPoint(x: r.maxX - where_.size().width - 28, y: r.maxY - barH / 2 - where_.size().height / 2))
    // the scene strip: the cantina at 2 px per pixel in the app, so 4 here
    let px = Double(Cantina.pixel) * z
    let stripH = 100.0 * z
    let strip = CGRect(x: r.minX, y: r.maxY - barH - stripH, width: r.width, height: stripH)
    let cw = Int((strip.width / px).rounded(.up)), ch = Int(stripH / px)
    let floorRows = Int(20 / Double(Cantina.pixel))
    let room = PixelCanvas(cw, ch); loc.drawStatic(room, floorRows: floorRows)
    let live = PixelCanvas(cw, ch); loc.drawAnimated(live, floorRows: floorRows, t: t)
    ctx.saveGState(); ctx.interpolationQuality = .none
    for c in [room, live] { if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: strip.minX, y: strip.minY, width: Double(cw) * px, height: Double(ch) * px)) } }
    ctx.restoreGState()
    // the crew in the cantina (sessions at the app's Small size: 2 pt per pixel → 4 px)
    let needsYou = local > 2.5
    onStage(ctx, strip, scale: px, ground: Double(ch) - Double(floorRows) * 0.45) {
        let vader = Actor(cast: .villain(.vader), x: 200, facing: -1, role: .duel)
        var luke = Actor(cast: .hero(.luke), x: 143, role: .duel, ai: .codex)
        if needsYou { luke.role = .none; luke.mode = .waiting; luke.bubble = .waiting; luke.urgent = true; luke.lift = abs(sin(t * 2 * .pi * 1.6)) * 4 }
        var v = vader; if needsYou { v.role = .none }
        let han = Actor(cast: .hero(.han), x: 260, facing: -1, session: false, role: .cheer, label: "Run the tests")
        let chewie = Actor(cast: .hero(.chewie), x: 300, facing: -1, session: false, role: .cheer, label: "Check git history")
        let r2 = Actor(cast: .hero(.r2d2), x: 95, facing: 1, session: false, ai: .codex)
        for a in [r2, luke, v, han, chewie] { draw(a, ctx, t: t) }
        if !needsYou { drawFX([(luke, vader)], ctx, t: t) }
    }
    // cards
    let ticks = max(0, Int(local))
    let now = ["Now: Read Overlay.swift", "Now: Edit WindowMode.swift", "Now: Bash: swift build"][min(2, max(0, Int(local / 0.9)))]
    var top = strip.minY - 10 * cz
    let x = r.minX + 10 * cz, w = r.width - 20 * cz
    top -= drawCard(Card(who: .villain(.vader), ai: .claude, name: "Darth Vader", project: "idle-claude",
                         status: "WORKING · \(24 + ticks)s", statusColor: NSColor(srgbRed: 0.45, green: 0.85, blue: 0.45, alpha: 1),
                         lines: [("claude-opus-5-5", dimText), (now, bodyText), ("You: “add a tauntaun”", bodyText)],
                         agents: [(.hero(.han), "Han Solo", "Run the tests", "Bash: swift test · \(34 + ticks)s · 9 tool calls"),
                                  (.hero(.chewie), "Chewbacca", "Check git history", "Bash: git log · 1m \(21 + ticks)s · 25 tool calls")]),
                    ctx, x: x, top: top, width: w, panel: panel, z: cz) + 10 * cz
    // the Codex group divider, then its card
    let g = NSAttributedString(string: "CODEX", attributes: [.font: NSFont.systemFont(ofSize: 10.5 * cz, weight: .heavy), .kern: 1.2 * cz,
                                                             .foregroundColor: AI.codex.ns])
    let gs = g.size()
    g.draw(at: NSPoint(x: x + 2 * cz, y: top - gs.height - 2 * cz))
    ctx.setFillColor(AI.codex.ns.withAlphaComponent(0.35).cgColor)
    ctx.fill(CGRect(x: x + gs.width + 10 * cz, y: top - gs.height / 2 - 2 * cz, width: w - gs.width - 12 * cz, height: cz))
    top -= 22 * cz
    drawCard(Card(who: .hero(.luke), ai: .codex, name: "Luke Skywalker", project: "website",
                  status: needsYou ? "NEEDS YOU · \(max(1, Int(local - 2.5) + 1))s" : "THINKING",
                  statusColor: needsYou ? NSColor(srgbRed: 1, green: 0.42, blue: 0.42, alpha: 1) : NSColor(white: 0.85, alpha: 1),
                  lines: [("gpt-5-codex", dimText), (needsYou ? "Wants to run: npm run deploy" : "Now: Thinking…", bodyText),
                          ("You: “make the hero section pop”", bodyText)]),
             ctx, x: x, top: top, width: w, panel: panel, z: cz)
    ctx.restoreGState()
}

// MARK: Opening (the Episode IV opening, in pixels)

let fxW = W / 6, fxH = H / 6        // the opening is drawn on one 320×180 pixel canvas, 6 px per pixel

/// Draws a full-frame pixel canvas onto the screen, crisp.
func blit(_ c: PixelCanvas, _ ctx: CGContext) {
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6))
    ctx.restoreGState()
}

/// Deep-space starfield; `shift` moves it up (the camera tilting down).
func starfield(_ c: PixelCanvas, shift: Double = 0, t: Double) {
    for i in 0..<260 {
        let x = Int(noise(i * 5) * Double(c.w))
        let y = Int((noise(i * 5 + 1) * Double(c.h + 120) - shift).rounded()) - 0
        guard y >= 0, y < c.h else { continue }
        let b = noise(i * 5 + 2)
        let tw = 0.75 + 0.25 * sin(t * 4 + Double(i))
        if b > 0.93 {                                   // a few bright ones with a little cross
            c.px(x, y, C(0xFFFFFF, tw)); c.px(x - 1, y, C(0xBFD8FF, 0.5 * tw)); c.px(x + 1, y, C(0xBFD8FF, 0.5 * tw))
            c.px(x, y - 1, C(0xBFD8FF, 0.5 * tw)); c.px(x, y + 1, C(0xBFD8FF, 0.5 * tw))
        } else {
            c.px(x, y, C(0xFFFFFF, (0.25 + b * 0.5) * tw))
        }
    }
}

/// Tatooine rising from the bottom of the frame, with its two moons. `rise` 0…1 brings it into view.
func tatooine(_ c: PixelCanvas, rise: Double) {
    let r = 330.0, cx = 205.0, cy = Double(c.h) + r - 34 - (1 - rise) * 70
    let bands = [C(0xE2B77A), C(0xD8A465), C(0xC98F52), C(0xDDAE70), C(0xB97C44), C(0xD39C5E)]
    for y in min(c.h, max(0, Int(cy - r)))..<c.h {
        let dy = Double(y) - cy
        let half = max(0, r * r - dy * dy).squareRoot()
        let x0 = max(0, Int(cx - half)), x1 = min(c.w - 1, Int(cx + half))
        guard x0 <= x1 else { continue }
        for x in x0...x1 {
            let dx = Double(x) - cx
            let lat = Int((dy + r) / 9 + noise(x / 7 + y * 3) * 1.2) % bands.count
            var col = bands[lat]
            // the night side to the left, dithered at the terminator
            let shade = (dx + r * 0.35) / (r * 0.6)
            if shade < 0 || (shade < 0.1 && (x + y) % 2 == 0) { col = C(0x3A2416) }
            else if shade < 0.2 && (x + y) % 3 == 0 { col = C(0x7A4E2C) }
            // thin bright atmosphere at the limb
            if hypot(dx, dy) > r - 1.5 && shade > 0 { col = C(0xF6E2B8) }
            c.px(x, y, col)
        }
    }
    // the two moons, up and to the left of the planet
    for (mx, my, mr) in [(70.0, cy - r - 40 + 30 * rise, 9.0), (98.0, cy - r - 18 + 30 * rise, 5.0)] {
        for y in Int(my - mr)...Int(my + mr) {
            for x in Int(mx - mr)...Int(mx + mr) where hypot(Double(x) - mx, Double(y) - my) <= mr && y >= 0 && y < c.h {
                let lit = Double(x) - mx > -mr * 0.2
                c.px(x, y, lit ? C(0xD9D2C4) : C(0x4A4640))
            }
        }
    }
}

/// The Tantive IV seen from behind as it flees: engine bank at the top, hammerhead nose at the bottom.
let tantiveRows = [
    "..EEEEEEEEE..",
    ".EEEEEEEEEEE.",
    ".HHHHHHHHHHH.",
    "HHHHHHHHHHHHH",
    "HHDHHDHHDHHDH",
    ".HHHHHHHHHHH.",
    "...HHHHHHH...",
    "....HHHHH....",
    "....HLHLH....",
    "....HHHHH....",
    "....HLHLH....",
    "....HHHHH....",
    "...HHHHHHH...",
    "..HHHHHHHHH..",
    "..HLLHHHLLH..",
    "..HHHHHHHHH..",
    "...HHHHHHH...",
    "....HHHHH....",
    ".....HWH.....",
    "......H......",
]

func tantive(t: Double) -> PixelCanvas {
    let c = PixelCanvas(15, tantiveRows.count + 2)
    c.pattern(1, 1, tantiveRows, ["H": C(0xD6D4CC), "D": C(0x8A8880), "L": C(0x6FA0D0), "W": C(0xFFFFFF),
                                  "E": C(0xFFC8D0, 0.75 + 0.25 * sin(t * 30))])
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// The Star Destroyer seen from below, nose pointing the way it flies (down the frame). `tipY` is the row of
/// its nose; the hull reaches `length` rows back up to the engine block.
let sdLength = 300.0, sdHalf = 190.0, sdX = 165.0

func starDestroyer(_ c: PixelCanvas, tipY: Double, t: Double) {
    let base = tipY - sdLength
    let lit = [C(0xA9ABB0), C(0x9A9CA2), C(0xB9BBC0)], shade = [C(0x8F9197), C(0x82848A), C(0x9C9EA4)]
    for y in min(c.h, max(0, Int(base) - 18))..<max(min(c.h, max(0, Int(base) - 18)), min(c.h, Int(tipY) + 1)) {
        let back = tipY - Double(y)                       // rows behind the nose
        if back > sdLength {                              // the engine block behind the hull
            let hw = sdHalf * 0.8
            let x0 = max(0, Int(sdX - hw)), x1 = min(c.w - 1, Int(sdX + hw))
            guard x0 <= x1 else { continue }
            for x in x0...x1 {
                let g = noise(y * 211 + x * 13)
                c.px(x, y, g > 0.9 ? C(0x6A6C72) : (x % 7 == 0 ? C(0x45474C) : C(0x55575D)))
            }
            continue
        }
        let hw = back * sdHalf / sdLength
        guard hw >= 0.5 else { c.px(Int(sdX), y, C(0xC9CBD0)); continue }
        let row = Int(back), band = row / 10
        let segW = 5 + Int(noise(band * 17) * 8)
        let x0 = max(0, Int(sdX - hw)), x1 = min(c.w - 1, Int(sdX + hw))
        guard x0 <= x1 else { continue }
        for x in x0...x1 {
            let dx = Double(x) - sdX, edge = hw - abs(dx)
            let seg = (x + 400) / segW
            let tone = noise(band * 131 + seg)
            let pal = dx < 0 ? lit : shade                                 // lit from the left
            var col = tone < 0.15 ? pal[1] : (tone > 0.85 ? pal[2] : pal[0])
            if (x + 400) % segW == 0 && edge > 3 { col = C(0x74767C) }      // plate seams
            if row % 10 == 0 && edge > 3 { col = C(0x6A6C72) }
            let g = noise(row * 313 + x * 7)
            if edge > 8 && g > 0.996 { col = C(0x55575D) } else if edge > 8 && g > 0.992 { col = C(0xD4D6DA) }   // greebles
            if edge >= 6 && edge < 7 { col = C(0x5E6066) }                 // trench along each edge
            if edge < 2.5 { col = dx < 0 ? C(0xD0D2D6) : C(0x6E7076) }     // bevelled rims
            if abs(dx) < 1.5 { col = C(0x6E7076) }                         // keel line
            if row > 118 && row < 150 && abs(dx) < 16 {                     // the docking bay
                col = (row == 119 || row == 149 || abs(dx) > 14.5) ? C(0x8A8C92) : C(0x24262A)
            }
            c.px(x, y, col)
        }
        // running lights along the edges
        if row % 18 == 7 {
            let on = sin(t * 6 + Double(row)) > 0
            c.px(Int(sdX - hw) + 3, y, on ? C(0xFFFFFF) : C(0x9FA3AA)); c.px(Int(sdX + hw) - 3, y, on ? C(0xFFFFFF) : C(0x9FA3AA))
        }
    }
    // three big engines glowing at the back, flickering
    let ey = Int(base) - 18
    for (k, ex) in [sdX - 80, sdX, sdX + 80].enumerated() {
        let r = (k == 1 ? 13.0 : 10.0) + sin(t * 25 + Double(k)) * 0.6
        for y in (ey - Int(r))...(ey + Int(r)) where y >= 0 && y < c.h {
            for x in Int(ex - r)...Int(ex + r) where x >= 0 && x < c.w {
                let d = hypot(Double(x) - ex, Double(y - ey))
                if d <= r { c.px(x, y, d < r * 0.45 ? C(0xFFFFFF) : (d < r * 0.75 ? C(0xBFE0FF) : C(0x6FB8FF))) }
            }
        }
    }
}

/// The chase: where the Tantive IV is at shot-local time `l` (fx units) and how big.
func tantivePos(_ l: Double) -> (x: Double, y: Double, k: Double) {
    let f = easeOut((l - 1.6) / 3.0)
    return (lerp(186, 150, f) + sin(l * 2.3) * 3, lerp(-28, 118, f) + (l > 4.6 ? (l - 4.6) * 3 : 0), lerp(1.4, 0.7, clamp((l - 1.6) / 6)))
}

func destroyerTip(_ l: Double) -> Double { -4 + (l - 3.0) * 85 }

func openingBattle(_ ctx: CGContext, local l: Double, t: Double) {
    let tilt = easeOut((l - 0.2) / 1.6)
    let sky = PixelCanvas(fxW, fxH)
    sky.rect(0, 0, fxW, fxH, C(0x000000))
    starfield(sky, shift: 60 * tilt, t: t)
    tatooine(sky, rise: tilt)
    blit(sky, ctx)
    // the blockade runner, behind the destroyer
    let p = tantivePos(l)
    if l > 1.4 && l < 6.5 {                    // swallowed by the destroyer after that
        let tc = tantive(t: t)
        if let img = tc.makeImage() {
            let s = 6 * p.k
            ctx.saveGState(); ctx.interpolationQuality = .none
            ctx.draw(img, in: CGRect(x: p.x * 6 - Double(tc.w) * s / 2, y: Double(H) - (p.y * 6 + Double(tc.h) * s / 2),
                                     width: Double(tc.w) * s, height: Double(tc.h) * s))
            ctx.restoreGState()
        }
    }
    // the destroyer, closest to us
    let tip = destroyerTip(min(l, 7.05))      // it comes to rest with its engines at the top
    let fx = PixelCanvas(fxW, fxH)
    if tip > -2 {
        starDestroyer(fx, tipY: tip, t: t)
        fx.addOutline(C(0xFFFFFF, 0.92))
    }
    // red turbolaser bolts chasing the runner: from off the top at first, then from the destroyer's nose
    for i in 0..<40 {
        let born = 1.3 + Double(i) * 0.17
        let age = l - born
        guard age > 0, age < 0.55 else { continue }
        let tipAt = destroyerTip(born)
        let from = tipAt > 4 ? (sdX + (noise(i * 7) - 0.5) * 30, tipAt - noise(i * 7 + 1) * 20) : (150 + noise(i * 7) * 70, -4.0)
        let aim = tantivePos(born + 0.45)
        let miss = (noise(i * 7 + 2) - 0.5) * 34
        let to = (aim.x + miss, aim.y + abs(miss) * 0.3)
        let g = age / 0.55
        let x = lerp(from.0, to.0, g), y = lerp(from.1, to.1, g)
        let len = hypot(to.0 - from.0, to.1 - from.1)
        let ux = (to.0 - from.0) / max(len, 0.01), uy = (to.1 - from.1) / max(len, 0.01)
        fx.glowLine(x - ux * 7, y - uy * 7, x, y, core: C(0xFFE0E0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 1.8)
        if g > 0.92 && abs(miss) < 8 { drawSparks(fx, x: to.0, y: to.1, t: t, size: 3) }
    }
    blit(fx, ctx)
}

// MARK: Shots

struct Shot {
    let name: String; let start: Double; let end: Double
    var cut = false                                   // comes in on a hard cut instead of a wipe
    let render: (CGContext, Double, Double) -> Void
}

let shots: [Shot] = [
    // 0a · The parody of the film's opening line, in that blue, on black.
    Shot(name: "longago", start: 0, end: 3.5) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let a = clamp(local / 0.6) * (1 - clamp((local - 2.7) / 0.6))
        let blue = NSColor(srgbRed: 0.29, green: 0.84, blue: 0.93, alpha: a)
        let font = NSFont.systemFont(ofSize: 60, weight: .regular)
        for (i, line) in ["A long time ago, in a terminal", "far, far away...."].enumerated() {
            NSAttributedString(string: line, attributes: [.font: font, .foregroundColor: blue]).draw(at: NSPoint(x: 520, y: 580 - Double(i) * 84))
        }
    },
    // 0b · The logo, outlined in yellow, falling away into the stars.
    Shot(name: "logo", start: 3.5, end: 7.0, cut: true) { ctx, local, t in
        let sky = PixelCanvas(fxW, fxH)
        sky.rect(0, 0, fxW, fxH, C(0x000000)); starfield(sky, t: t); blit(sky, ctx)
        let p = clamp(local / 3.5)
        let s = 2.4 * exp(-3.4 * p)
        let a = 1 - clamp((p - 0.8) / 0.2)
        let tf = NSFont(name: "Futura-CondensedExtraBold", size: 260) ?? .systemFont(ofSize: 240, weight: .black)
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: s, y: s)
        for (i, word) in ["CLAWD", "WARS"].enumerated() {
            let w = NSAttributedString(string: word, attributes: [.font: tf, .kern: 20, .strokeWidth: 3,
                                                                  .strokeColor: yellow.withAlphaComponent(a)])
            let sz = w.size()
            w.draw(at: NSPoint(x: -sz.width / 2, y: i == 0 ? 0 : -sz.height * 0.82))
        }
        ctx.restoreGState()
    },
    // 0c · Tilt down to Tatooine: the Tantive IV runs, the Star Destroyer slides in overhead and keeps coming.
    Shot(name: "destroyer", start: 7.0, end: 15.5, cut: true) { ctx, local, t in
        openingBattle(ctx, local: local, t: t)
    },
    // 1 · The hook: three AIs at work in three terminals, and one overwhelmed human.
    Shot(name: "hook", start: 15.5, end: 19.5) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom)
        ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    // 2 · Desktop mode: they become a Star Wars brawl along the bottom of the screen.
    Shot(name: "desktop", start: 19.5, end: 24.1) { ctx, local, t in
        desktop(ctx, dim: easeOut(local / 0.4))
        let drop = { (d: Double) -> Double in max(0, 40 * (1 - easeIn((local - d) / 0.3))) }
        var vader = Actor(cast: .villain(.vader), x: 62, mode: .working, role: .duel, label: "idle-claude")
        var luke = Actor(cast: .hero(.luke), x: 119, facing: -1, mode: .working, role: .duel, label: "website", ai: .codex)
        var han = Actor(cast: .hero(.han), x: 190, session: false, role: .shoot(offset: 0), label: "Run the test suite")
        var trooper = Actor(cast: .villain(.trooper), x: 246, facing: -1, session: false, role: .shoot(offset: blasterPeriod / 2),
                            label: "Review Overlay.swift", ai: .codex)
        vader.lift = drop(0); luke.lift = drop(0.12); han.lift = drop(0.24); trooper.lift = drop(0.32)
        for a in [vader, luke, han, trooper] where a.lift < 40 { draw(a, ctx, t: t) }
        if local > 0.45 { drawFX([(vader, luke), (han, trooper)], ctx, t: t) }
        modeBadge("DESKTOP MODE", ctx, local: local)
        caption("Now they're a pixel-art Star Wars brawl", ctx, local: local, start: 0.35, y: 900)
        caption("along the bottom of your screen. They fight while they work.", ctx, local: local, start: 0.6, y: 830,
                size: 40, color: yellow, weight: .bold)
    },
    // 3 · Status at a glance: working, thinking, needs you, napping.
    Shot(name: "status", start: 24.1, end: 28.3) { ctx, local, t in
        desktop(ctx, dim: 1)
        let cast: [(Cast, AI, VaderMode, BubbleKind?, String, NSColor)] = [
            (.villain(.vader), .claude, .working, nil, "WORKING", NSColor(srgbRed: 0.45, green: 0.85, blue: 0.45, alpha: 1)),
            (.villain(.emperor), .qwen, .thinking, .thinking, "THINKING…", NSColor(white: 0.9, alpha: 1)),
            (.villain(.boba), .gemini, .waiting, .waiting, "NEEDS YOU!", NSColor(srgbRed: 1, green: 0.4, blue: 0.4, alpha: 1)),
            (.villain(.jabba), .copilot, .idle, .sleeping, "NAPPING", NSColor(srgbRed: 0.6, green: 0.55, blue: 1, alpha: 1)),
        ]
        for (i, (who, ai, mode, bubble, word, col)) in cast.enumerated() {
            let d = 0.1 + Double(i) * 0.22
            let f = backOut((local - d) / 0.35)
            guard local > d else { continue }
            var a = Actor(cast: who, x: 48 + Double(i) * 75, mode: mode, bubble: bubble, ai: ai)
            a.urgent = mode == .waiting
            if a.urgent { a.lift = abs(sin(t * 2 * .pi * 1.6)) * 6 }      // ignored for a minute: it jumps
            a.lift += (1 - f) * -8
            a.alpha = clamp(f)
            draw(a, ctx, t: t)
            let w = NSAttributedString(string: word, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .black), .kern: 2]).size().width
            text(word, ctx, x: a.x * S - w / 2, y: 70, size: 40, weight: .black, color: col, alpha: clamp(f), kern: 2)
        }
        caption("All fun and games, and you still see everything.", ctx, local: local, start: 0.05, y: 900, size: 58)
        caption("(Leave Boba waiting and he starts jumping.)", ctx, local: local, start: 0.9, y: 835, size: 36,
                color: yellow, weight: .bold)
    },
    // 4 · Subagents march in, each labelled with its task.
    Shot(name: "agents", start: 28.3, end: 32.3) { ctx, local, t in
        desktop(ctx, dim: 1)
        draw(Actor(cast: .villain(.vader), x: 262, facing: -1, mode: .standGuard, label: "idle-claude"), ctx, t: t)
        let crew: [(Companion, String, Double)] = [(.luke, "Find hook events", 190), (.leia, "Write changelog", 140),
                                                   (.chewie, "Check git history", 90), (.r2d2, "Plan the refactor", 40)]
        for (i, (who, task, stop)) in crew.enumerated() {
            let d = Double(i) * 0.18
            let f = easeOut((local - d) / 0.75)
            let x = lerp(-30, stop, f)
            draw(Actor(cast: .hero(who), x: x, session: false, walking: f < 0.98, label: task), ctx, t: t)
        }
        caption("Every subagent reports for duty.", ctx, local: local, start: 0.1, y: 900)
        caption("Its job is right there on its label. No more guessing.", ctx, local: local, start: 0.45, y: 835, size: 40,
                color: yellow, weight: .bold)
    },
    // 5 · Window mode: the crew in the cantina, a live card for every session.
    Shot(name: "window", start: 32.3, end: 37.1) { ctx, local, t in
        desktop(ctx, dim: 1, floor: false)
        let f = easeOut(local / 0.6), s = 0.94 + 0.06 * f
        let base = CGRect(x: 300, y: 20, width: 1320, height: 800)
        let r = CGRect(x: base.midX - base.width * s / 2, y: base.minY + 20 * (1 - f), width: base.width * s, height: base.height * s)
        windowMode(ctx, frame: r, local: local, t: t)
        modeBadge("WINDOW MODE", ctx, local: local)
        caption("Prefer a window? Grab the popcorn.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4,
                y: 890, size: 32, color: yellow, weight: .bold)
    },
    // 6 · Every AI it supports, Claude first and biggest, each with its own outline.
    Shot(name: "ais", start: 37.1, end: 41.5) { ctx, local, t in
        desktop(ctx, dim: 1)
        // the line-up: Claude a head taller, duelling Codex; everyone else cheering
        let lineup: [(Cast, AI, Double, Double, FightRole)] = [
            (.villain(.kylo), .desktop, 36, -1, .cheer), (.villain(.vader), .claude, 104, 1, .duel), (.hero(.luke), .codex, 165, -1, .duel),
            (.hero(.yoda), .qwen, 216, -1, .cheer), (.hero(.leia), .gemini, 258, -1, .cheer), (.hero(.r2d2), .copilot, 298, -1, .cheer),
        ]
        var actors: [Actor] = []
        for (i, (who, ai, x, facing, role)) in lineup.enumerated() {
            let d = 0.15 + Double(i) * 0.1
            guard local > d else { continue }
            let f = backOut((local - d) / 0.3)
            var a = Actor(cast: who, x: x, facing: facing, role: role, label: ai.tag, ai: ai)
            if ai == .claude { a.grow = 1.25; a.labelSize = 36 } else { a.labelSize = 22 }
            a.lift = (1 - f) * -10; a.alpha = clamp(f)
            actors.append(a)
            draw(a, ctx, t: t)
        }
        if actors.count >= 3 { drawFX([(actors[1], actors[2])], ctx, t: t) }
        // the names: Claude Code biggest, the rest in their own colours
        let fc = easeOut((local - 0.05) / 0.35)
        if fc > 0 {
            let tf = NSFont(name: "Futura-CondensedExtraBold", size: 140) ?? .systemFont(ofSize: 130, weight: .black)
            text("CLAUDE CODE", ctx, y: 790 - 30 * (1 - fc), size: 140, alpha: fc, font: tf, kern: 8)
        }
        let fr = easeOut((local - 0.35) / 0.35)
        if fr > 0 {
            let row = NSMutableAttributedString(attributedString: attributed("+  ", size: 40, weight: .heavy, color: dimText, alpha: fr))
            for (i, ai) in AI.allCases.dropFirst().enumerated() {
                if i > 0 { row.append(attributed("  ·  ", size: 40, weight: .heavy, color: dimText, alpha: fr)) }
                row.append(attributed(ai.name, size: 40, weight: .heavy, color: ai.ns, alpha: fr))
            }
            row.draw(at: NSPoint(x: (Double(W) - row.size().width) / 2, y: 720 - 20 * (1 - fr)))
        }
        caption("Everyone picks a side. Nobody plays nice.", ctx, local: local, start: 0.7, y: 640, size: 40, color: yellow, weight: .bold)
    },
    // 7 · End card: the Falcon flies through, the title lands.
    Shot(name: "endcard", start: 41.5, end: 45.7) { ctx, local, t in
        space(ctx, t: local)
        // the Falcon streaks across the sky
        let fp = local / 1.1
        if fp > 0 && fp < 1 {
            let fc = PixelCanvas(66, 29)
            drawFalcon(fc, ramp: 0, engines: true, gear: false)
            fc.addOutline(C(0xFFFFFF, 0.92))
            if let img = fc.makeImage() {
                let x = lerp(-500, Double(W) + 100, easeIn(fp) * 0.6 + fp * 0.4)
                ctx.draw(img, in: CGRect(x: x, y: 560 + 200 * fp, width: 66 * 6, height: 29 * 6))
            }
        }
        // the crew on the horizon, one of every AI's colours
        let crew: [(Cast, FightRole, AI)] = [(.villain(.kylo), .cheer, .desktop), (.villain(.vader), .duel, .claude),
                                             (.hero(.luke), .duel, .codex), (.hero(.r2d2), .none, .copilot),
                                             (.hero(.yoda), .cheer, .qwen), (.hero(.leia), .none, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 80, 137, 190, 240, 290][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
            a.lift = groundY - (Double(H) - 242) / S        // feet on the orange horizon
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
        let f = backOut((local - 0.35) / 0.4)
        if local > 0.35 {
            let tf = NSFont(name: "Futura-CondensedExtraBold", size: 190) ?? .systemFont(ofSize: 170, weight: .black)
            ctx.saveGState()
            ctx.translateBy(x: Double(W) / 2, y: 700); ctx.scaleBy(x: f, y: f); ctx.translateBy(x: -Double(W) / 2, y: -700)
            text("CLAWD WARS", ctx, y: 620, size: 190, color: yellow, font: tf, kern: 14)
            ctx.restoreGState()
        }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 540, size: 56)
        caption("Free for macOS", ctx, local: local, start: 0.8, y: 480, size: 34, color: NSColor(white: 0.8, alpha: 1), weight: .bold)
        // the app icon and where to get it, in the floor band
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 640, y: 50, width: 140, height: 140))
            ctx.restoreGState()
            text("github.com/rodclemen/clawd-wars", ctx, x: 810, y: 92, size: 44, weight: .bold, alpha: ff)
        }
    },
]

// MARK: Frame

/// A Star Wars wipe between shots: a soft, feathered edge travels across the frame at a constant speed,
/// uncovering the next shot behind it while both shots keep playing. Centred on each cut.
let wipe = 2.7, feather = 220.0

/// Greyscale mask that is white (keep the outgoing shot) to the right of `edge`, ramping softly across `feather`.
func wipeMask(edge: Double) -> CGImage {
    var row = [UInt8](repeating: 0, count: W)
    for x in 0..<W { row[x] = UInt8(clamp((Double(x) - edge) / feather + 0.5) * 255) }
    let provider = CGDataProvider(data: Data(row) as CFData)!
    return CGImage(width: W, height: 1, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: W,
                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                   provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
}

func renderShot(_ s: Shot, at t: Double, into ctx: CGContext) {
    ctx.saveGState(); s.render(ctx, t - s.start, t); ctx.restoreGState()
}

func frame(_ t: Double) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.interpolationQuality = .none
    if let j = shots.indices.dropFirst().first(where: { !shots[$0].cut && abs(t - shots[$0].start) < wipe / 2 }) {
        // Mid-wipe: the incoming shot underneath, the outgoing one on top, masked to the right of the edge.
        let p = (t - shots[j].start + wipe / 2) / wipe
        let edge = lerp(-feather / 2, Double(W) + feather / 2, p)
        renderShot(shots[j], at: t, into: ctx)
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 0, width: W, height: H), mask: wipeMask(edge: edge))
        ctx.interpolationQuality = .none
        renderShot(shots[j - 1], at: t, into: ctx)
        ctx.restoreGState()
    } else {
        renderShot(shots[shots.lastIndex(where: { t >= $0.start }) ?? 0], at: t, into: ctx)
    }
    // fade in from / out to black
    let black = max(1 - t / 0.2, (t - (duration - 0.3)) / 0.3, 0)
    if black > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: black)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ path: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// MARK: Storyboard sheet

let beats: [(title: String, action: String, onScreen: String, sound: String)] = [
    ("A LONG TIME AGO", "Black screen. The film's famous blue opening line, parodied for terminals, fades in and out.",
     "“A long time ago, in a terminal far, far away....”", "silence"),
    ("THE LOGO", "Hard cut to stars. CLAWD WARS, outlined in yellow, starts bigger than the screen and falls away into the starfield.",
     "CLAWD WARS (outlined logo)", "big hit, then an original chiptune fanfare"),
    ("THE STAR DESTROYER", "The camera tilts down to pixel Tatooine and its two moons. The Tantive IV races in from the top under red laser fire; then the Star Destroyer's nose slides in overhead and the hull keeps coming, filling the frame, until its three engines pass.",
     "no text", "dark pulsing build, a turbolaser per bolt, timpani, the rumble growing as it passes"),
    ("THE HOOK", "Three busy terminals (Claude, Codex, Gemini) on a dusky Mac desktop, slow push-in. One thinking, one waiting on a permission prompt, one long done.",
     "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "low synth hum, keyboard clicks"),
    ("DESKTOP MODE", "Desktop dims; Claude's Vader and Codex's Luke drop onto the bottom edge and duel. Agent Han trades shots with a Codex Stormtrooper. Project names and agent tasks on the labels.",
     "DESKTOP MODE badge  ·  “Now they're a pixel-art Star Wars brawl along the bottom of your screen. They fight while they work.”", "saber ignite + clash, blaster pew"),
    ("AT A GLANCE", "Four sessions pop in, each in its AI's outline: Vader swings his kata, the Emperor's bubble fills with dots, Boba's red ! jumps, Jabba snoozes with zZz.",
     "“All fun and games, and you still see everything.”  ·  WORKING · THINKING… · NEEDS YOU! · NAPPING", "one 8-bit blip per pop"),
    ("SUBAGENTS", "Vader stands guard. R2-D2, Chewie, Leia and Luke march in one after another, each with its task label, and fall into line.",
     "“Every subagent reports for duty.”  ·  “Its job is right there on its label. No more guessing.”", "marching footsteps, R2 beep"),
    ("WINDOW MODE", "The app window slides up: the cantina with its band, Vader duelling Codex's Luke, agents cheering; below, live cards whose timers tick and whose “Now:” line changes. Then Luke stops, jumps with a red ! and his card flips to NEEDS YOU.",
     "WINDOW MODE badge  ·  “Prefer a window? Grab the popcorn.”  ·  “A live card per session…”", "cantina band, notification ping"),
    ("EVERY AI", "Six sessions pop in, one per AI outline (GitHub Copilot CLI gets R2-D2). Claude's Vader stands a head taller and duels Codex's Luke; the rest cheer.",
     "CLAUDE CODE (huge)  ·  + Claude Desktop · OpenAI Codex · Qwen Code · Gemini CLI · GitHub Copilot CLI  ·  “Everyone picks a side. Nobody plays nice.”", "big saber clash"),
    ("END CARD", "Wipe to space. The Millennium Falcon streaks across; the crew lines up on the horizon in all six colours; the title punches in, then the tagline, icon and link.",
     "CLAWD WARS  ·  “Have fun. Keep track.”  ·  Free for macOS  ·  github.com/rodclemen/clawd-wars", "Falcon flyby whoosh, final sting"),
]

func storyboard(_ frames: [NSBitmapImageRep]) -> NSBitmapImageRep {
    let cols = 2, pw = 900.0, ph = pw * 9 / 16, textH = 260.0, gap = 60.0, margin = 70.0, headH = 200.0
    let rows = (frames.count + cols - 1) / cols
    let sw = Int(margin * 2 + pw * Double(cols) + gap * Double(cols - 1))
    let sh = Int(headH + Double(rows) * (ph + textH) + Double(rows - 1) * gap * 0.5 + margin)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: sw, pixelsHigh: sh, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: sw, height: sh))
    func put(_ s: String, _ x: Double, _ y: Double, _ size: CGFloat, _ weight: NSFont.Weight, _ col: NSColor, width: Double = 0) {
        let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: col])
        if width > 0 { a.draw(with: NSRect(x: x, y: y - 200, width: width, height: 200), options: [.usesLineFragmentOrigin]) }   // y = top edge
        else { a.draw(at: NSPoint(x: x, y: y)) }
    }
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 64) ?? .systemFont(ofSize: 60, weight: .black)
    NSAttributedString(string: "CLAWD WARS", attributes: [.font: tf, .foregroundColor: yellow, .kern: 5])
        .draw(at: NSPoint(x: margin, y: Double(sh) - 110))
    put(String(format: "%.0f-second promo · storyboard", duration) + " · 1920×1080 · 30 fps · every sprite drawn by the app's own code",
        margin, Double(sh) - 150, 26, .medium, NSColor(white: 0.75, alpha: 1))
    let dim = NSColor(white: 0.62, alpha: 1), body = NSColor(white: 0.92, alpha: 1)
    for (i, f) in frames.enumerated() {
        let s = shots[i], b = beats[i]
        let x = margin + Double(i % cols) * (pw + gap)
        let top = Double(sh) - headH - Double(i / cols) * (ph + textH + gap * 0.5)
        let r = CGRect(x: x, y: top - ph, width: pw, height: ph)
        ctx.saveGState(); ctx.interpolationQuality = .high
        ctx.draw(f.cgImage!, in: r)
        ctx.restoreGState()
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.25)); ctx.setLineWidth(2); ctx.stroke(r)
        let ty = top - ph - 44
        put("\(i + 1)  \(b.title)", x, ty, 30, .heavy, yellow)
        put(String(format: "%.1f - %.1f s", s.start, s.end), x + pw - 170, ty + 2, 26, .semibold, dim)
        put(b.action, x, ty - 14, 21, .regular, body, width: pw)
        put("ON SCREEN  " + b.onScreen, x, ty - 100, 20, .semibold, NSColor(srgbRed: 0.75, green: 0.85, blue: 1, alpha: 1), width: pw)
        put("SOUND  " + b.sound, x, ty - 180, 20, .semibold, dim, width: pw)
    }
    NSGraphicsContext.current = nil
    return rep
}

// MARK: Soundtrack (all synthesized here: an original chiptune score and retro sound effects)

let sampleRate = 44100.0
func hashNoise(_ i: Int) -> Double { noise(i) }   // the sprites' noise, reachable from inside Mix

/// A mono mix bus the whole soundtrack is written into.
final class Mix {
    var buf: [Float]
    init(seconds: Double) { buf = [Float](repeating: 0, count: Int(seconds * sampleRate) + 1) }

    enum Wave { case square(Double), saw, triangle, sine }

    /// One note or sweep: `freq` slides to `to`, with an attack/release envelope and optional vibrato.
    func tone(_ start: Double, _ dur: Double, _ freq: Double, to: Double? = nil, wave: Wave = .square(0.5), vol: Double,
              attack: Double = 0.005, release: Double = 0.05, decay: Double = 0, vibrato: Double = 0) {
        guard start < Double(buf.count) / sampleRate, dur > 0 else { return }
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var phase = 0.0
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            let tt = Double(i) / sampleRate, p = tt / dur
            var f = to.map { freq * pow($0 / freq, p) } ?? freq
            if vibrato > 0 { f *= 1 + vibrato * sin(tt * 2 * .pi * 5.5) }
            phase += f / sampleRate
            let ph = phase - floor(phase)
            let v: Double
            switch wave {
            case .square(let duty): v = ph < duty ? 1 : -1
            case .saw: v = 2 * ph - 1
            case .triangle: v = ph < 0.5 ? 4 * ph - 1 : 3 - 4 * ph
            case .sine: v = sin(2 * .pi * ph)
            }
            var env = min(1, tt / attack) * min(1, (dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    /// Filtered noise: `cutoff` (0…1, one-pole low-pass amount) slides to `cutoffTo`; `highpass` keeps only the hiss.
    func noise(_ start: Double, _ dur: Double, vol: Double, cutoff: Double = 1, cutoffTo: Double? = nil,
               attack: Double = 0.002, release: Double = 0.05, decay: Double = 0, highpass: Bool = false, seed: Int = 1) {
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var lp = 0.0, rng = UInt64(seed &* 2654435761 &+ 12345)
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let white = Double(Int64(bitPattern: rng >> 11) % 2_000_000) / 1_000_000 - 1
            let tt = Double(i) / sampleRate, p = tt / dur
            let a = cutoffTo.map { cutoff + ($0 - cutoff) * p } ?? cutoff
            lp += (white - lp) * a
            let v = highpass ? white - lp : lp
            var env = min(1, tt / attack) * min(1, max(0, dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    // Sound effects
    func pew(_ t: Double, vol: Double = 0.16) {                       // hand blaster
        tone(t, 0.2, 1900, to: 220, wave: .square(0.5), vol: vol, release: 0.08, decay: 0.09)
        noise(t, 0.05, vol: vol * 0.5, cutoff: 0.6, decay: 0.02)
    }
    func turbolaser(_ t: Double, pitch: Double, vol: Double = 0.1) {
        tone(t, 0.32, 900 * pitch, to: 110 * pitch, wave: .saw, vol: vol, release: 0.1, decay: 0.14)
        noise(t, 0.12, vol: vol * 0.6, cutoff: 0.25, decay: 0.05, seed: Int(t * 100))
    }
    func clash(_ t: Double, vol: Double = 0.2) {                      // sabers meeting
        noise(t, 0.22, vol: vol, cutoff: 0.9, decay: 0.06, highpass: true, seed: Int(t * 77))
        tone(t, 0.18, 1400, to: 500, wave: .square(0.3), vol: vol * 0.35, decay: 0.05)
        tone(t, 0.25, 180, to: 120, wave: .saw, vol: vol * 0.4, decay: 0.1)
    }
    func ignite(_ t: Double, vol: Double = 0.14) {
        tone(t, 0.5, 70, to: 120, wave: .saw, vol: vol, attack: 0.02, release: 0.2)
        noise(t, 0.3, vol: vol * 0.5, cutoff: 0.05, cutoffTo: 0.4, decay: 0.15, seed: 9)
    }
    func hum(_ t: Double, _ dur: Double, vol: Double = 0.035) {        // saber hum while blades are out
        tone(t, dur, 92, wave: .saw, vol: vol, attack: 0.3, release: 0.4, vibrato: 0.01)
        tone(t, dur, 94.5, wave: .saw, vol: vol, attack: 0.3, release: 0.4)
    }
    func boom(_ t: Double, vol: Double = 0.45) {
        tone(t, 1.2, 90, to: 32, wave: .sine, vol: vol, release: 0.4, decay: 0.45)
        noise(t, 0.8, vol: vol * 0.5, cutoff: 0.08, cutoffTo: 0.01, decay: 0.3, seed: Int(t * 13))
    }
    func whoosh(_ center: Double, _ dur: Double, vol: Double = 0.12) {
        noise(center - dur / 2, dur, vol: vol, cutoff: 0.01, cutoffTo: 0.25, attack: dur * 0.5, release: dur * 0.5, seed: Int(center * 31))
    }
    func pop(_ t: Double, step: Int, vol: Double = 0.1) {
        let f = 520 * pow(2, Double(step) * 4 / 12)
        tone(t, 0.09, f, to: f * 1.6, wave: .square(0.25), vol: vol, release: 0.03)
    }
    func ping(_ t: Double, vol: Double = 0.16) {                      // notification
        tone(t, 0.25, 1318.5, wave: .sine, vol: vol, release: 0.2, decay: 0.15)
        tone(t + 0.12, 0.45, 1760, wave: .sine, vol: vol, release: 0.35, decay: 0.2)
    }
    func step(_ t: Double, vol: Double = 0.05) { noise(t, 0.04, vol: vol, cutoff: 0.15, decay: 0.012, seed: Int(t * 997)) }
    func click(_ t: Double, vol: Double = 0.04) { noise(t, 0.02, vol: vol, cutoff: 0.8, decay: 0.006, highpass: true, seed: Int(t * 541)) }
    func r2(_ t: Double, vol: Double = 0.07) {                       // a little droid chirp
        for k in 0..<10 {
            let f = 1100 + hashNoise(Int(t * 10) + k * 3) * 1700
            tone(t + Double(k) * 0.045, 0.05, f, to: f * (hashNoise(k + 4) > 0.5 ? 1.3 : 0.8), wave: .sine, vol: vol, release: 0.01)
        }
    }
    // Drums
    func kick(_ t: Double, vol: Double = 0.3) { tone(t, 0.16, 150, to: 45, wave: .sine, vol: vol, release: 0.05, decay: 0.08) }
    func snare(_ t: Double, vol: Double = 0.12) {
        noise(t, 0.14, vol: vol, cutoff: 0.7, decay: 0.05, seed: Int(t * 61))
        tone(t, 0.08, 220, to: 160, wave: .triangle, vol: vol * 0.5, decay: 0.04)
    }
    func hat(_ t: Double, vol: Double = 0.035) { noise(t, 0.04, vol: vol, cutoff: 0.95, decay: 0.012, highpass: true, seed: Int(t * 173)) }
}

func midi(_ n: Int) -> Double { 440 * pow(2, Double(n - 69) / 12) }

/// Writes 16-bit mono PCM as a WAV file.
func writeWAV(_ samples: [Float], to path: String) {
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + samples.count * 2)); d.append("WAVEfmt ".data(using: .ascii)!)
    u32(16); u16(1); u16(1); u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
    d.append("data".data(using: .ascii)!); u32(UInt32(samples.count * 2))
    var pcm = [Int16](repeating: 0, count: samples.count)
    for i in samples.indices { pcm[i] = Int16(max(-1, min(1, samples[i])) * 32000) }
    pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
    try! d.write(to: URL(fileURLWithPath: path))
}

func shotStart(_ name: String) -> Double { shots.first { $0.name == name }!.start }

/// Every time the duelling blades meet (the same clock the sparks use) between `a` and `b`.
func clashTimes(_ a: Double, _ b: Double) -> [Double] {
    var out: [Double] = [], was = false
    var t = a
    while t < b {
        let c = duelPose(t).clash
        if c && !was { out.append(t) }
        was = c; t += 1 / 120
    }
    return out
}

/// When a blaster with `offset` fires between `a` and `b` (a bolt leaves at each whole period).
func shotTimes(_ a: Double, _ b: Double, offset: Double) -> [Double] {
    var out: [Double] = []
    var k = ceil((a + offset) / blasterPeriod)
    while k * blasterPeriod - offset < b { out.append(k * blasterPeriod - offset); k += 1 }
    return out
}

func soundtrack() -> [Float] {
    let m = Mix(seconds: duration)
    let half = wipe / 2

    // ── Opening ────────────────────────────────────────────────────────────────
    // "A long time ago…": silence, as in the film.
    // The logo: a big hit and an original fanfare.
    let logo = shotStart("logo")
    m.boom(logo, vol: 0.55)
    m.noise(logo, 1.6, vol: 0.12, cutoff: 0.9, decay: 0.5, highpass: true, seed: 3)          // crash cymbal
    for n in [48, 55, 60, 64, 67] { m.tone(logo, 1.1, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.7) }
    let fanfare: [(Double, Double, Int)] = [(0.3, 0.28, 64), (0.6, 0.28, 67), (0.9, 0.85, 72), (1.8, 0.28, 71),
                                            (2.1, 0.28, 69), (2.4, 1.05, 74)]
    for (s, d, n) in fanfare {
        m.tone(logo + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(logo + s, d, midi(n), wave: .saw, vol: 0.05, release: 0.08)
    }
    for (s, d, chord) in [(0.0, 0.9, [48, 52, 55]), (0.9, 0.9, [45, 48, 52]), (1.8, 0.6, [41, 45, 48]), (2.4, 1.1, [43, 47, 50])] {
        for n in chord { m.tone(logo + s, d, midi(n), wave: .triangle, vol: 0.07, attack: 0.03, release: 0.15) }
    }
    m.tone(logo + 2.4, 1.1, midi(31), wave: .sine, vol: 0.2, release: 0.3)

    // The Star Destroyer: a dark pulsing build, turbolasers, and a rumble that grows as it passes overhead.
    let sd = shotStart("destroyer")
    for i in 0..<Int((8.5 + half) / 0.25) {
        let t = sd + Double(i) * 0.25
        let grow = min(1, Double(i) / 30)
        m.tone(t, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.05 + 0.06 * grow, release: 0.04)
    }
    for (s, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55]), (7.0, [43, 47, 50])] {
        for n in chord { m.tone(sd + s, 1.8, midi(n), wave: .saw, vol: 0.04, attack: 0.05, release: 0.6) }
    }
    for k in 0..<12 { m.tone(sd + 2.4 + Double(k) * 0.05, 0.08, 70, to: 55, wave: .sine, vol: 0.06 + Double(k) * 0.012, decay: 0.05) }  // timpani roll
    m.boom(sd + 3.0, vol: 0.4)                                                                            // its nose appears
    m.noise(sd + 2.6, 6.5, vol: 0.32, cutoff: 0.004, cutoffTo: 0.03, attack: 3.0, release: 2.0, seed: 5)  // the rumble
    m.tone(sd + 2.6, 6.5, 41, wave: .sine, vol: 0.18, attack: 3.0, release: 2.0)
    m.tone(sd + 1.4, 5.0, 620, to: 560, wave: .triangle, vol: 0.02, attack: 0.5, release: 1.5)            // the runner's engines
    for i in 0..<40 {                                                                                      // one per bolt on screen
        let t = sd + 1.3 + Double(i) * 0.17
        if t < sd + 8.5 + half { m.turbolaser(t, pitch: noise(i * 7) > 0.5 ? 1 : 0.8, vol: 0.07) }
    }
    m.tone(sd + 6.6, 3.0, midi(24), wave: .sine, vol: 0.12, attack: 0.4, release: 1.5)                   // engines passing

    // ── The promo: an original chiptune groove, Am F C G ────────────────────────
    let g0 = shotStart("hook"), beat = 0.5, bar = 2.0
    let roots = [45, 41, 48, 43]
    let triads = [[69, 72, 76], [65, 69, 72], [67, 72, 76], [67, 71, 74]]
    let melodyA: [[(Int, Double)]] = [[(76, 1), (81, 1), (84, 0.5), (83, 0.5), (81, 1)], [(84, 1), (81, 1), (77, 0.5), (79, 0.5), (81, 1)],
                                      [(79, 1), (76, 0.5), (79, 0.5), (84, 1), (83, 1)], [(86, 1), (83, 1), (79, 2)]]
    let melodyB: [[(Int, Double)]] = [[(81, 0.5), (84, 0.5), (88, 1), (86, 0.5), (84, 0.5), (83, 1)], [(81, 1.5), (84, 0.5), (81, 1), (77, 1)],
                                      [(79, 0.5), (81, 0.5), (79, 0.5), (76, 0.5), (79, 1), (84, 1)], [(83, 1), (86, 1), (91, 2)]]
    let grooveBars = Int(((shotStart("endcard") - g0) / bar).rounded())
    for b in 0..<grooveBars {
        let t0 = g0 + Double(b) * bar, c = b % 4
        let full = b >= 2                                  // the hook is sparse; the band kicks in with desktop mode
        for e in 0..<8 {                                   // bass, eighths, octave bounce
            m.tone(t0 + Double(e) * beat / 2, beat / 2 * 0.9, midi(roots[c] - 12 + (e % 2) * 12), wave: .square(0.25),
                   vol: full ? 0.075 : 0.05, release: 0.02)
            m.hat(t0 + Double(e) * beat / 2, vol: e % 2 == 1 ? 0.04 : 0.025)
        }
        m.kick(t0)
        if full {
            m.kick(t0 + 2 * beat); m.kick(t0 + 2.5 * beat, vol: 0.18)
            m.snare(t0 + beat); m.snare(t0 + 3 * beat)
            for s in 0..<16 {                              // the arpeggio
                m.tone(t0 + Double(s) * beat / 4, beat / 4 * 0.8, midi(triads[c][s % 3] - 12 + (s / 3 % 2) * 12),
                       wave: .triangle, vol: 0.03, release: 0.02)
            }
            let phrase = (b - 2) / 4 % 2 == 0 ? melodyA : melodyB
            var tt = t0
            for (n, d) in phrase[c] {
                m.tone(tt, d * beat * 0.92, midi(n), wave: .square(0.5), vol: 0.055, release: 0.04, vibrato: 0.004)
                tt += d * beat
            }
        }
        if b == grooveBars - 1 {                           // snare roll into the end card
            for k in 0..<8 { m.snare(t0 + 2 * beat + Double(k) * beat / 4, vol: 0.06 + Double(k) * 0.01) }
        }
    }

    // ── End card: a heroic cadence, F G A ────────────────────────────────────────
    let end = shotStart("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(end + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(end + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(end + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(end + 0.35, vol: 0.45)                          // the title lands
    m.noise(end + 1.4, 2.5, vol: 0.08, cutoff: 0.9, decay: 0.8, highpass: true, seed: 8)
    m.whoosh(end + 0.55, 1.1, vol: 0.22)                   // the Falcon flies by
    m.tone(end, 1.1, 300, to: 900, wave: .saw, vol: 0.025, attack: 0.4, release: 0.5)

    // ── Sound effects in the promo ──────────────────────────────────────────────
    for s in shots.dropFirst() where !s.cut { m.whoosh(s.start, wipe, vol: 0.07) }       // every wipe

    let hook = shotStart("hook")                           // somebody typing
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }

    let desk = shotStart("desktop")                        // the drop-ins, the duel and the shootout
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    m.ignite(desk + 0.45)
    m.hum(desk + 0.45, 4.6 - 0.45 + half)
    for t in clashTimes(desk + 0.45, desk + 4.6 + half) { m.clash(t) }
    for t in shotTimes(desk + 0.45, desk + 4.6 + half, offset: 0) { m.pew(t) }
    for t in shotTimes(desk + 0.45, desk + 4.6 + half, offset: blasterPeriod / 2) { m.pew(t, vol: 0.12) }

    let status = shotStart("status")                       // the four pop in; Boba's alert
    for i in 0..<4 { m.pop(status + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(status + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }

    let agents = shotStart("agents")                       // marching in, and R2
    for k in 0..<14 { m.step(agents + Double(k) * 0.125, vol: 0.06) }
    m.r2(agents + 1.4)

    let win = shotStart("window")                          // the cantina duel, the cards, and the ping
    m.hum(win, 2.5, vol: 0.02)
    for t in clashTimes(win, win + 2.5) { m.clash(t, vol: 0.09) }
    for k in [0.9, 1.8] { m.click(win + k, vol: 0.06) }
    m.ping(win + 2.5)

    let ais = shotStart("ais")                             // six pop in, Claude vs Codex
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.ignite(ais + 0.3, vol: 0.12)
    m.hum(ais + 0.35, 4.4 - 0.35 + half)
    for t in clashTimes(ais + 0.35, ais + 4.4 + half) { m.clash(t) }

    for t in clashTimes(end + 0.5, duration) { m.clash(t, vol: 0.12) }                     // the duel on the horizon

    // Master: gentle saturation, normalise, fade out.
    var peak: Float = 0
    for i in m.buf.indices { m.buf[i] = Float(tanh(Double(m.buf[i]) * 1.2)); peak = max(peak, abs(m.buf[i])) }
    let gain = peak > 0 ? 0.89 / peak : 1
    let fadeFrom = Int((duration - 1.2) * sampleRate)
    for i in m.buf.indices {
        m.buf[i] *= gain
        if i > fadeFrom { m.buf[i] *= Float(max(0, 1 - Double(i - fadeFrom) / (1.2 * sampleRate))) }
    }
    return m.buf
}

/// Puts the soundtrack under the silent video: WAV → AAC with afconvert, then a passthrough export.
func mux(video: String, audio: String, to out: String) {
    let m4a = audio.replacingOccurrences(of: ".wav", with: ".m4a")
    try? FileManager.default.removeItem(atPath: m4a)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
    p.arguments = ["-f", "m4af", "-d", "aac", "-b", "192000", audio, m4a]
    try! p.run(); p.waitUntilExit()

    let comp = AVMutableComposition()
    let v = AVURLAsset(url: URL(fileURLWithPath: video)), a = AVURLAsset(url: URL(fileURLWithPath: m4a))
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
    let vt = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
    try! vt.insertTimeRange(range, of: v.tracks(withMediaType: .video)[0], at: .zero)
    let at = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    let aRange = CMTimeRange(start: .zero, duration: min(range.duration, a.duration))
    try! at.insertTimeRange(aRange, of: a.tracks(withMediaType: .audio)[0], at: .zero)
    try? FileManager.default.removeItem(atPath: out)
    let ex = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough)!
    ex.outputURL = URL(fileURLWithPath: out); ex.outputFileType = .mp4
    let done = DispatchSemaphore(value: 0)
    ex.exportAsynchronously { done.signal() }
    done.wait()
    if ex.status != .completed { print("mux failed: \(String(describing: ex.error))"); exit(1) }
    print("wrote \(out)")
}

// MARK: Main

let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "storyboard"
let out = args.count > 2 ? args[2] : "build/promo"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

/// Encodes every frame straight into an H.264 MP4 with AVAssetWriter (no ffmpeg needed).
func writeVideo(to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 16_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: W,
        kCVPixelBufferHeightKey as String: H,
    ])
    writer.add(input)
    writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let n = Int(duration * fps)
    for f in 0..<n {
        autoreleasepool {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
            var pb: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
            let buf = pb!
            CVPixelBufferLockBaseAddress(buf, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H, bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
            ctx.draw(frame(Double(f) / fps).cgImage!, in: CGRect(x: 0, y: 0, width: W, height: H))
            CVPixelBufferUnlockBaseAddress(buf, [])
            adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
        }
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { print("video failed: \(String(describing: writer.error))"); exit(1) }
    print("wrote \(path)")
}

if cmd == "video" {
    let tmp = NSTemporaryDirectory()
    writeVideo(to: tmp + "clawd-wars-silent.mp4")
    writeWAV(soundtrack(), to: tmp + "clawd-wars.wav")
    mux(video: tmp + "clawd-wars-silent.mp4", audio: tmp + "clawd-wars.wav", to: "\(out)/clawd-wars-promo.mp4")
} else if cmd == "audio" {
    writeWAV(soundtrack(), to: "\(out)/clawd-wars-promo.wav"); print("wrote \(out)/clawd-wars-promo.wav")
} else if cmd == "frames" {
    let n = Int(duration * fps)
    for f in 0..<n { autoreleasepool { save(frame(Double(f) / fps), "\(out)/frame-\(String(format: "%03d", f)).png") } }
    print("wrote \(n) frames to \(out)")
} else if cmd == "frame" {
    let t = Double(args[3]) ?? 0
    save(frame(t), "\(out)/t\(args[3]).png"); print("wrote \(out)/t\(args[3]).png")
} else {
    let keys: [Double] = [1.8, 4.4, 11.2, 17.0, 21.8, 26.4, 30.5, 35.1, 39.5, 44.5]
    let frames = keys.map(frame)
    for (i, f) in frames.enumerated() { save(f, "\(out)/key-\(i + 1).png") }
    save(storyboard(frames), "\(out)/storyboard.png")
    print("wrote \(keys.count) key frames and storyboard.png to \(out)")
}
