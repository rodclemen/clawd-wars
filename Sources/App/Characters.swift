import Foundation

// All sprites are variations of Clawd (Claude Code's pixel mascot): a blocky orange body,
// two eyes, arm nubs and four legs. Every character shares this 72x52 canvas layout, facing right:
//   body x 18...37, y 26...37 · legs y 38...43 · right hand pivot (41.5, 34.5)
// Characters facing left are drawn mirrored by the view.

enum Sprite {
    static let width = 72
    static let height = 52
    static let bodyCenterX = 28.0
    static let hand = (x: 41.5, y: 34.5)
}

enum Companion: Int, CaseIterable {
    case luke, han, leia, obiwan, r2d2, c3po, quigon, mace, yoda, jawa, chewie, rey, ahsoka, ewok, tauntaun
    case jarjar, lando, zorii, boKatan, maz, wedge, l337, monMothma, padme, ackbar, grogu, babuFrik, mando, k2so, gonk
    case cassian, bix, cobbVanth, pitDroid, kuiil

    var name: String {
        switch self {
        case .luke: return "Luke Skywalker"
        case .han: return "Han Solo"
        case .leia: return "Princess Leia"
        case .obiwan: return "Obi-Wan Kenobi"
        case .r2d2: return "R2-D2"
        case .c3po: return "C-3PO"
        case .quigon: return "Qui-Gon Jinn"
        case .mace: return "Mace Windu"
        case .yoda: return "Yoda"
        case .jawa: return "Jawa"
        case .chewie: return "Chewbacca"
        case .rey: return "Rey"
        case .ahsoka: return "Ahsoka Tano"
        case .ewok: return "Wicket the Ewok"
        case .tauntaun: return "Tauntaun"
        case .jarjar: return "Jar Jar Binks"
        case .lando: return "Lando Calrissian"
        case .zorii: return "Zorii Bliss"
        case .boKatan: return "Bo-Katan Kryze"
        case .maz: return "Maz Kanata"
        case .wedge: return "Wedge Antilles"
        case .l337: return "L3-37"
        case .monMothma: return "Mon Mothma"
        case .padme: return "Padmé Amidala"
        case .ackbar: return "Admiral Ackbar"
        case .grogu: return "Grogu"
        case .babuFrik: return "Babu Frik"
        case .mando: return "The Mandalorian"
        case .k2so: return "K-2SO"
        case .gonk: return "GNK Power Droid"
        case .cassian: return "Cassian Andor"
        case .bix: return "Bix Caleen"
        case .cobbVanth: return "Cobb Vanth"
        case .pitDroid: return "Pit Droid"
        case .kuiil: return "Kuiil"
        }
    }

    /// Top row of the head/hair/dome on the 72x52 canvas, for placing the task label.
    var headTop: Int {
        switch self {
        case .luke: return 21
        case .han, .c3po: return 22
        case .leia: return 23
        case .obiwan, .jawa, .rey: return 19
        case .r2d2: return 17
        case .quigon, .chewie: return 21
        case .mace: return 26
        case .yoda: return 24
        case .ahsoka: return 16
        case .ewok: return 22
        case .tauntaun: return 14
        case .jarjar: return 18
        case .lando, .maz, .monMothma, .padme: return 22
        case .babuFrik: return 16
        case .zorii, .boKatan, .wedge, .mando: return 19
        case .l337, .ackbar: return 17
        case .grogu: return 23
        case .k2so: return 14
        case .gonk: return 23
        case .cassian: return 22
        case .bix: return 19
        case .cobbVanth: return 22
        case .pitDroid: return 16
        case .kuiil: return 7
        }
    }

    /// Whether it sits down when its session has been idle a while (not the droid on wheels-and-legs, the tauntaun,
    /// or anyone whose gown or robe already reaches the floor).
    var canSit: Bool {
        switch self {
        case .r2d2, .tauntaun, .leia, .jawa, .monMothma, .grogu, .babuFrik, .gonk, .pitDroid, .kuiil: return false
        case .luke, .han, .obiwan, .c3po, .quigon, .mace, .yoda, .chewie, .rey, .ahsoka, .ewok,
             .jarjar, .lando, .zorii, .boKatan, .maz, .wedge, .l337, .padme, .ackbar, .mando, .k2so, .cassian, .bix, .cobbVanth: return true
        }
    }
}

// MARK: - Palette

let clawdOrange = C(0xD97757)
let clawdShade = C(0xB85F40)
let ink = C(0x16161B)
let outline = C(0x2A2A33)
let white = C(0xFFFFFF)

/// Deterministic noise in 0..<1 (sparks and lightning change every frame without true randomness).
func noise(_ i: Int) -> Double {
    let v = sin(Double(i) * 12.9898 + 78.233) * 43758.5453
    return v - floor(v)
}

// MARK: - Lightsaber choreography

struct Key { let a, dx, dy, dur: Double; let fast: Bool; var clash = false }

private func play(_ keys: [Key], start: Double, _ t: Double) -> (angle: Double, dx: Double, dy: Double, clash: Bool) {
    let length = keys.reduce(0) { $0 + $1.dur }
    var tt = t.truncatingRemainder(dividingBy: length)
    if tt < 0 { tt += length }
    var prev = (a: start, dx: 0.0, dy: 0.0)
    for k in keys {
        if tt < k.dur {
            let f = tt / k.dur
            let e = k.fast ? 1 - pow(1 - f, 3) : f * f * (3 - 2 * f)
            return (prev.a + (k.a - prev.a) * e, prev.dx + (k.dx - prev.dx) * e, prev.dy + (k.dy - prev.dy) * e,
                    k.clash && (!k.fast || f > 0.8))
        }
        tt -= k.dur
        prev = (k.a, k.dx, k.dy)
    }
    return (start, 0, 0, false)
}

