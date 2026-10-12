import Foundation

// Idle habits: a session that's done doesn't just stand there. Every 11–19 s (its own rhythm) its character does
// something small for a second or two: looks over its shoulder, shifts its weight, or handles its weapon the way it
// would — a Sith lights and spins its saber, a gunner raises its blaster and blows the smoke off, the Emperor lets
// a little lightning crackle. Only while idle and still standing: once it sits down (2 min) it's just resting.

enum IdleHabit {
    case glance        // looks back over its shoulder
    case shuffle       // shifts its weight from foot to foot
    case bounce        // a little bounce on the spot (the unarmed ones)
    case flourish      // saber: lit, spun once, switched off; axes, pikes and claws swing up and back
    case checkWeapon   // blaster raised to eye level, then the smoke blown off the barrel
    case crackle       // lightning flickering between the fingers, hand raised
    case signature     // its own thing, drawn by its own drawing code (`Cast.hasSignature`)

    var length: Double {
        switch self {
        case .glance: return 1.6
        case .shuffle: return 1.2
        case .bounce: return 0.9
        case .flourish: return 1.8
        case .checkWeapon: return 2.2
        case .crackle: return 1.4
        case .signature: return 2.6
        }
    }
}

/// The habit being played right now, `e` seconds in. Set while a session's character is drawn (like `seatedPose`).
struct HabitPlay {
    let kind: IdleHabit
    let e: Double
    var length: Double
    var p: Double { min(1, e / length) }

    init(kind: IdleHabit, e: Double, length: Double? = nil) {
        self.kind = kind; self.e = e; self.length = length ?? kind.length
    }
}

var idleHabit: HabitPlay?

/// Previews and the docs renderer: play this habit instead of the scheduled one.
var forcedHabit: HabitPlay?

extension Cast {
    /// What this character does when idle: its weapon habit (if it handles one by hand) comes up twice as often.
    var habits: [IdleHabit] {
        if case .villain(.royalGuard) = self { return [] }     // the Emperor's guard doesn't fidget: it stands guard
        var weaponHabit: IdleHabit?
        switch self {
        case .villain(let l):
            switch l.weapon {
            case .saber: weaponHabit = .flourish
            case .blaster:
                // Walkers, the pod racer, the speeder bike and the droideka have their guns built in.
                if ![.atst, .atat, .sebulba, .scoutTrooper, .droideka].contains(l) { weaponHabit = .checkWeapon }
            case .lightning: weaponHabit = .crackle
            case .none: break
            }
        case .hero(let h):
            switch h.weapon {
            case .saber: weaponHabit = .flourish
            case .blaster, .lightning: weaponHabit = .checkWeapon
            case .none: break
            }
        }
        var list: [IdleHabit] = [.glance, .shuffle]
        list += weaponHabit.map { [$0, $0] } ?? [.bounce]
        if hasSignature { list += [.signature, .signature] }
        return list
    }

    /// Characters with a move of their own, and how long it takes:
    /// - Vader works the switches on his chest panel; Luke spins his unlit hilt; a stormtrooper bumps his head and
    ///   sees stars; Boba swings his rangefinder down over his visor.
    /// - R2-D2 projects Leia's message; C-3PO throws his arms up ("We're doomed"); Chewbacca roars; Han spins his
    ///   blaster on a finger and holsters it; Obi-Wan strokes his beard; Yoda leans on his gimer stick, ears
    ///   drooping; the tauntaun shakes its head and snorts; Maz adjusts her goggles; Grogu nibbles a cookie.
    /// - Grievous has a coughing fit; Kylo has a tantrum; Phasma's chrome catches the light; Jabba licks his lips;
    ///   IG-88's head lights spin; the Rancor roars.
    var signatureLength: Double? {
        switch self {
        case .villain(.vader), .villain(.trooper), .villain(.boba), .hero(.luke): return 2.6
        case .hero(.r2d2): return 4
        case .hero(.c3po), .hero(.chewie), .villain(.rancor): return 2
        case .hero(.han): return 3
        case .hero(.obiwan), .hero(.grogu): return 3.2
        case .hero(.yoda): return 3.4
        case .hero(.tauntaun), .hero(.maz), .villain(.jabba), .villain(.ig88): return 2.4
        case .villain(.grievous): return 2.2
        case .villain(.kylo): return 1.8
        case .villain(.phasma): return 1.4
        default: return nil
        }
    }

