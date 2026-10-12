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
    var p: Double { min(1, e / kind.length) }
}

var idleHabit: HabitPlay?

/// Previews and the docs renderer: play this habit instead of the scheduled one.
var forcedHabit: HabitPlay?

extension Cast {
    /// What this character does when idle: its weapon habit (if it handles one by hand) comes up twice as often.
    var habits: [IdleHabit] {
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

    /// Characters with a move of their own:
    /// Vader works the controls on his chest panel, Luke spins his unlit hilt, a stormtrooper bumps his head (and
    /// sees stars), Boba swings his rangefinder down over his visor.
    var hasSignature: Bool {
        switch self {
        case .villain(.vader), .villain(.trooper), .villain(.boba), .hero(.luke): return true
        default: return false
        }
    }

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
        let kind = list[min(list.count - 1, Int(noise(Int(cycle) * 31 + id) * Double(list.count)))]
        return e < kind.length ? HabitPlay(kind: kind, e: e) : nil
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