/// Solo practice kata. Angles in degrees, 0 = forward, -90 = straight up (y grows down).
/// The final key is the opening guard (-60) plus one full turn, so the loop is seamless.
private let kata: [Key] = [
    Key(a: -120, dx: -1, dy: 0, dur: 0.40, fast: false),   // wind up overhead
    Key(a: 40, dx: 1, dy: -2, dur: 0.13, fast: true),      // downward slash with a hop
    Key(a: 30, dx: 1, dy: 0, dur: 0.25, fast: false),      // follow through
    Key(a: -150, dx: -1, dy: -1, dur: 0.30, fast: true),   // rising backhand
    Key(a: -160, dx: -1, dy: 0, dur: 0.20, fast: false),   // high block
    Key(a: 0, dx: 2, dy: 0, dur: 0.14, fast: true),        // horizontal cut
    Key(a: 5, dx: 2, dy: 0, dur: 0.25, fast: false),       // thrust
    Key(a: 300, dx: 0, dy: -1, dur: 0.55, fast: false),    // full twirl
    Key(a: 300, dx: 0, dy: 0, dur: 0.35, fast: false),     // back to guard
]

/// Duel exchange. Both fighters run it in sync, mirrored, so their blades meet on the midline.
private let duel: [Key] = [
    Key(a: -125, dx: -1, dy: 0, dur: 0.35, fast: false),
    Key(a: -30, dx: 2, dy: 0, dur: 0.12, fast: true, clash: true),    // high strike
    Key(a: -32, dx: 2, dy: 0, dur: 0.30, fast: false, clash: true),   // bind
    Key(a: -140, dx: -1, dy: -1, dur: 0.35, fast: false),
    Key(a: 12, dx: 2, dy: 0, dur: 0.12, fast: true, clash: true),     // low strike
    Key(a: 14, dx: 2, dy: 0, dur: 0.28, fast: false, clash: true),    // bind
    Key(a: -95, dx: 0, dy: -2, dur: 0.25, fast: false),
    Key(a: -20, dx: 3, dy: 0, dur: 0.10, fast: true, clash: true),    // lunge
    Key(a: -20, dx: 3, dy: 0, dur: 0.22, fast: false, clash: true),
    Key(a: -70, dx: 0, dy: 0, dur: 0.35, fast: false),
]

func kataPose(_ t: Double) -> (angle: Double, dx: Double, dy: Double) {
    let p = play(kata, start: -60, t)
    return (p.angle, p.dx, p.dy)
}

func duelPose(_ t: Double) -> (angle: Double, dx: Double, dy: Double, clash: Bool) {
    play(duel, start: -70, t)
}

func saberTrail(_ t: Double, speed: Double = 1, pose: @escaping (Double) -> Double = { kataPose($0).angle }) -> [Double] {
    let now = pose(t * speed)
    let prev = pose((t - 0.035) * speed)
    guard abs(now - prev) > 6 else { return [] }   // only trail fast swings
    return [prev, pose((t - 0.07) * speed)]
}

// MARK: - Shared drawing helpers

struct Look {
    var body = clawdOrange
    var shade = clawdShade
    var leg = clawdOrange
    var arm = clawdOrange
    var eye: Px? = ink
    var legs = true
}

/// Legs are drawn without the body's breathing offset so a 1px bob never leaves a gap.
/// `step` alternates which pair of legs is lifted while walking (-1 = standing).
/// Set while drawing a seated character: legs fold forward onto the ground (the body is drawn 4 px lower).
var seatedPose = false

func drawLegs(_ c: PixelCanvas, _ look: Look, step: Int = -1) {
    guard look.legs else { return }
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, look.leg) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = step >= 0 && i % 2 == step
        c.rect(lx, 36, 2, lifted ? 7 : 8, look.leg)
    }
}

func drawBody(_ c: PixelCanvas, _ look: Look, armLeft: Int = 0, armRight: Int = 0) {
    c.rect(18, 26, 20, 12, look.body)
    c.rect(18, 37, 20, 1, look.shade)
    c.rect(37, 26, 1, 12, look.shade)
    c.rect(15, 33 - armLeft, 3, 3, look.arm)
    c.rect(38, 33 - armRight, 3, 3, look.arm)
    if let eye = look.eye {
        c.rect(22, 29, 2, 3, eye)
        c.rect(32, 29, 2, 3, eye)
    }
}

func drawSaber(_ c: PixelCanvas, t: Double, angle: Double, core: Px, glow: Px, lit: Bool,
               trail: [Double] = [], length: Double = 20, crossguard: Bool = false, unstable: Bool = false) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    if lit {
        for (i, a) in trail.enumerated() {
            let r = a * .pi / 180
            c.glowLine(hx + cos(r) * 3, hy + sin(r) * 3, hx + cos(r) * (3 + length), hy + sin(r) * (3 + length),
                       core: glow, glow: glow, coreR: 0.5, glowR: 1.8, strength: 0.32 / Double(i + 1))
        }
    }
    let r = angle * .pi / 180
    let ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 2, hy - uy * 2, hx + ux * 2.5, hy + uy * 2.5,
               core: C(0xB9BEC8), glow: C(0x000000, 0), coreR: 0.85, glowR: 0.9)
    c.px(Int(hx - ux * 0.5), Int(hy - uy * 0.5), C(0x2A2A2F))
    guard lit else { return }
    let flicker = unstable ? 0.75 + 0.25 * noise(Int(t * 30)) : 0.92 + 0.08 * sin(t * 40)
    c.glowLine(hx + ux * 3, hy + uy * 3, hx + ux * (3 + length), hy + uy * (3 + length),
               core: core, glow: glow, glowR: unstable ? 2.4 + noise(Int(t * 25)) : 2.4, strength: flicker)
    if crossguard {
        // Kylo Ren's quillons vent sideways from the emitter.
        let bx = hx + ux * 3.5, by = hy + uy * 3.5
        for side in [-1.0, 1.0] {
            c.glowLine(bx, by, bx - uy * 3.5 * side, by + ux * 3.5 * side,
                       core: core, glow: glow, coreR: 0.5, glowR: 1.6, strength: flicker)
        }
    }
}