    var hasSignature: Bool { signatureLength != nil }

    /// The signature move playing right now, 0…1 through it (nil: not playing).
    static var signatureProgress: Double? {
        guard let h = idleHabit, h.kind == .signature else { return nil }
        return h.p
    }

    /// The habit playing at `t`, if any: one per cycle, picked afresh each cycle.
    func habit(at t: Double) -> HabitPlay? {
        if let forced = forcedHabit { return forced }
        let period = 11 + 8 * noise(id * 7 + 3)
        let lt = t + Double(id) * 3.1
        let cycle = floor(lt / period), e = lt - cycle * period
        let list = habits
        guard !list.isEmpty else { return nil }
        let kind = list[min(list.count - 1, Int(noise(Int(cycle) * 31 + id) * Double(list.count)))]
        let length = kind == .signature ? signatureLength ?? kind.length : kind.length
        return e < length ? HabitPlay(kind: kind, e: e, length: length) : nil
    }
}

/// Smooth 0→1→0 over `p` 0…1, held at 1 through the middle `hold` share.
func habitArc(_ p: Double, hold: Double = 0.4) -> Double {
    let ramp = (1 - hold) / 2
    if p < ramp { return 0.5 - 0.5 * cos(p / ramp * .pi) }
    if p > 1 - ramp { return 0.5 - 0.5 * cos((1 - p) / ramp * .pi) }
    return 1
}

/// The whole-sprite habits, applied after the character is drawn.
func applyHabitTransform(_ c: PixelCanvas, _ play: HabitPlay) {
    switch play.kind {
    case .glance:
        // Mirrored about the body's centre; skipped for anyone too wide to turn round inside the canvas.
        if play.p > 0.15 && play.p < 0.85 { c.mirror(aboutX: Sprite.bodyCenterX) }
    case .shuffle:
        c.shift(dx: Int(play.e / 0.3) % 2 == 0 ? 0 : (Int(play.e / 0.6) % 2 == 0 ? 1 : -1), dy: 0)
    case .bounce:
        c.shift(dx: 0, dy: sin(play.p * .pi * 2) > 0.3 ? -2 : 0)
    default:
        break
    }
}

/// Smoke blown off a barrel at (`x`, `y`): three puffs drifting up and fading, `k` 0…1 through it.
func drawBarrelSmoke(_ c: PixelCanvas, x: Double, y: Double, _ k: Double) {
    for i in 0..<3 {
        let f = k * 1.6 - Double(i) * 0.3
        guard f > 0, f < 1 else { continue }
        let px = Int((x + sin(f * 8) * 1.5).rounded()), py = Int((y - 2 - f * 9).rounded())
        let col = C(0xE0E0E0).alpha(0.85 * (1 - f))
        c.rect(px, py, 2, 2, col)
        c.px(px - 1, py, col.alpha(0.5))
    }
}

/// A sweep of light across chrome: a diagonal band moving left to right, `p` 0…1, only over what's drawn left of
/// `maxX` (so it catches the armour, not the gun).
func drawGlint(_ c: PixelCanvas, p: Double, maxX: Int = 40) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let k = -10 + p * 70
    for y in 0..<c.h {
        for x in 0...min(maxX, c.w - 1) where c.isDrawn(x, y) {
            let d = abs(Double(x) + Double(y) * 0.5 - k)
            if d < 2.5 { c.px(x, y, C(0xFFFFFF).alpha(d < 1 ? 0.8 : 0.4)) }
        }
    }
}