/// Muzzle flash + (optionally) a bolt flying to the canvas edge. Returns recoil (0 or 1).
@discardableResult
func fireBlaster(_ c: PixelCanvas, t: Double, period: Double, muzzleX: Int, muzzleY: Int, bolt: Bool = true) -> Int {
    var f = (t / period).truncatingRemainder(dividingBy: 1)
    if f < 0 { f += 1 }
    if f < 0.08 {
        c.rect(muzzleX, muzzleY - 1, 2, 3, C(0xFFE27A))
        c.px(muzzleX + 2, muzzleY, C(0xFFF6C8))
    }
    if bolt && f < 0.4 {
        let x = Double(muzzleX + 2) + f / 0.4 * Double(Sprite.width - muzzleX)
        c.glowLine(x, Double(muzzleY) + 0.5, x + 5, Double(muzzleY) + 0.5,
                   core: C(0xFFE0E0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 1.8)
    }
    return f < 0.15 ? 1 : 0
}

// MARK: - Blasters (facing right, grip at the hand)

/// Han's BlasTech DL-44: black heavy pistol, scope on top, conical flash hider, wooden grip.
func drawDL44(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "....SSSSL....",
        ".....K..K....",
        "GKKKKKKKKKKFF",
        "GGKKKkKkKKKFF",
        "GG...........",
        ".GG..........",
    ], ["S": C(0x2C2C33), "L": C(0x7FC8FF), "K": C(0x26262C), "k": C(0x55555F),
        "F": C(0x3E3E46), "G": C(0x4A3426)])
}

/// Leia's Defender sporting blaster: small, chrome slide over a black frame.
func drawDefender(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "SSSSSs",
        "KKKKKK",
        "KK....",
        "KK....",
    ], ["S": C(0xD7DCE4), "s": C(0x9BA3AF), "K": C(0x2A2A30)])
}

/// Stormtrooper E-11: black carbine with scope, cooling holes and a side magazine.
func drawE11(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "......SSSL.....",
        ".......K.K.....",
        "KK.KKKKKKKKKKKK",
        "KKKKKKkKkKkKKK.",
        "....KK..MM.....",
        "....KK..MM.....",
    ], ["S": C(0x2C2C33), "L": C(0x7FC8FF), "K": C(0x1E1E24), "k": C(0x5A5A64), "M": C(0x3A3A42)])
}

/// Boba Fett's EE-3 carbine: short dark rifle with brass fittings and a scope.
func drawEE3(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        ".....SSSSL....",
        "......B..B....",
        "BKKKKKKKKKKKKK",
        "KKKKBBKKKKKK..",
        "...KK.........",
        "...KK.........",
    ], ["S": C(0x2C2C33), "L": C(0xFF6A3A), "K": C(0x2A2A2E), "B": C(0xB08D57)])
}

// MARK: - Companions

/// `mode`, `urgent` and `sitting` are for a hero leading a session, as in `drawLeader`: it rests (saber off, blaster
/// lowered) unless it's working or fighting, holds its weapon up while Claude waits for you (waving it and hopping
/// once that's urgent), and sits down when it's been idle a while. Agents keep the default `.working`.
func drawCompanion(_ c: PixelCanvas, _ who: Companion, t: Double, walking: Bool, role: FightRole = .none,
                   mode: VaderMode = .working, urgent: Bool = false, sitting: Bool = false) {
    var role = role
    if case .none = role, mode != .working { role = mode == .waiting ? .ready(urgent: urgent) : .rest }
    // Idle habits: a saber hero runs through a few moves, a gunner raises its weapon to check it.
    if mode == .idle, case .rest = role, let h = idleHabit {
        if h.kind == .flourish, h.p > 0.1, h.p < 0.9 { role = .none }
        if h.kind == .checkWeapon, h.p < 0.75 { role = .ready(urgent: false) }
    }
    var resting = false
    if case .rest = role { resting = true }
    let seated = sitting && who.canSit && !walking && resting && (mode == .idle || mode == .standGuard)
    seatedPose = seated
    c.baseY = seated ? 4 : (urgent && mode == .waiting && !walking ? cheerHop(t * 1.5) : 0)
    defer { seatedPose = false; c.baseY = 0 }
    if case .cheer = role, !walking { drawCheerSparkles(c, t: t) }
    switch who {
    case .luke: drawLuke(c, t: t, walking: walking, role: role)
    case .han: drawHan(c, t: t, walking: walking, role: role)
    case .leia: drawLeia(c, t: t, walking: walking, role: role)
    case .obiwan: drawObiWan(c, t: t, walking: walking, role: role)
    case .r2d2: drawR2(c, t: t, walking: walking)
    case .c3po: drawC3PO(c, t: t, walking: walking)
    case .quigon, .mace, .yoda, .rey, .ahsoka: drawJedi(c, who, t: t, walking: walking, role: role)
    case .ewok: drawEwok(c, t: t, walking: walking, role: role)
    case .tauntaun: drawTauntaun(c, t: t, walking: walking)
    case .jawa, .chewie: drawGunner(c, who, t: t, walking: walking, role: role)
    case .jarjar: drawJarJar(c, t: t, walking: walking, role: role)
    case .lando: drawLando(c, t: t, walking: walking, role: role)
    case .zorii: drawZorii(c, t: t, walking: walking, role: role)
    case .boKatan: drawBoKatan(c, t: t, walking: walking, role: role)
    case .maz: drawMaz(c, t: t, walking: walking, role: role)
    case .wedge: drawWedge(c, t: t, walking: walking, role: role)
    case .l337: drawL337(c, t: t, walking: walking, role: role)
    case .monMothma: drawMonMothma(c, t: t, walking: walking, role: role)
    case .padme: drawPadme(c, t: t, walking: walking, role: role)
    case .ackbar: drawAckbar(c, t: t, walking: walking, role: role)
    case .grogu: drawGrogu(c, t: t, walking: walking, role: role)
    case .babuFrik: drawBabuFrik(c, t: t, walking: walking, role: role)
    case .mando: drawMando(c, t: t, walking: walking, role: role)
    case .k2so: drawK2SO(c, t: t, walking: walking, role: role)
    case .gonk: drawGonk(c, t: t, walking: walking, role: role)
    case .cassian: drawCassian(c, t: t, walking: walking, role: role)
    case .bix: drawBix(c, t: t, walking: walking, role: role)
    case .cobbVanth: drawCobbVanth(c, t: t, walking: walking, role: role)
    case .pitDroid: drawPitDroid(c, t: t, walking: walking, role: role)
    case .kuiil: drawKuiil(c, t: t, walking: walking, role: role)
    }
}

/// The Millennium Falcon, nose to the right: the disc, the forward mandibles, the offset cockpit, the radar
/// dish. `ramp` 0…1 lowers the boarding ramp (down and to the left), `engines` lights the blue glow.
func drawFalcon(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    // Seen slightly from above, so the round saucer, the central hatch and the split front read clearly.
    let hull = C(0xB8B6AC), hullLight = C(0xD2D0C6), hullDark = C(0x8A8880), panel = C(0x6E6C66)
    if gear {
        for gx in [18, 44] { c.rect(gx, 24, 1, 3, hullDark); c.rect(gx - 1, 27, 3, 1, panel) }
    }
    if ramp > 0 {                                                       // boarding ramp, toward the left
        let len = Int((ramp * 9).rounded())
        for k in 0..<len { c.rect(31 - k, 24 + k / 3, 2, 1, hullDark) }
    }
    c.ellipse(32, 18, 28, 7, hullDark)                                  // rim / underside
    c.ellipse(32, 16, 28, 8, hull)                                      // the saucer, seen from above
    c.ellipse(30, 15, 22, 6, hullLight)
    c.circle(30, 15, 4, hull); c.circle(30, 15, 2, panel)               // central hatch
    for (x, y) in [(12, 15), (18, 11), (40, 11), (46, 16), (20, 20), (40, 20), (24, 14), (36, 18)] { c.rect(x, y, 3, 1, panel) }
    // the split front: two mandibles with the cargo gap between them
    c.rect(55, 11, 10, 3, hull); c.rect(55, 18, 10, 3, hull)
    c.rect(55, 14, 7, 4, C(0x2A2A28))
    c.rect(63, 11, 2, 3, hullLight); c.rect(63, 18, 2, 3, hullLight)
    // cockpit off to the side, and the radar dish
    c.rect(46, 6, 10, 3, hull); c.circle(56, 7, 2, hull); c.rect(56, 6, 2, 2, C(0x3A5A7A))
    c.rect(22, 6, 1, 4, panel); c.ellipse(21, 5, 4, 1, hullLight)
    if engines {                                                        // the blue engine glow along the back
        c.rect(3, 12, 2, 9, C(0x6FB8FF)); c.rect(2, 14, 1, 5, C(0xBFE0FF))
    }
}

/// Little blinking stars above the head of whoever is cheering.
func drawCheerSparkles(_ c: PixelCanvas, t: Double) {
    for i in 0..<3 {
        let f = (t * 1.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
        let x = 20 + i * 8 + Int(sin(f * 7 + Double(i)) * 2), y = 16 - Int(f * 12)
        let col = (i % 2 == 0 ? C(0xFFD25A) : C(0xFF7AC8)).alpha(1 - f)
        c.px(x, y, col); c.px(x - 1, y, col.alpha(0.5)); c.px(x + 1, y, col.alpha(0.5))
        c.px(x, y - 1, col.alpha(0.5)); c.px(x, y + 1, col.alpha(0.5))
    }
}

/// Hop height while cheering: bounces twice a second.
func cheerHop(_ t: Double) -> Int { sin(t * 2 * .pi * 2) > 0 ? -2 : 0 }

/// Saber pose for an agent: its own kata, or whatever a fight calls for.
func saberPose(_ t: Double, walking: Bool, role: FightRole, speed: Double, offset: Double)
    -> (angle: Double, dx: Double, dy: Double, trail: [Double]) {
    if walking { return (-60, 0, 0, []) }
    switch role {
    case .duel:
        let p = duelPose(t)
        return (p.angle, p.dx, p.dy, saberTrail(t, pose: { duelPose($0).angle }))
    case .deflect:
        return (deflectAngle(t), 0, 0, saberTrail(t, pose: deflectAngle))
    case .block:
        return (-60 + 2 * sin(t * 37), -1, 0, [])
    case .hit:
        return (-60, noise(Int(t * 30)) > 0.5 ? 1 : -1, 0, [])
    case .cheer:
        return (-95 + 18 * sin(t * 9), 0, Double(cheerHop(t)), [])
    case .rest:
        return (75, 0, 0, [])                // saber lowered and switched off
    case .ready(let urgent):
        return (urgent ? -90 + 25 * sin(t * 12) : -90 + 2 * sin(t * 3), 0, 0, [])   // held up; waved when urgent
    default:
        let p = kataPose(t * speed + offset)
        return (p.angle, p.dx, p.dy, saberTrail(t + offset / speed, speed: speed))
    }
}

/// Lightsabers are switched off while a hero rests.
func saberLit(_ role: FightRole) -> Bool { if case .rest = role { return false } else { return true } }

func walkStep(_ t: Double, _ walking: Bool) -> Int { walking ? Int(t * 8) % 2 : -1 }

private func drawLuke(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let p = saberPose(t, walking: walking, role: role, speed: 0.92, offset: 0)
    let step = walkStep(t, walking)
    c.ox = Int(p.dx.rounded()); c.oy = Int(p.dy.rounded())
    let look = Look(leg: C(0xB89E72))
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    c.pattern(17, 21, [
        ".....YYYYYYYYYYYY.....",
        "...YYYYYYYYYYYYYYYY...",
        "..YYYYyYYYYYYYYyYYYY..",
        ".YYYyYYYYYyYYYYYyYYYY.",
        ".YYYYYY.YYYYYY.YYYYYY.",
        ".YY..Y....YY....Y..YY.",
    ], ["Y": C(0xE2C07A), "y": C(0xB8914A)])
    c.rect(18, 33, 19, 5, C(0xEFE9DA))
    c.rect(26, 33, 4, 1, clawdOrange)
    c.rect(18, 36, 19, 1, C(0x6B4A2B))
    drawSaber(c, t: t, angle: p.angle, core: C(0xEAFFEA), glow: C(0x3FE85A), lit: saberLit(role), trail: p.trail)
}

private func drawObiWan(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let p = saberPose(t, walking: walking, role: role, speed: 0.85, offset: 1.3)
    let step = walkStep(t, walking)
    c.ox = Int(p.dx.rounded()); c.oy = Int(p.dy.rounded())
    let robe = C(0x7A5532)
    let look = Look(leg: C(0x8A6A44), arm: robe)
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    drawHood(c, robe, C(0x5E3F22))
    c.rect(18, 33, 4, 5, C(0xE4D3B0))
    c.rect(34, 33, 4, 5, C(0xE4D3B0))
    c.pattern(22, 32, [
        ".FFFF..FFFF.",
        "FFFFFFFFFFFF",
        "FFfFFFFFFfFF",
        ".FFFFfFFFFF.",
        "...FFFFFF...",
    ], ["F": C(0xC9A27A), "f": C(0xA9825A)])
    c.rect(18, 37, 20, 1, C(0x5A3A22))
    drawSaber(c, t: t, angle: p.angle, core: C(0xE6F4FF), glow: C(0x3D9BFF), lit: saberLit(role), trail: p.trail)
}

func drawHood(_ c: PixelCanvas, _ main: Px, _ dark: Px) {
    c.pattern(15, 19, [
        ".......BBBBBBBBBBBB.......",
        ".....BBBBBBBBBBBBBBBB.....",
        "....BBBBbBBBBBBBBBbBBB....",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "..BBBBBBBBBBBBBBBBBBBBBB..",
        "..BBBb..............bBBB..",
        ".BBBB................BBBB.",
        ".BBB..................BBB.",
        ".BBB..................BBB.",
        "BBBB..................BBBB",
        "BBB....................BBB",
        "BBB....................BBB",
    ], ["B": main, "b": dark])
}

/// Blaster agents: own target practice, firing at / getting zapped by an opponent, or cheering.
/// Returns how far to lift the gun (recoil or cheer) and a sideways shake.
func agentFire(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole,
                       period: Double, phase: Double, muzzleX: Int, muzzleY: Int = 32) -> (recoil: Int, shake: Int) {
    if walking { return (0, 0) }
    switch role {
    case .shoot(let offset):
        return (fireBlaster(c, t: t + offset, period: blasterPeriod, muzzleX: muzzleX, muzzleY: muzzleY, bolt: false), 0)
    case .hit:
        return (0, noise(Int(t * 30)) > 0.5 ? 1 : -1)
    case .cheer:
        return (-cheerHop(t) + 1, 0)
    case .rest, .ready:
        return (0, 0)                        // blaster lowered, not firing
    default:
        return (fireBlaster(c, t: t + phase, period: period, muzzleX: muzzleX, muzzleY: muzzleY), 0)
    }
}

private func drawHan(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let step = walkStep(t, walking)
    let bob = walking ? (step == 0 ? -1 : 0) : (sin(t * 5) > 0.6 ? -1 : 0)
    let look = Look(leg: C(0x2B3550))
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHHHHHHH...",
        ".HHHHhHHHHHHHHHHHHHH..",
        ".HHHHHHHHhhHHHHHHHHH..",
        ".HH.HHHHHHH..HHHH.HH..",
    ], ["H": C(0x5A3A1E), "h": C(0x3E2812)])
    c.rect(18, 32, 20, 6, C(0xEDEAE2))
    c.rect(18, 32, 5, 6, C(0x1F1F26))
    c.rect(33, 32, 5, 6, C(0x1F1F26))
    c.rect(18, 37, 20, 1, C(0x5A3A22))
    c.rect(26, 37, 3, 1, C(0xC9A44A))
    c.rect(19, 38, 3, 3, C(0x4A3020))
    let (recoil, shake) = agentFire(c, t: t, walking: walking, role: role, period: 0.95, phase: 0, muzzleX: 53)
    c.oy = bob - recoil
    c.ox = shake
    drawDL44(c, x: 40, y: 30)
}

private func drawLeia(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let bob = walking ? (Int(t * 8) % 2 == 0 ? -1 : 0) : (sin(t * 4 + 1) > 0.6 ? -1 : 0)
    c.oy = bob
    let gown = C(0xF4F4F0), gownShade = C(0xD9DADF)
    var look = Look(arm: gown)
    look.legs = false
    for y in 38...43 {
        let k = (y - 38) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, gown)
        c.px(18 - k, y, gownShade); c.px(37 + k, y, gownShade)
    }
    drawBody(c, look)
    let B = C(0x4A2E18), b = C(0x3A2212)
    let bun = [".BBB.", "BBbBB", "BbBbB", "BBbBB", ".BBB."]
    c.pattern(12, 27, bun, ["B": B, "b": b])
    c.pattern(39, 27, bun, ["B": B, "b": b])
    c.pattern(18, 23, [
        "...BBBBBBBBBBBBBB...",
        "..BBBBBBBbbBBBBBBB..",
        ".BBBBBBB....BBBBBBB.",
    ], ["B": B, "b": b])
    c.rect(18, 33, 20, 5, gown)
    c.rect(37, 33, 1, 5, gownShade)
    c.rect(18, 35, 20, 1, C(0xB8BEC9))
    let (recoil, shake) = agentFire(c, t: t, walking: walking, role: role, period: 1.15, phase: 0.4, muzzleX: 46)
    c.oy = bob - recoil
    c.ox = shake
    drawDefender(c, x: 40, y: 32)
}

private func drawR2(_ c: PixelCanvas, t: Double, walking: Bool) {
    c.ox = sin(t * 2 * .pi * (walking ? 3 : 1.6)) > 0 ? 1 : -1
    let blue = C(0x2E62D6), grey = C(0x9AA3B2)
    let look = Look(body: C(0xEEF1F5), shade: C(0xC9D0DA), leg: C(0xA7B0BF), arm: blue, eye: nil)
    drawLegs(c, look)
    drawBody(c, look)
    let light = Int(t * 2.5) % 2 == 0 ? C(0xFF3B3B) : C(0x4FA8FF)
    c.pattern(18, 17, [
        "......SSSSSSSS......",
        "....SSSSSSSSSSSS....",
        "...SSSSSSSSSSSSSS...",
        "..SSBBSSSEEESSBBSS..",
        ".SSSBBSSSEEESSBBSSS.",
        ".SSSSSSSSSSSSSSSSSS.",
        "SSBBBSSSRSSSSSBBBSSs",
        "ssssssssssssssssssss",
        "ssssssssssssssssssss",
    ], ["S": C(0xC3CAD6), "s": grey, "B": blue, "E": C(0x111118), "R": light])
    c.rect(20, 28, 3, 6, blue)
    c.rect(33, 28, 3, 6, blue)
    c.rect(24, 29, 8, 2, grey)
    c.rect(24, 32, 8, 1, blue)
    c.rect(26, 34, 4, 3, grey)

    // Beep-boop: music notes drifting up
    c.ox = 0
    for i in 0..<2 {
        let f = (t / 1.4 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
        c.pattern(42 + i * 6 + Int(sin(f * 6) * 2), 18 - Int(f * 16),
                  ["..NN", "..N.", "..N.", "NNN.", "NN.."], ["N": blue.alpha(1 - f)])
    }
}

private func drawC3PO(_ c: PixelCanvas, t: Double, walking: Bool) {
    let flail = Int(t * 6) % 2
    let step = walkStep(t, walking)
    c.ox = walking ? 0 : (Int(t * 1.5) % 2 == 0 ? 0 : 1)
    let gold = C(0xE2B33C), goldShade = C(0xB8862A)
    let look = Look(body: gold, shade: goldShade, leg: C(0xD4A436), arm: gold, eye: nil)
    drawLegs(c, look, step: step)
    drawBody(c, look, armLeft: flail == 0 ? 4 : 0, armRight: flail == 0 ? 0 : 4)
    c.pattern(20, 22, [
        "....GGGGGGGG....",
        "..GGGGGGGGGGGG..",
        ".GGGgGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGG",
    ], ["G": gold, "g": C(0xFFE08A)])
    let eye = C(0xFFF3A6), eyeRim = C(0x8A6420)
    for ex in [21, 31] {
        c.rect(ex, 28, 4, 4, eyeRim)
        c.rect(ex + 1, 29, 2, 2, eye)
    }
    c.rect(26, 33, 4, 1, eyeRim)
    c.rect(23, 35, 10, 2, goldShade)
    c.px(25, 35, C(0xE0303A)); c.px(28, 36, C(0x3A7BEA)); c.px(31, 35, C(0x3BD15A))
    c.rect(19, 27, 2, 1, C(0xFFE08A))
}

// MARK: - More heroes

/// Saber-wielding agents: Qui-Gon, Mace Windu, Yoda, Rey and Ahsoka (twin blades).
private func drawJedi(_ c: PixelCanvas, _ who: Companion, t: Double, walking: Bool, role: FightRole) {
    // Each Jedi's kata offset and blade colours (core, glow).
    let offset: Double, core: Px, glow: Px
    switch who {
    case .quigon: (offset, core, glow) = (0.6, C(0xEAFFEA), C(0x3FE85A))
    case .mace: (offset, core, glow) = (2.1, C(0xF6E6FF), C(0xB04CFF))
    case .yoda: (offset, core, glow) = (0.3, C(0xEAFFEA), C(0x3FE85A))
    case .rey: (offset, core, glow) = (1.7, C(0xE6F4FF), C(0x3D9BFF))
    case .ahsoka: (offset, core, glow) = (2.6, C(0xFFFFFF), C(0xC9D6FF))
    default:   // not Jedi: never drawn here
        (offset, core, glow) = (0, C(0xEAFFEA), C(0x3FE85A))
    }
    let p = saberPose(t, walking: walking, role: role, speed: who == .yoda ? 1.15 : 0.9, offset: offset)
    let step = walkStep(t, walking)
    c.ox = Int(p.dx.rounded()); c.oy = Int(p.dy.rounded())
    let cream = C(0xE4D3B0), robe = C(0x7A5532), belt = C(0x5A3A22)
    var look = Look(leg: C(0x8A6A44))
    switch who {
    case .yoda: look = Look(body: C(0x8DB360), shade: C(0x6E9148), leg: C(0x8DB360), arm: C(0x8DB360))
    case .mace: look = Look(leg: C(0x3A2A1C), arm: C(0x4A3322))
    case .rey: look = Look(leg: C(0x9A8A72), arm: C(0xB5A58A))
    case .ahsoka: look = Look(body: C(0xD9693A), shade: C(0xB0532C), leg: C(0x5A4A3A), arm: C(0xD9693A))
    default: look = Look(leg: C(0x6E5236), arm: robe)
    }
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)

    switch who {
    case .quigon:
        let H = C(0x6A4A2A)
        c.pattern(16, 21, [
            ".....HHHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHH..",
            ".HHHH............HHHH.",
            "HHH................HHH",
            "HHH................HHH",
            "HH..................HH",
            "HH..................HH",
        ], ["H": H])
        c.pattern(23, 32, [".HH....HH.", "HHHHHHHHHH", ".HHHHHHHH.", "...HHHH..."], ["H": H])
        c.rect(18, 35, 20, 3, cream); c.rect(18, 36, 20, 1, belt)
    case .mace:
        c.rect(22, 28, 3, 1, C(0x2A1C12)); c.rect(31, 28, 3, 1, C(0x2A1C12))   // stern brows, bald head
        c.rect(18, 33, 20, 5, C(0x5A3A22)); c.rect(25, 33, 6, 5, cream); c.rect(18, 36, 20, 1, C(0x2A1C12))
    case .yoda:
        let ear = C(0x8DB360), earIn = C(0xC98F7A)
        c.pattern(9, 26, ["EEEEEEEEE", ".EeeeEEEE", "...EEEEEE"], ["E": ear, "e": earIn])
        c.pattern(38, 26, ["EEEEEEEEE", "EEEEeeeE.", "EEEEEE..."], ["E": ear, "e": earIn])
        c.pattern(22, 24, ["W..W..W.W..W", ".W..W...W.W."], ["W": C(0xEDEDED)])
        c.rect(18, 33, 20, 5, robe); c.rect(26, 33, 4, 5, cream)
    case .rey:
        let H = C(0x4A2E18)
        c.pattern(18, 22, ["...HHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHH", "HH..............HH"], ["H": H])
        c.pattern(15, 19, [".HH.", "HHHH", ".HHH"], ["H": H])   // buns at the back of the head
        c.pattern(15, 22, ["HHHH", "HHHH", ".HHH"], ["H": H])
        c.rect(18, 33, 20, 5, C(0xEFE6D2)); c.rect(18, 35, 20, 1, C(0xB5A58A))
    case .ahsoka:
        let W = C(0xF4F4F4), B = C(0x2E62D6)
        // montrals and lekku: white with blue stripes
        c.pattern(17, 16, [
            ".WW..............WW.",
            ".WB..............BW.",
            "WWW..............WWW",
            "WBW..............WBW",
            "WWWW............WWWW",
            "WBWW............WWBW",
            "WWWWWWWWWWWWWWWWWWWW",
            ".WWWWWWWWWWWWWWWWWW.",
            "..BB.BB..BB..BB.BB..",
        ], ["W": W, "B": B])
        c.rect(21, 28, 4, 1, W); c.rect(31, 28, 4, 1, W)        // facial markings
        c.rect(27, 30, 2, 3, W)
        c.rect(18, 33, 20, 5, C(0x4A3A30)); c.rect(18, 35, 20, 1, C(0x8A6A44))
    default:
        break
    }

    if who == .ahsoka {
        // Second, shorter shoto from the other hand, held in reverse grip.
        c.ox -= 24; c.oy += 1
        drawSaber(c, t: t, angle: 180 - p.angle * 0.6 + 40, core: core, glow: glow, lit: saberLit(role), length: 12)
        c.ox += 24; c.oy -= 1
    }
    drawSaber(c, t: t, angle: p.angle, core: core, glow: glow, lit: saberLit(role), trail: p.trail, length: who == .yoda ? 14 : 20)
}

/// Blaster-carrying agents: Chewbacca (bowcaster) and a Jawa (ion blaster).
private func drawGunner(_ c: PixelCanvas, _ who: Companion, t: Double, walking: Bool, role: FightRole) {
    let step = walkStep(t, walking)
    let bob = walking ? (step == 0 ? -1 : 0) : (sin(t * 4.5) > 0.6 ? -1 : 0)
    if who == .chewie {
        let fur = C(0x7A4E2A), furDark = C(0x5C3A1E), furLight = C(0x9A6A3E)
        let look = Look(body: fur, shade: furDark, leg: fur, arm: fur)
        drawLegs(c, look, step: step)
        c.oy = bob
        drawBody(c, look)
        c.pattern(18, 21, ["...FFFFFFFFFFFFFF...", ".FFFfFFFFFFFFFfFFFF.", "FFFFFFFFfFFFFFFFFFFF", "FfFFFFFFFFFFFFFFFfFF", "FF................FF"],
                  ["F": fur, "f": furLight])
        for (x, y) in [(20, 33), (24, 35), (30, 34), (34, 33), (22, 30), (35, 29)] { c.px(x, y, furLight) }
        c.rect(25, 33, 6, 1, C(0x3A2412))                       // mouth
        for i in 0..<10 { c.rect(19 + i * 2, 36 - i, 2, 2, i % 3 == 0 ? C(0xB9BEC8) : C(0x4A3020)) }  // bandolier
    } else {
        let robe = C(0x7A5A3A), robeDark = C(0x5A4028)
        var look = Look(body: robe, shade: robeDark, arm: robe, eye: nil)
        look.legs = false
        for y in 38...43 {
            let k = (y - 38) / 2
            c.rect(18 - k, y, 20 + k * 2, 1, robe)
            c.px(18 - k, y, robeDark); c.px(37 + k, y, robeDark)
        }
        c.oy = bob
        drawBody(c, look)
        c.pattern(18, 19, ["......RRRRRRRR......", "....RRRRRRRRRRRR....", "..RRRRRRRRRRRRRRRR..", ".RRRRRRRRRRRRRRRRRR.", "RRRRRRRRRRRRRRRRRRRR",
                           "RRRRRRRRRRRRRRRRRRRR", "RRRRRRRRRRRRRRRRRRRR"], ["R": robe])
        c.rect(21, 27, 15, 6, C(0x14100C))                      // shadowed face
        let glow = sin(t * 3) > -0.8 ? C(0xFFE14A) : C(0x8A7A2A)
        c.rect(24, 29, 2, 2, glow); c.rect(31, 29, 2, 2, glow)
        c.rect(18, 35, 20, 1, C(0x3A2A18))
    }
    let muzzleX = Int(who.muzzle.x)
    let (recoil, shake) = agentFire(c, t: t, walking: walking, role: role, period: who == .chewie ? 1.3 : 0.75,
                                    phase: who == .chewie ? 0.2 : 0.55, muzzleX: muzzleX)
    c.oy = bob - recoil
    c.ox = shake
    if who == .chewie {
        // Bowcaster: stock, body and the crossbow limbs
        c.pattern(40, 29, ["......SS......", ".......S......", "KKKKKKKKKKKKKK", "KKWWKKKKKKKK..", "...S...S......", "......SS......"],
                  ["K": C(0x3A2A1C), "W": C(0x8A6A44), "S": C(0xB9BEC8)])
    } else {
        c.pattern(40, 32, ["KKKKKK", "KKSSK.", "KK...."], ["K": C(0x4A4A52), "S": C(0x9AA0AE)])
    }
}

/// Wicket: a small furry Clawd in a leather hood, with big dark eyes and a stone-tipped spear.
private func drawEwok(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let p = saberPose(t, walking: walking, role: role, speed: 1.1, offset: 0.9)
    let step = walkStep(t, walking)
    c.ox = Int(p.dx.rounded()); c.oy = Int(p.dy.rounded())
    let fur = C(0x6E4A2A), furDark = C(0x52361E), furLight = C(0x8A6238)
    let look = Look(body: fur, shade: furDark, leg: furDark, arm: fur, eye: nil)
    drawLegs(c, look, step: step)
    c.oy += step == 0 ? -1 : 0
    drawBody(c, look)
    for (x, y) in [(20, 33), (27, 35), (33, 32), (23, 30), (31, 36)] { c.px(x, y, furLight) }
    // leather hood with little ears poking through
    c.pattern(17, 22, [
        "..E...............E...",
        ".EEH.HHHHHHHHHHH.HEE..",
        ".HHHHHHHHhHHHHHHHHHH..",
        "HHHHHHhHHHHHHHhHHHHHH.",
        "HH..................HH",
        "HH..................HH",
    ], ["H": C(0xB07A42), "h": C(0x8A5A2E), "E": furDark])
    c.rect(22, 29, 3, 3, C(0x0E0A08)); c.rect(31, 29, 3, 3, C(0x0E0A08))   // big dark eyes
    c.px(23, 29, C(0x6A5A4A)); c.px(32, 29, C(0x6A5A4A))
    c.rect(27, 32, 2, 1, C(0x2A1A10))                                      // little nose
    drawSpear(c, angle: saberLit(role) ? p.angle : -75)   // resting: spear shouldered, not through the floor
}

/// A wooden spear with a stone tip, held like a saber (same pivot, same choreography).
func drawSpear(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 4, hy - uy * 4, hx + ux * 18, hy + uy * 18, core: C(0x8A6238), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    c.glowLine(hx + ux * 18, hy + uy * 18, hx + ux * 22, hy + uy * 22, core: C(0x9AA0A8), glow: C(0, 0), coreR: 1.1, glowR: 1.2)
    c.glowLine(hx + ux * 16, hy + uy * 16, hx + ux * 17, hy + uy * 17, core: C(0xC8B48A), glow: C(0, 0), coreR: 1.0, glowR: 1.1)  // binding
}

/// A tauntaun from Hoth: a shaggy grey-white biped with curled horns, a long snout and a tail. It doesn't
/// fight — it stomps about, bobs its head and huffs frosty breath.
private func drawTauntaun(_ c: PixelCanvas, t: Double, walking: Bool) {
    let fur = C(0xD8D2C4), furShade = C(0xAEA696), furDark = C(0x8A8274), horn = C(0x8A6A48)
    let step = walking ? Int(t * 8) % 2 : (sin(t * 3) > 0.7 ? 0 : -1)        // an impatient stomp now and then
    let bob = Int((sin(t * 2.4) * 1.2).rounded())
    // Two strong legs with big feet
    for (i, lx) in [21, 31].enumerated() {
        let up = step == i ? 1 : 0
        c.rect(lx, 34, 4, 9 - up, furShade)
        c.rect(lx - 1, 42 - up, 6, 2, furDark)
    }
    // Tail swishing behind
    let sway = Int((sin(t * 2) * 2).rounded())
    c.glowLine(18, 32, 9, Double(36 + sway), core: furShade, glow: C(0, 0), coreR: 1.4, glowR: 1.5)
    // Body (a shaggy Clawd) with a little arm
    c.rect(18, 22, 18, 13, fur)
    c.rect(18, 33, 18, 2, furShade)
    for (x, y) in [(20, 25), (24, 29), (29, 24), (33, 30), (22, 32), (31, 27)] { c.px(x, y, furShade) }
    c.rect(35, 28, 3, 2, furShade)
    // Neck and head, bobbing; long snout forward, horns curling back
    c.oy = bob
    c.rect(30, 16, 6, 7, fur)
    c.rect(32, 11, 10, 7, fur)
    c.rect(42, 13, 5, 4, fur)                    // snout
    c.rect(42, 16, 5, 1, furShade)
    c.px(46, 14, furDark)                         // nostril
    c.rect(36, 13, 2, 2, C(0x1A1612))             // eye
    c.pattern(30, 7, [".HHH.", "H...H", "H....", ".H..."], ["H": horn])   // curled horn
    c.oy = 0
    // Frosty breath
    let f = (t / 1.8).truncatingRemainder(dividingBy: 1)
    if f < 0.6 {
        let k = f / 0.6
        c.circle(48 + Int(k * 7), 15 + bob - Int(k * 3), 1 + Int(k * 2), white.alpha(0.55 * (1 - k)))
    }
}
