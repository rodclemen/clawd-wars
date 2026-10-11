import Foundation

// One dark-side Clawd per running Claude Code session. Session #1 is always Vader.

enum Weapon { case saber, blaster, lightning, none }

extension Companion {
    var weapon: Weapon {
        switch self {
        case .luke, .obiwan, .quigon, .mace, .yoda, .rey, .ahsoka: return .saber
        case .ewok: return .saber     // a spear — fights up close like a blade
        case .han, .leia, .jawa, .chewie: return .blaster
        case .lando, .zorii, .boKatan, .wedge, .padme, .mando, .k2so: return .blaster
        case .r2d2, .c3po, .tauntaun: return .none
        case .jarjar, .maz, .l337, .monMothma, .ackbar, .grogu, .babuFrik, .gonk: return .none
        }
    }

    /// Muzzle position on the companion's canvas (blaster users only).
    var muzzle: (x: Double, y: Double) {
        switch self {
        case .han: return (53, 32)
        case .chewie: return (54, 31)
        case .lando, .zorii, .boKatan, .wedge, .padme: return (47, 32)
        case .mando: return (58, 32)
        case .k2so: return (52, 32)
        default: return (46, 32)
        }
    }
}

enum Leader: Int, CaseIterable {
    case vader, kylo, maul, boba, trooper, emperor, rogr, dooku, gamorrean, jabba, ig88, atst, atat, rancor, greedo, royalGuard
    case sebulba, salacious, grievous, tusken, cadBane, thrawn, hammerhead, mse6

    var name: String {
        switch self {
        case .vader: return "Darth Vader"
        case .kylo: return "Kylo Ren"
        case .maul: return "Darth Maul"
        case .boba: return "Boba Fett"
        case .trooper: return "Stormtrooper"
        case .emperor: return "The Emperor"
        case .rogr: return "R0-GR"
        case .dooku: return "Count Dooku"
        case .gamorrean: return "Gamorrean Guard"
        case .jabba: return "Jabba the Hutt"
        case .ig88: return "IG-88"
        case .atst: return "AT-ST"
        case .atat: return "AT-AT"
        case .rancor: return "Rancor"
        case .greedo: return "Greedo"
        case .royalGuard: return "Royal Guard"
        case .sebulba: return "Sebulba"
        case .salacious: return "Salacious Crumb"
        case .grievous: return "General Grievous"
        case .tusken: return "Tusken Raider"
        case .cadBane: return "Cad Bane"
        case .thrawn: return "Admiral Thrawn"
        case .hammerhead: return "Hammerhead"
        case .mse6: return "MSE-6"
        }
    }

    var weapon: Weapon {
        switch self {
        case .vader, .kylo, .maul: return .saber
        case .boba, .trooper, .rogr, .ig88, .atst, .atat, .greedo: return .blaster
        case .dooku, .gamorrean, .rancor, .royalGuard: return .saber   // vibro-axe, claws and force pike fight up close like a blade
        case .jabba, .salacious, .hammerhead, .mse6: return .none
        case .emperor: return .lightning
        case .sebulba, .cadBane, .thrawn: return .blaster
        case .grievous, .tusken: return .saber          // four sabers; the gaffi stick fights up close
        }
    }

    /// Armour or a metal shell: blaster bolts ricochet off it.
    var armoured: Bool {
        switch self {
        case .boba, .trooper, .rogr, .ig88, .atst, .atat: return true
        case .sebulba, .grievous, .mse6: return true
        case .vader, .kylo, .maul, .emperor, .dooku, .gamorrean, .jabba, .rancor, .greedo, .royalGuard,
             .salacious, .tusken, .cadBane, .thrawn, .hammerhead: return false
        }
    }

    /// Top row of the helmet/hood/hair on the 72x52 canvas, for placing the project label.
    var headTop: Int {
        switch self {
        case .vader: return 14
        case .kylo: return 15
        case .maul: return 23
        case .boba: return 11   // rangefinder antenna
        case .trooper: return 16
        case .emperor: return 19
        case .rogr: return 15
        case .dooku: return 21
        case .gamorrean: return 17
        case .jabba: return 19
        case .ig88: return 9
        case .atst: return 10
        case .atat: return 11
        case .rancor: return 8
        case .greedo: return 19
        case .royalGuard: return 13
        case .sebulba: return 19
        case .salacious: return 16
        case .grievous: return 14
        case .tusken: return 19
        case .cadBane: return 15
        case .thrawn: return 22
        case .hammerhead: return 10
        case .mse6: return 35
        }
    }

    /// Whether it sits down when it's been idle a while (walkers, slugs, monsters, the Emperor and his guard don't).
    var canSit: Bool {
        switch self {
        case .atst, .atat, .jabba, .rancor, .emperor, .royalGuard, .sebulba, .salacious, .hammerhead, .mse6: return false
        case .vader, .kylo, .maul, .boba, .trooper, .rogr, .dooku, .gamorrean, .ig88, .greedo,
             .grievous, .tusken, .cadBane, .thrawn: return true
        }
    }

    /// Where its weapon pivots (canvas pixels): the hand, except the Rancor's claw, which swings from the shoulder.
    var weaponPivot: (x: Double, y: Double) {
        switch self {
        case .rancor: return rancorShoulder
        case .vader, .kylo, .maul, .boba, .trooper, .emperor, .rogr, .dooku, .gamorrean, .jabba, .ig88, .atst, .atat,
             .greedo, .royalGuard, .sebulba, .salacious, .grievous, .tusken, .cadBane, .thrawn, .hammerhead,
             .mse6: return Sprite.hand
        }
    }

    /// Where its blaster bolts come out (canvas pixels). Walkers fire from their chin guns.
    var muzzle: (x: Int, y: Int) {
        switch self {
        case .atst: return (47, 22)
        case .atat: return (64, 21)
        case .greedo, .cadBane, .thrawn: return (47, 32)
        case .sebulba: return (70, 31)
        default: return (52, 32)
        }
    }

    init(index: Int) { self = Leader(rawValue: index % Leader.allCases.count) ?? .vader }
}

/// What a leader is doing on screen.
enum VaderMode {
    case idle, thinking, working, waiting
    case standGuard     // Claude is idle but its agents are still out on missions
}

/// Role in a fight between two neighbouring Claudes that are both working.
enum FightRole {
    case none
    case duel                    // saber vs saber, both on the shared clock so blades meet
    case shoot(offset: Double)   // blaster: fire at the opponent (bolts are drawn by the FX layer)
    case deflect                 // saber vs blaster: swing to meet each incoming bolt
    case block                   // saber vs lightning: hold the blade into the arc
    case zap                     // lightning (arcs drawn by the FX layer)
    case hit                     // non-saber caught by lightning: shake
    case cheer                   // odd one out: bounce and wave the weapon
    case rest                    // a hero leading an idle session: saber off, blaster lowered
    case ready(urgent: Bool)     // a hero whose session needs you: weapon held up (waved, with hops, when urgent)
}

func fightRoles(_ a: Weapon, _ b: Weapon) -> (FightRole, FightRole) {
    switch (a, b) {
    case (.saber, .saber): return (.duel, .duel)
    case (.blaster, .saber): return (.shoot(offset: 0), .deflect)
    case (.saber, .blaster): return (.deflect, .shoot(offset: 0))
    case (.blaster, .blaster): return (.shoot(offset: 0), .shoot(offset: blasterPeriod / 2))
    case (.lightning, .saber): return (.zap, .block)
    case (.saber, .lightning): return (.block, .zap)
    case (.lightning, .blaster): return (.zap, .hit)
    case (.blaster, .lightning): return (.hit, .zap)
    case (.lightning, .lightning): return (.zap, .zap)
    case (.none, _), (_, .none): return (.none, .none)
    }
}

/// Saber fighters close in for a duel; ranged fights keep normal spacing.
func fightIsCloseQuarters(_ a: Weapon, _ b: Weapon) -> Bool { a == .saber && b == .saber }

let blasterPeriod = 0.9

/// What happens to a bolt in a blaster-vs-blaster shoot-out. Plain hits stay in the mix, but most shots are saved.
enum BoltOutcome { case hit, duck, collide, shield, ricochet }

/// The outcome of the shot a shooter (by its clock offset) is firing at time `t`. A fixed cycle, so the effects
/// layer and the defender's own sprite (ducking) always agree, and both shooters run through it out of step.
func boltOutcome(t: Double, offset: Double, defenderArmoured: Bool) -> BoltOutcome {
    let cycle: [BoltOutcome] = [.hit, .duck, .collide, .shield, .ricochet, .duck, .collide, .hit, .ricochet, .shield, .duck]
    let n = Int(floor((t + offset) / blasterPeriod)) + (offset > 0 ? 4 : 0)
    let o = cycle[((n % cycle.count) + cycle.count) % cycle.count]
    return o == .ricochet && !defenderArmoured ? .duck : o   // no armour to bounce it off: get down instead
}

/// How far (0…1) a defender squats to let a bolt from the shooter with clock `offset` whizz over its head.
func duckAmount(t: Double, shooterOffset: Double, armoured: Bool) -> Double {
    guard boltOutcome(t: t, offset: shooterOffset, defenderArmoured: armoured) == .duck else { return 0 }
    let f = frac((t + shooterOffset) / blasterPeriod)
    // Down as the bolt closes in, held while it passes, back up after.
    let down = min(max((f - 0.12) / 0.12, 0), 1), up = min(max((f - 0.55) / 0.15, 0), 1)
    return down * (1 - up)
}
private let boltArrival = 0.4          // fraction of the period a bolt spends in flight
private let rifleMuzzle = (x: 52, y: 32)
private let deflectPeak = -15.0

private func frac(_ v: Double) -> Double { v - floor(v) }

func deflectAngle(_ t: Double) -> Double {
    let d = frac(t / blasterPeriod) - boltArrival
    return -75 + 60 * exp(-pow(d / 0.07, 2))
}

// MARK: - Drawing

/// `urgent`: a "needs you" that's been ignored for a while — the villain jumps up and down waving.
func drawLeader(_ c: PixelCanvas, _ who: Leader, t: Double, mode: VaderMode, walking: Bool, role: FightRole = .none,
                urgent: Bool = false, sitting: Bool = false) {
    // Long-idle Claudes sit down (the big ones just keep standing).
    var unengaged = false
    if case .none = role { unengaged = true }
    let seated = sitting && who.canSit && !walking && unengaged && (mode == .idle || mode == .standGuard)
    seatedPose = seated
    defer { seatedPose = false }
    let lt = t + Double(who.rawValue) * 0.77     // personal clock so solo leaders aren't in lockstep
    let step = walkStep(t, walking)
    var breathe = walking ? (step == 0 ? -1 : 0) : (sin(lt * 2 * .pi / 2.6) > 0.35 ? -1 : 0)
    var dx = 0, hop = 0
    var saber: Double?                // blade angle; nil = holstered
    var trail: [Double] = []
    var fire: (t: Double, bolt: Bool)?
    var zap: Bool?                    // true = draw the arc in-canvas
    var capeSpeed = 1.6
    var armRaise = 0

    if walking {
        if mode != .idle && mode != .thinking { saber = -60 }
    } else {
        switch mode {
        case .idle, .thinking:
            break
        case .waiting:
            saber = urgent ? -90 + 25 * sin(t * 12) : -90 + 2 * sin(t * 3)
            if urgent { hop = cheerHop(t * 1.5); breathe = 0 }
        case .standGuard:
            saber = -65 + 3 * sin(t * 2.2)
            capeSpeed = 2.2
        case .working:
            capeSpeed = 4.5
            switch role {
            case .duel:
                let p = duelPose(t)
                saber = p.angle; dx = Int(p.dx.rounded()); hop = Int(p.dy.rounded()); breathe = 0
                trail = saberTrail(t, pose: { duelPose($0).angle })
            case .deflect:
                saber = deflectAngle(t)
                trail = saberTrail(t, pose: deflectAngle)
            case .block:
                saber = -60 + 2 * sin(t * 37)
                dx = -1
            case .shoot(let offset):
                fire = (t + offset, false)
            case .zap:
                zap = false
            case .hit:
                dx = noise(Int(t * 30)) > 0.5 ? 1 : -1
                hop = noise(Int(t * 30) + 7) > 0.6 ? -1 : 0
            case .cheer:
                hop = cheerHop(t); breathe = 0
                switch who.weapon {
                case .saber: saber = -95 + 18 * sin(t * 9)
                case .lightning: zap = false
                default: break
                }
            case .none, .rest, .ready:
                switch who.weapon {
                case .saber:
                    let p = kataPose(lt)
                    saber = p.angle; dx = Int(p.dx.rounded()); hop = Int(p.dy.rounded()); breathe = 0
                    trail = saberTrail(lt)
                case .blaster: fire = (lt, true)
                case .lightning: zap = true
                case .none: break
                }
            }
        }
    }
    // The Tusken Raider is never calm: when it isn't fighting it shakes its gaffi stick over its head and hops.
    if who == .tusken, !walking, saber == nil {
        saber = -100 + 25 * sin(t * 9); hop = cheerHop(t * 0.8); breathe = 0
    }
    if zap != nil { armRaise = 2 }

    if case .cheer = role, mode == .working, !walking { drawCheerSparkles(c, t: t) }

    if seated { hop += 4 }

    // Back layer moves with hops but not with breathing.
    c.ox = dx; c.oy = hop
    switch who {
    case .vader, .kylo: drawCape(c, t: t, speed: capeSpeed, color: C(0x0E0E12), edge: C(0x2C2C36))
    case .dooku: drawCape(c, t: t, speed: capeSpeed, color: C(0x2A1A14), edge: C(0x4A3024))
    case .emperor: drawCape(c, t: t, speed: capeSpeed * 0.6, color: C(0x111116), edge: C(0x2A2A33), extra: 1.5)
    case .royalGuard: drawCape(c, t: t, speed: capeSpeed * 0.5, color: C(0x6E0C10), edge: C(0x8E1418), extra: 0.5)
    case .grievous: drawCape(c, t: t, speed: capeSpeed * 0.7, color: C(0x3A3028), edge: C(0x5A4A3A))
    case .boba: drawJetpack(c, t: t, burning: fire.map { frac($0.t / blasterPeriod) > 0.7 } ?? false)
    default: break
    }

    switch who {
    case .vader: drawVaderCostume(c, step: step, lift: breathe)
    case .kylo: drawKylo(c, step: step, lift: breathe)
    case .maul: drawMaul(c, step: step, lift: breathe)
    case .boba: drawBoba(c, step: step, lift: breathe)
    case .trooper: drawTrooper(c, step: step, lift: breathe)
    case .rogr: drawBattleDroid(c, step: step, lift: breathe)
    case .dooku: drawDooku(c, step: step, lift: breathe)
    case .gamorrean: drawGamorrean(c, step: step, lift: breathe)
    case .jabba: drawJabba(c, t: t, lift: breathe)
    case .ig88: drawIG88(c, step: step, lift: breathe)
    case .atst: drawATST(c, step: step, lift: breathe)
    case .atat: drawATAT(c, step: step, lift: breathe)
    case .rancor: drawRancor(c, step: step, lift: breathe)
    case .greedo: drawGreedo(c, step: step, lift: breathe)
    case .emperor: drawEmperor(c, lift: breathe, armRaise: armRaise)
    case .royalGuard: drawRoyalGuard(c, lift: breathe)
    case .sebulba: drawSebulbaPod(c, t: t, lift: breathe)
    case .salacious: drawSalacious(c, t: t, lift: breathe)
    case .grievous: drawGrievous(c, step: step, lift: breathe)
    case .tusken: drawTusken(c, step: step, lift: breathe)
    case .cadBane: drawCadBane(c, step: step, lift: breathe)
    case .thrawn: drawThrawn(c, step: step, lift: breathe)
    case .hammerhead: drawHammerhead(c, lift: breathe)
    case .mse6: drawMouseDroid(c, t: t)
    }

    // Weapon
    switch who.weapon {
    case .saber:
        let lit = saber != nil
        let angle = saber ?? 0
        switch who {
        case .maul:
            if lit {
                drawSaber(c, t: t, angle: angle + 180, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, length: 15)
                drawSaber(c, t: t, angle: angle, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, trail: trail, length: 15)
            } else {
                c.rect(36, 34, 2, 8, C(0x2A2A2F)); c.rect(36, 37, 2, 2, C(0xB9BEC8))
            }
        case .kylo:
            if lit {
                drawSaber(c, t: t, angle: angle, core: C(0xFFD6D6), glow: C(0xFF2A1A), lit: true, trail: trail,
                          crossguard: true, unstable: true)
            } else {
                c.rect(36, 37, 2, 5, C(0x3A3A42)); c.rect(35, 38, 4, 1, C(0x3A3A42))
            }
        case .gamorrean:
            drawAxe(c, angle: lit ? angle : -75)      // resting: axe shouldered, not through the floor
        case .rancor:
            drawClaw(c, angle: lit ? angle : 30)      // resting: arm hangs forward, claws above the floor
        case .royalGuard:
            drawPike(c, angle: lit ? angle : -84)     // resting: held upright at its side, as they stand guard
        case .tusken:
            drawGaffi(c, angle: lit ? angle : -75)
        case .grievous:                               // four arms, four blades: two forward, two from the back hands
            let blue = (core: C(0xE6F4FF), glow: C(0x3D9BFF)), green = (core: C(0xEAFFEA), glow: C(0x3FE85A))
            if lit {
                c.ox -= 22; c.oy -= 2
                drawSaber(c, t: t, angle: 180 - angle * 0.6 + 40, core: blue.core, glow: blue.glow, lit: true, length: 17)
                drawSaber(c, t: t, angle: 180 - angle * 0.6 + 75, core: green.core, glow: green.glow, lit: true, length: 17)
                c.ox += 22; c.oy += 2
                drawSaber(c, t: t, angle: angle + 30, core: blue.core, glow: blue.glow, lit: true)
                drawSaber(c, t: t, angle: angle, core: green.core, glow: green.glow, lit: true, trail: trail)
            } else {
                c.rect(36, 37, 2, 5, C(0xB9BEC8)); c.rect(13, 34, 2, 5, C(0xB9BEC8))
            }
        default:
            if lit {
                drawSaber(c, t: t, angle: angle, core: C(0xFFE3E3), glow: C(0xFF1E2D), lit: true, trail: trail)
            } else {
                c.rect(36, 37, 2, 5, C(0xB9BEC8)); c.rect(36, 39, 2, 1, C(0x2A2A2F))
            }
        }
    case .blaster:
        var recoil = 0
        if let fire {
            recoil = fireBlaster(c, t: fire.t, period: blasterPeriod, muzzleX: who.muzzle.x, muzzleY: who.muzzle.y,
                                 bolt: fire.bolt)
        }
        c.oy = hop + breathe - recoil
        switch who {
        case .boba: drawEE3(c, x: 38, y: 30)
        case .rogr: drawE5(c, x: 39, y: 31)
        case .ig88: drawE11(c, x: 37, y: 30)
        case .atst, .atat, .sebulba: break             // chin guns are part of the walker; the pod's flame jet too
        case .cadBane, .thrawn: drawPistol(c, x: 40, y: 31)
        case .greedo:
            c.pattern(40, 31, [".KKKKK", "KKKKSK", "KK....", "KK...."], ["K": C(0x2A2A30), "S": C(0x8A8F9C)])
        default: drawE11(c, x: 37, y: 30)
        }
    case .lightning:
        c.oy = hop + breathe
        if zap == true {
            drawLightning(c, from: (41.5, 32.5), to: (70, 30), t: t)
        } else if zap == false || mode == .waiting {
            // crackle between the fingers
            let i = Int(t * 20)
            c.px(41 + Int(noise(i) * 3), 31 + Int(noise(i + 1) * 3), C(0xBFD8FF))
            c.px(41 + Int(noise(i + 2) * 3), 31 + Int(noise(i + 3) * 3), C(0xFFFFFF))
        }
    case .none:
        break
    }
    c.ox = 0; c.oy = 0
}

func drawCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px, extra: Double = 0) {
    for y in 27...43 where y + c.oy <= 43 {      // hem ends on the feet's row (43), never below
        let k = Double(y - 27) / 16
        let hw = 10.5 + k * (4.5 + extra)
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((Sprite.bodyCenterX - hw + sway).rounded())
        let r = Int((Sprite.bodyCenterX + hw + sway).rounded()) - 1
        c.rect(l, y, r - l + 1, 1, color)
        c.px(l, y, edge)
        c.px(r, y, edge)
    }
}

private func drawJetpack(_ c: PixelCanvas, t: Double, burning: Bool) {
    let pack = C(0x7D8A6E), packShade = C(0x5E6A52)
    for x in [13, 38] {
        c.rect(x, 23, 5, 11, pack)
        c.rect(x + 4, 23, 1, 11, packShade)
        c.rect(x, 34, 5, 1, C(0x4A4A52))
    }
    c.rect(13, 21, 5, 2, C(0xC8402A))   // the missile
    c.rect(14, 20, 3, 1, C(0xC8402A))
    if burning {
        for x in [14, 39] {
            let len = 3 + Int(noise(Int(t * 30) + x) * 3)
            c.rect(x, 35, 3, len, C(0xFF9A2A))
            c.rect(x + 1, 35, 1, len + 1, C(0xFFE27A))
        }
    }
}

// MARK: Costumes

private func drawVaderCostume(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    drawLegs(c, Look(leg: C(0x2E2F36)), step: step)
    c.oy = base + lift
    drawBody(c, Look())
    c.rect(15, 33, 1, 3, ink)
    c.rect(40, 33, 1, 3, ink)
    c.pattern(15, 14, [
        ".........KKKKKKKK.........",
        ".......KKKKKKKKKKKK.......",
        "......KKKHHKKKKKKKKK......",
        ".....KKKHHKKKKKKKKKKK.....",
        ".....KKHHKKKKKKKKKKKK.....",
        "....KKKHKKKKKKKKKKKKKK....",
        "....KKKKKKKKKKKKKKKKKK....",
        "....KKKKKKKKKKKKKKKKKK....",
        "...KKKKKKKKKKKKKKKKKKKK...",
        "...KKKKKKKKKKKKKKKKKKKK...",
        "..KKKKKKKKKKKKKKKKKKKKKK..",
        "..KKKGGGGGGGGGGGGGGGGKKK..",
        ".KKKK................KKKK.",
        ".KKK..................KKK.",
        "KKKK..................KKKK",
        "KKK....................KKK",
        "KK......................KK",
        "K........................K",
    ], ["K": ink, "H": C(0x5C6070), "G": C(0x3A3D46)])
    c.pattern(25, 32, [".GGGG.", "GSGGSG", ".GSSG."], ["G": C(0x3A3D46), "S": C(0x9AA0AE)])
    c.pattern(31, 34, ["GGGGG", "GRgBG", "GGGGG"],
              ["G": C(0x3A3D46), "R": C(0xE0303A), "g": C(0x3BD15A), "B": C(0x3A7BEA)])
    c.rect(18, 37, 20, 1, C(0x2A2B31))
    c.rect(26, 37, 4, 1, C(0x9AA0AE))
}

private func drawKylo(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let black = C(0x1E1E24), silver = C(0xA9AEB8)
    drawLegs(c, Look(leg: black), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: black))
    c.pattern(16, 15, [
        "......KKKKKKKKKKKK......",
        "....KKKKKKKKKKKKKKKK....",
        "...KKKKKKKKKKKKKKKKKK...",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKSSSSSSSSSSSSSSSSKK..",
        "..KKKKKKKKKSSKKKKKKKKK..",
        "..KKKKKKKKKSSKKKKKKKKK..",
        ".KKKKKKKKKKSSKKKKKKKKKK.",
        ".KKKKKKKKKKSSKKKKKKKKKK.",
        ".KKK.......SS.......KKK.",
        "KKKK................KKKK",
        "KKK..................KKK",
        "KK....................KK",
    ], ["K": C(0x16161B), "S": silver])
    c.rect(27, 27, 2, 4, silver)
    c.rect(21, 28, 4, 1, silver)
    c.rect(31, 28, 4, 1, silver)
    c.rect(18, 33, 20, 5, black)
    c.rect(18, 35, 20, 1, C(0x3A3A42))
}

private func drawMaul(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let robe = C(0x1A1A1F)
    drawLegs(c, Look(leg: robe), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: C(0xC0262D), shade: C(0x8E1A20), arm: robe, eye: C(0xF5D547)))
    let K: [Character: Px] = ["K": C(0x111114)]
    c.pattern(18, 26, ["KK...K..KKKK..K...KK", "K....KK..KK..KK....K"], K)
    c.pattern(18, 32, ["..KK....KKKK....KK..", "...KKK..KKKK..KKK..."], K)
    c.px(21, 29, C(0x111114)); c.px(34, 29, C(0x111114))
    c.pattern(18, 23, ["..h..h...hh...h..h..", "..H..H...HH...H..H..", "..H..H..H..H..H..H.."], ["H": C(0xF0E6CC), "h": C(0xFFF8E6)])
    c.rect(18, 34, 20, 4, robe)
    c.rect(18, 35, 20, 1, C(0x3A3A42))
}

private func drawBoba(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let armor = C(0x6B7A5E), armorShade = C(0x4E5A44)
    drawLegs(c, Look(leg: C(0x6E6A5A)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: armor, shade: armorShade, arm: C(0x9A8F72), eye: nil))
    c.pattern(16, 17, [
        "......GGGGGGGGGGGG......",
        "....GGGGGGGGGGGGGGGG....",
        "...GGGGGRRGGGGGGGGGGG...",
        "..GGGGGGRRGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGG..",
        ".GGGGGGGGGGGGGGGGGGGGGG.",
        ".GGGGGGGGGGGGGGGGGGGGGG.",
    ], ["G": armor, "R": C(0xA8442E)])
    c.rect(20, 28, 16, 2, ink)       // T visor
    c.rect(27, 30, 2, 5, ink)
    c.rect(38, 11, 1, 8, C(0x9AA0AE)) // rangefinder antenna
    c.rect(37, 17, 2, 2, C(0x9AA0AE))
    c.rect(18, 35, 20, 1, armorShade)
    c.rect(18, 37, 20, 1, C(0x6B4A2B))
    c.rect(21, 37, 2, 1, C(0xB08D57)); c.rect(32, 37, 2, 1, C(0xB08D57))
}

private func drawTrooper(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let armor = C(0xF2F3F5), edge = C(0x8C93A0)
    // Faint outline so the white armour still reads on a white window.
    c.rect(18, 36, 2, 1, edge)
    drawLegs(c, Look(leg: C(0xC3C9D2)), step: step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 39, 2, 1, edge) }
    c.oy = base + lift
    c.rect(17, 25, 22, 14, edge)
    drawBody(c, Look(body: armor, shade: C(0xC9CED6), arm: armor, eye: nil))
    c.pattern(15, 16, [
        ".......oooooooooooo.......",
        ".....ooWWWWWWWWWWWWoo.....",
        "....oWWWWWWWWWWWWWWWWo....",
        "...oWWWWWWWWWWWWWWWWWWo...",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oWWWWWWWWWWWWWWWWWWWWo..",
        "..oggggggggggggggggggggo..",
        ".oWWWWWWWWWWWWWWWWWWWWWWo.",
        ".oWWWWWWWWWWWWWWWWWWWWWWo.",
    ], ["W": armor, "g": C(0x9AA0AE), "o": edge])
    c.rect(21, 28, 4, 3, ink)
    c.rect(31, 28, 4, 3, ink)
    c.rect(25, 32, 6, 2, C(0x9AA0AE))
    c.px(26, 32, ink); c.px(28, 32, ink); c.px(30, 32, ink)
    c.rect(18, 36, 20, 1, ink)
    c.rect(27, 36, 2, 1, armor)
}

/// The Gamorrean guard's vibro-axe: a long haft with a heavy blade at the end.
private func drawAxe(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 3, hy - uy * 3, hx + ux * 17, hy + uy * 17, core: C(0x5A3A22), glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    // Blade: a wedge on one side of the haft near the end
    let px = -uy, py = ux
    for i in 0..<6 {
        let along = 12.0 + Double(i)
        let width = 4.5 - abs(Double(i) - 2.5) * 0.6
        c.glowLine(hx + ux * along, hy + uy * along, hx + ux * along + px * width, hy + uy * along + py * width,
                   core: C(0xA9AEB8), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    }
    c.glowLine(hx + ux * 12 + px * 4.5, hy + uy * 12 + py * 4.5, hx + ux * 17 + px * 4.5, hy + uy * 17 + py * 4.5,
               core: C(0xE4E8EE), glow: C(0, 0), coreR: 0.6, glowR: 0.7)
}

/// The Royal Guard's force pike: a long dark staff with a silver head, the tip crackling when it's swung.
private func drawPike(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 7, hy - uy * 7, hx + ux * 17, hy + uy * 17, core: C(0x8A8E99), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    c.glowLine(hx + ux * 17, hy + uy * 17, hx + ux * 21, hy + uy * 21, core: C(0xC9CED8), glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    c.glowLine(hx + ux * 21, hy + uy * 21, hx + ux * 22.5, hy + uy * 22.5, core: C(0xFFF2C0), glow: C(0, 0), coreR: 0.6, glowR: 0.7)
}

private func drawDooku(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let robe = C(0x2A1A14)
    drawLegs(c, Look(leg: C(0x1E1410)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: robe))
    let W = C(0xDCDCDC), w = C(0xB4B4B4)
    c.pattern(18, 22, ["....WWWWWWWWWWWW....", "..WWwWWWWWWWWWWwWW..", ".WW..............WW.", "WW................WW"], ["W": W, "w": w])
    c.pattern(24, 32, ["WW....WW", ".WWWWWW.", "..WWWW..", "...WW..."], ["W": W])   // pointed beard
    c.rect(18, 33, 20, 5, robe)
    c.pattern(24, 32, ["WW....WW", ".WWWWWW.", "..WWWW..", "...WW..."], ["W": W])
    c.rect(18, 36, 20, 1, C(0x8A6A3A))
    c.rect(26, 35, 4, 1, C(0xC9A44A))   // cape clasp chain
}

private func drawGamorrean(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let green = C(0x6E8B3D), greenDark = C(0x55702C), leather = C(0x5A3A22)
    drawLegs(c, Look(leg: greenDark), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.pattern(17, 18, ["H..................H", "HH..LLLLLLLLLLLL..HH", ".HLLLLLLLLLLLLLLLLH.", "..LLLLLLLLLLLLLLLL..",
                       ".LLLLLLLLLLLLLLLLLL.", "LLLLLLLLLLLLLLLLLLLL", "LL................LL"],
              ["L": leather, "H": C(0xE8DCC0)])                 // leather cap with horns
    c.rect(23, 28, 2, 2, C(0x1A1A10)); c.rect(32, 28, 2, 2, C(0x1A1A10))   // small piggy eyes
    c.pattern(25, 30, [".PPPPP.", "PPkPkPP", ".PPPPP."], ["P": C(0x9AB070), "k": C(0x2A2A18)])   // snout
    c.px(23, 34, C(0xF4EEDC)); c.px(33, 34, C(0xF4EEDC))      // tusks
    c.rect(18, 35, 20, 3, C(0x6A4A2A))                          // fur loincloth
    for x in stride(from: 19, to: 38, by: 3) { c.px(x, 37, C(0x4A3020)) }
}

private func drawJabba(_ c: PixelCanvas, t: Double, lift: Int) {
    let skin = C(0x8E8B4E), dark = C(0x6E6B38), belly = C(0xB0A86A)
    let laugh = sin(t * 9) > 0 ? -1 : 0
    // Tail curling off behind, then the big slug body (no legs).
    c.pattern(4, 36, ["......SSSS", "...SSSSSSS", ".SSSSSSSSS", "SSSSSSSSSS", "SS........"], ["S": dark])
    // the belly stays planted on the floor; only the upper body bobs as he laughs
    for y in 40...43 {
        let hw = 10 + Double(y - 22) / 21 * 7
        let l = Int((Sprite.bodyCenterX - hw).rounded()), r = Int((Sprite.bodyCenterX + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
    }
    c.oy += lift + laugh
    for y in 22...43 {
        let k = Double(y - 22) / 21
        let hw = 10 + k * 7
        let l = Int((Sprite.bodyCenterX - hw).rounded()), r = Int((Sprite.bodyCenterX + hw).rounded())
        c.rect(l, y, r - l, 1, skin)
        c.px(l, y, dark); c.px(r - 1, y, dark)
    }
    c.rect(20, 34, 18, 9, belly)
    for y in stride(from: 35, to: 43, by: 2) { c.rect(21, y, 16, 1, C(0x9A925A)) }
    c.pattern(21, 26, ["OOO.....OOO", "OKO.....OKO"], ["O": C(0xE08A2A), "K": C(0x2A1A0A)])   // slit eyes
    c.rect(19, 31, 20, 1, C(0x4A4626))                          // the enormous mouth
    c.rect(20, 32, 18, 1, laugh < 0 ? C(0x7A3A3A) : dark)
    c.rect(38, 33, 4, 2, skin)                                  // tiny arm
}

private func drawIG88(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let metal = C(0x6F747C), metalDark = C(0x4C5058), metalLight = C(0x9AA0A8)
    drawLegs(c, Look(leg: metalDark), step: step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 39, 2, 1, metalLight) }
    c.oy = base + lift
    drawBody(c, Look(body: metal, shade: metalDark, arm: metalDark, eye: nil))
    c.rect(20, 28, 16, 2, metalDark); c.rect(22, 31, 12, 4, metalDark)    // chest plating
    c.rect(24, 32, 2, 2, C(0xE0303A)); c.rect(30, 32, 2, 2, C(0xE0303A))
    c.rect(27, 22, 2, 4, metalDark)                                       // neck
    // Tall cylindrical sensor head
    c.pattern(23, 9, ["..MMMMMM..", ".MMLMMMMM.", "MMLMMMMMMM", "MMLMMMMMMM", "RRRRRRRRRR", "MMLMMMMMMM",
                      "MMLMMMMMMM", "MMLMMMMMMM", "RRRRRRRRRR", "MMLMMMMMMM", "MMMMMMMMMM", ".MMMMMMMM.", "..MMMMMM.."],
              ["M": metal, "L": metalLight, "R": C(0xC0392B)])
}

/// Greedo: a green Rodian Clawd — huge glossy black eyes, a tapir snout, spines on top, a vest and a pistol.
private func drawGreedo(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0x5E9A4A), skinShade = C(0x467A36), skinLight = C(0x7AB860)
    drawLegs(c, Look(leg: C(0x4A4A52)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: skinShade, arm: skin, eye: nil))
    // head spines and the little ear fans
    c.pattern(19, 21, ["...S..S..S...S..S...", "..SSS.SS.SS..SS.SSS.", ".SSSSSSSSSSSSSSSSSS."], ["S": skinShade])
    c.pattern(14, 27, ["EE", "EEE", "EE"], ["E": skinLight]); c.pattern(39, 27, [".EE", "EEE", ".EE"], ["E": skinLight])
    for (x, y) in [(20, 27), (35, 26), (24, 35), (31, 34)] { c.px(x, y, skinLight) }
    // the big multifaceted eyes
    for ex in [20, 31] {
        c.rect(ex, 27, 5, 5, C(0x0A0C10)); c.rect(ex + 1, 26, 3, 7, C(0x0A0C10))
        c.px(ex + 1, 28, C(0x6A8AB0)); c.px(ex + 2, 27, C(0xBFD8F0))
    }
    // tapir snout
    c.rect(26, 31, 4, 3, skinShade); c.rect(27, 34, 2, 2, skinShade); c.px(27, 35, C(0x2A3A20))
    // vest over a pale tunic
    c.rect(18, 33, 20, 5, C(0xC8BCA0))
    c.rect(18, 33, 5, 5, C(0x3A3A2E)); c.rect(33, 33, 5, 5, C(0x3A3A2E))
    c.rect(18, 37, 20, 1, C(0x5A4A32))
}

/// The rancor: a towering, hunched reptile that stands upright on two short, stubby legs, with a flat face
/// that's mostly fanged mouth, tiny eyes, spines over its back and shoulders, and very long arms.
private func drawRancor(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let hide = C(0x8A7A62), shade = C(0x6A5C48), light = C(0xA89878), spine = C(0x4A3E30), claw = C(0xE8DCC0)
    for (i, lx) in [21, 31].enumerated() {                          // two short, stubby legs
        let up = step >= 0 && i == step ? 1 : 0
        c.rect(lx, 35, 6, 8 - up, shade)
        c.rect(lx - 1, 42 - up, 8, 2, C(0x54483A))
        for k in 0..<3 { c.px(lx - 1 + k * 3, 43 - up, claw) }      // three toes
    }
    c.oy = base + lift
    // tall torso, hunched forward (shoulders lean right)
    for y in 14...36 {
        let lean = (36 - y) / 4                                     // top leans toward the head
        c.rect(19 + lean, y, 18, 1, hide)
        c.px(19 + lean, y, shade)
    }
    c.rect(21, 33, 16, 3, shade)                                    // belly fold
    for (x, y) in [(24, 20), (29, 25), (23, 29), (32, 18), (27, 31), (33, 28)] { c.rect(x, y, 2, 1, light) }   // scales
    for k in 0..<5 { c.px(21 + k * 3 + (5 - k) / 2, 13 - k % 2, spine); c.px(21 + k * 3 + (5 - k) / 2, 14, spine) }  // back spines
    // the near arm hangs almost to the ground — they're long
    c.rect(16, 19, 4, 20, shade)
    c.rect(15, 38, 6, 2, shade)
    for k in 0..<3 { c.px(15 + k * 2, 40, claw) }
    c.px(17, 22, spine); c.px(17, 26, spine)
    // flat face dominated by the mouth, thrust forward on the hunch
    c.rect(34, 9, 13, 14, hide)
    c.rect(34, 9, 13, 2, light)
    c.px(37, 11, spine); c.px(41, 10, spine)                        // brow ridges
    c.px(38, 12, C(0xFFD23D)); c.px(43, 12, C(0xFFD23D))            // tiny eyes
    c.rect(35, 15, 12, 7, C(0x3A1A12))                              // the mouth
    for k in 0..<6 { c.px(35 + k * 2, 15, claw); c.px(36 + k * 2, 21, claw) }   // fangs top and bottom
    c.rect(35, 22, 12, 1, shade)                                    // jaw
}

/// The Rancor's shoulder, below the jaw: its claw arm pivots here (the fight effects need it too).
private let rancorShoulder = (x: 35.0, y: 25.0)

/// The rancor's reaching arm: very long, thick, ending in three claws.
private func drawClaw(_ c: PixelCanvas, angle: Double) {
    let (hx, hy) = rancorShoulder
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r)
    c.glowLine(hx, hy, hx + ux * 20, hy + uy * 20, core: C(0x7A6A54), glow: C(0, 0), coreR: 1.8, glowR: 1.9)
    let tx = hx + ux * 20, ty = hy + uy * 20
    for k in -1...1 {
        let a = r + Double(k) * 0.35
        c.glowLine(tx, ty, tx + cos(a) * 5, ty + sin(a) * 5, core: C(0xE8DCC0), glow: C(0, 0), coreR: 0.6, glowR: 0.7)
    }
}

/// AT-ST: a grey cockpit Clawd on two long jointed legs, chin guns forward.
private func drawATST(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let metal = C(0x8A8F9C), dark = C(0x5C616C), light = C(0xB4BAC6)
    // Legs: hip → backward knee → ankle → wide foot. The lifted leg steps up a pixel.
    for (i, hx) in [22, 32].enumerated() {
        let up = step >= 0 && i == step ? 1 : 0
        c.rect(hx, 24, 3, 8 - up, dark)                    // thigh
        c.rect(hx - 3, 31 - up, 4, 2, metal)               // knee joint (bends back)
        c.rect(hx - 2, 32 - up, 3, 10, metal)              // shin
        c.rect(hx - 5, 42 - up, 10, 2, dark)               // foot
        c.rect(hx - 5, 42 - up, 2, 1, light)
    }
    c.oy = base + lift
    // The cockpit: Clawd-shaped head with a viewport slit, side guns and chin cannons.
    c.rect(18, 12, 20, 12, metal)
    c.rect(18, 12, 20, 2, light)
    c.rect(37, 12, 1, 12, dark)
    c.rect(22, 16, 13, 2, C(0x1A1C21))                     // viewport
    c.px(24, 16, C(0xE0303A))
    c.rect(16, 15, 2, 6, dark); c.rect(38, 17, 3, 3, dark) // side pods
    c.rect(38, 21, 9, 1, C(0x3A3D46)); c.rect(38, 23, 7, 1, C(0x3A3D46))   // chin guns
    c.rect(24, 24, 8, 2, dark)                             // hip block
}

/// AT-AT: Clawd as the walker's body — it already has four legs — with the neck, the head and chin cannons.
private func drawATAT(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let metal = C(0x9A9EA8), dark = C(0x6A6F7A), light = C(0xC4C8D0)
    for (i, lx) in [16, 22, 34, 40].enumerated() {
        let up = step >= 0 && i % 2 == step ? 1 : 0
        c.rect(lx, 26, 3, 7 - up, metal)                   // upper leg
        c.rect(lx - 1, 32 - up, 5, 2, dark)                // knee
        c.rect(lx, 34 - up, 3, 8, metal)                   // lower leg
        c.rect(lx - 1, 42 - up, 5, 2, dark)                // round foot
    }
    c.oy = base + lift
    // Body
    c.rect(13, 14, 32, 12, metal)
    c.rect(13, 14, 32, 2, light)
    c.rect(13, 24, 32, 2, dark)
    for x in stride(from: 17, to: 44, by: 6) { c.rect(x, 17, 1, 6, dark) }   // armour plates
    // Neck and head
    c.rect(45, 17, 4, 4, dark)
    c.rect(49, 13, 13, 9, metal)
    c.rect(49, 13, 13, 2, light)
    c.rect(52, 16, 6, 2, C(0x1A1C21))                      // viewport
    c.rect(62, 15, 2, 5, dark)                             // snout
    c.rect(56, 21, 8, 1, C(0x3A3D46)); c.rect(58, 22, 4, 1, C(0x3A3D46))  // chin cannons
}

/// R0-GR, a B1 battle droid: tan, skinny-limbed, with the long forward-pointing snout head.
private func drawBattleDroid(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let tan = C(0xD4C08F), tanShade = C(0xA8946A), dark = C(0x6E5E3E)
    let look = Look(body: tan, shade: tanShade, leg: C(0xC2AE7E), arm: tan, eye: nil)
    // Thin droid legs: draw them, then carve them narrower.
    drawLegs(c, look, step: step)
    for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 4, dark) }
    c.oy = base + lift
    drawBody(c, look)
    c.rect(20, 28, 16, 1, tanShade)          // chest plates
    c.rect(20, 31, 16, 1, tanShade)
    c.rect(26, 27, 4, 8, C(0xC7B282))
    c.rect(24, 34, 8, 2, dark)               // backpack strap / power unit
    c.rect(27, 22, 2, 4, dark)               // neck
    c.pattern(21, 15, [
        "....HHHHHH......",
        "..HHHHHHHHHHH...",
        ".HHEEHHHHHHHHHHH",
        ".HHEEHHHHHHHHHHs",
        "..HHHHHHHHHHHss.",
        "....hhhhhhhh....",
        ".....hhhhh......",
    ], ["H": tan, "h": tanShade, "s": tanShade, "E": C(0x2A2418)])
}

/// The B1's E-5 blaster: slim tan-brown rifle with a shoulder stock.
func drawE5(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "..BBBBBBBBBBB",
        "BBBBBBbBb....",
        "BB...BB......",
    ], ["B": C(0x5A4A32), "b": C(0x8A7652)])
}

private func drawEmperor(_ c: PixelCanvas, lift: Int, armRaise: Int) {
    let robe = C(0x1A1A20), robeEdge = C(0x2E2E38)
    for y in 36...43 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, robe)
        c.px(17 - k, y, robeEdge); c.px(38 + k, y, robeEdge)
    }
    c.oy += lift
    var look = Look(body: C(0xD08A6C), shade: C(0xA86A50), arm: robe, eye: C(0xF5D547))
    look.legs = false
    drawBody(c, look, armRight: armRaise)
    drawHood(c, robe, robeEdge)
    c.rect(18, 33, 20, 5, robe)
    c.rect(26, 33, 4, 1, C(0xA86A50))
}

/// The Emperor's Royal Guard: crimson from head to foot, a floor-length robe over a smooth, tall helmet with a
/// black T-shaped visor slit.
private func drawRoyalGuard(_ c: PixelCanvas, lift: Int) {
    let red = C(0xB3161B), dark = C(0x7E0E12), shine = C(0xE0484C)
    for y in 36...43 {
        let k = (y - 36) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, red)
        c.px(17 - k, y, dark); c.px(38 + k, y, dark)
        if y > 38 { c.px(23, y, dark); c.px(32, y, dark) }       // folds
    }
    c.oy += lift
    var look = Look(body: red, shade: dark, arm: red, eye: nil)
    look.legs = false
    drawBody(c, look)
    c.pattern(16, 13, [
        ".........RRRRRR.........",
        ".......RRRRRRRRRR.......",
        "......RRSSRRRRRRRR......",
        "......RSSRRRRRRRRRD.....",
        ".....RRSRRRRRRRRRRRD....",
        ".....RSSRRRRRRRRRRRD....",
        ".....RSRRRRRRRRRRRRD....",
        ".....RSRRRRRRRRRRRRD....",
        "....RRRRRRRRRRRRRRRRD...",
        "....RRRRRRRRRRRRRRRRD...",
        "...RRRRRRRRRRRRRRRRRRD..",
        "..RRRRRRRRRRRRRRRRRRRRD.",
        ".RRRRRRRRRRRRRRRRRRRRRRD",
        "DDDDDDDDDDDDDDDDDDDDDDDD",
    ], ["R": red, "S": shine, "D": dark])
    c.rect(21, 29, 14, 1, ink)          // the visor: a narrow slit across…
    c.rect(27, 29, 2, 4, ink)           // …and down the middle
    c.rect(18, 35, 20, 1, dark)         // where the robe falls from the shoulders
}

// MARK: - Effects

func drawLightning(_ c: PixelCanvas, from a: (Double, Double), to b: (Double, Double), t: Double) {
    let seed = Int(t * 20)
    for bolt in 0..<2 {
        var prev = a
        let n = 6
        let dx = b.0 - a.0, dy = b.1 - a.1
        let len = max(sqrt(dx * dx + dy * dy), 0.01)
        let nx = -dy / len, ny = dx / len
        for i in 1...n {
            let f = Double(i) / Double(n)
            let off = i == n ? 0 : (noise(seed * 31 + bolt * 7 + i) - 0.5) * 7
            let p = (a.0 + dx * f + nx * off, a.1 + dy * f + ny * off)
            c.glowLine(prev.0, prev.1, p.0, p.1, core: C(0xF4F8FF), glow: C(0x7FB2FF), coreR: 0.5, glowR: 1.8,
                       strength: bolt == 0 ? 1 : 0.6)
            prev = p
        }
    }
}

func drawSparks(_ c: PixelCanvas, x: Double, y: Double, t: Double, size: Double = 3) {
    let seed = Int(t * 30)
    c.glowLine(x, y, x, y, core: white, glow: C(0xFFD25A), coreR: 0.8, glowR: 2.2)
    for i in 0..<6 {
        let a = noise(seed * 13 + i) * 2 * .pi
        let r = 1 + noise(seed * 17 + i) * size
        c.px(Int(x + cos(a) * r), Int(y + sin(a) * r), noise(seed + i) > 0.5 ? white : C(0xFFC23A))
    }
}

/// One side of a fight, in FX-canvas units (leader pixels, y down from the top of a leader canvas).
struct Fighter {
    let weapon: Weapon
    let x: Double                        // body centre
    let k: Double                        // sprite scale relative to a leader (agents are 2/3)
    let top: Double                      // y of this sprite's canvas top
    let side: Double                     // +1 facing right, -1 facing left
    let muzzle: (x: Double, y: Double)   // in its own canvas coordinates
    var armoured = false                 // bolts ricochet off it
    var pivot = Sprite.hand              // where its weapon swings from (`Cast.weaponPivot`), own canvas coordinates

    /// A point given in the sprite's own (right-facing) canvas coordinates.
    func point(_ cx: Double, _ cy: Double) -> (x: Double, y: Double) {
        (x + side * (cx - Sprite.bodyCenterX) * k, top + cy * k)
    }
    var hand: (x: Double, y: Double) { point(pivot.x, pivot.y) }
    var body: (x: Double, y: Double) { point(Sprite.bodyCenterX + 9, 31) }
    /// Where this fighter's blade sits along its length `u` (in its own pixels) at `angle`.
    func blade(_ angle: Double, _ u: Double, dx: Double = 0) -> (x: Double, y: Double) {
        let r = angle * .pi / 180, h = point(pivot.x + dx, pivot.y)
        return (h.x + side * cos(r) * u * k, h.y + sin(r) * u * k)
    }
}

/// One bolt of a blaster-vs-blaster shoot-out, played out per `outcome`. `f` is the shooter's phase in its period.
private func drawShootout(_ c: PixelCanvas, f: Double, t: Double, m: (x: Double, y: Double), me: Fighter, foe: Fighter,
                          outcome: BoltOutcome,
                          bolt: ((x: Double, y: Double), (x: Double, y: Double), Double, Double) -> Void) {
    let arrive = boltArrival
    switch outcome {
    case .hit:
        if f < arrive { bolt(m, foe.body, f / arrive, 1) }
        else if f < arrive + 0.06 { drawSparks(c, x: foe.body.x, y: foe.body.y, t: t, size: 2) }

    case .duck:
        // Aimed at head height; the defender squats (see duckAmount) and it whizzes over, out behind them.
        let head = foe.point(Sprite.bodyCenterX + 4, 21)
        let behind = (x: foe.x - foe.side * 40 * foe.k, y: head.y - 2 * foe.k)
        let total = arrive * 1.6
        if f < total {
            let g = f / total
            let fade = g > 0.8 ? (1 - g) / 0.2 : 1
            bolt(m, behind, g, fade)
        }

    case .collide:
        // The defender fires back at the same moment; the bolts meet in the middle and burst.
        let fm = foe.point(foe.muzzle.x + 2, foe.muzzle.y + 0.5)
        let meet = (x: (m.x + fm.x) / 2, y: (m.y + fm.y) / 2)
        let flight = arrive * 0.55
        if f < flight {
            let g = f / flight
            bolt(m, meet, g, 1)
            bolt(fm, meet, g, 1)
        } else if f < flight + 0.16 {
            let g = (f - flight) / 0.16
            // a bright starburst that grows and fades
            let r = (2 + g * 7) * me.k, a = 1 - g
            for i in 0..<8 {
                let ang = Double(i) * .pi / 4 + g * 0.6
                c.glowLine(meet.x + cos(ang) * r * 0.35, meet.y + sin(ang) * r * 0.35, meet.x + cos(ang) * r, meet.y + sin(ang) * r,
                           core: C(0xFFF4D0).alpha(a), glow: C(0xFF6A2A).alpha(a * 0.8), coreR: 0.5, glowR: 1.6)
            }
            c.glowLine(meet.x, meet.y, meet.x, meet.y, core: C(0xFFFFFF).alpha(a), glow: C(0xFFD25A).alpha(a), coreR: 1.2, glowR: 3.2 * (1 - g * 0.5))
        }

    case .shield:
        // A blue bubble flickers up around the defender and the bolt splashes on it.
        let centre = foe.point(Sprite.bodyCenterX + 1, 31)
        let r = 15 * foe.k
        let front = (x: centre.x + foe.side * r, y: m.y + (centre.y - m.y) * 0.3)
        if f < arrive {
            bolt(m, front, f / arrive, 1)
        } else if f < arrive + 0.3 {
            let g = (f - arrive) / 0.3
            let a = (1 - g) * (0.6 + 0.4 * sin(g * 40))   // flicker
            let n = 22
            for i in 0..<n {
                let a0 = Double(i) / Double(n) * 2 * .pi, a1 = Double(i + 1) / Double(n) * 2 * .pi
                c.glowLine(centre.x + cos(a0) * r, centre.y + sin(a0) * r * 1.05, centre.x + cos(a1) * r, centre.y + sin(a1) * r * 1.05,
                           core: C(0xBFF0FF).alpha(a * 0.9), glow: C(0x3AA8FF).alpha(a * 0.6), coreR: 0.4, glowR: 1.4)
            }
            if g < 0.35 { c.glowLine(front.x, front.y, front.x, front.y, core: C(0xFFFFFF).alpha(1 - g / 0.35),
                                     glow: C(0x3AA8FF).alpha(1 - g / 0.35), coreR: 1, glowR: 3) }
        }

    case .ricochet:
        // Armour: a "tink" of sparks and the bolt glances off up into the sky.
        let impact = foe.point(Sprite.bodyCenterX + 8, 27)
        if f < arrive {
            bolt(m, impact, f / arrive, 1)
        } else if f < arrive + 0.4 {
            let g = (f - arrive) / 0.4
            if g < 0.18 { drawSparks(c, x: impact.x, y: impact.y, t: t, size: 2) }
            let x = impact.x + foe.side * g * 22 * foe.k, y = impact.y - g * 40
            c.glowLine(x, y, x - foe.side * 2.5, y + 4, core: C(0xFFE0E0).alpha(1 - g), glow: C(0xFF2A2A).alpha(1 - g),
                       coreR: 0.6, glowR: 1.8)
        }
    }
}

/// Whether `drawFightFX` has anything to draw at `t`: a saber duel only sparks while the blades clash.
func fightFXVisible(t: Double, _ a: Weapon, _ b: Weapon) -> Bool {
    switch fightRoles(a, b).0 {
    case .duel: return duelPose(t).clash
    case .none: return false
    default: return true
    }
}

/// Bolts, deflections, lightning and clash sparks between two fighters (villains or agents).
func drawFightFX(_ c: PixelCanvas, t: Double, left: Fighter, right: Fighter) {
    let (lRole, rRole) = fightRoles(left.weapon, right.weapon)

    // Saber duel: sparks where the two (mirrored, possibly different-sized) blades cross.
    if case .duel = lRole {
        let p = duelPose(t)
        guard p.clash else { return }
        let r = p.angle * .pi / 180
        let a = left.point(left.pivot.x + p.dx, left.pivot.y), b = right.point(right.pivot.x + p.dx, right.pivot.y)
        let cs = cos(r), sn = sin(r)
        guard cs > 0.2 else { return }
        var s: Double, u: Double
        if abs(sn) < 0.05 {
            s = (b.x - a.x) / cs / 2; u = s
        } else {
            let sum = (b.x - a.x) / cs, diff = (b.y - a.y) / sn
            s = (sum + diff) / 2; u = (sum - diff) / 2
        }
        guard s >= 3 * left.k, s <= 23 * left.k, u >= 3 * right.k, u <= 23 * right.k else { return }
        drawSparks(c, x: a.x + cs * s, y: a.y + sn * s, t: t)
        return
    }

    for (me, role, foe, foeRole) in [(left, lRole, right, rRole), (right, rRole, left, lRole)] {
        switch role {
        case .shoot(let offset):
            let f = frac((t + offset) / blasterPeriod)
            let m = me.point(me.muzzle.x + 2, me.muzzle.y + 0.5)
            func bolt(from a: (x: Double, y: Double), to b: (x: Double, y: Double), _ g: Double, alpha: Double = 1) {
                let x = a.x + (b.x - a.x) * g, y = a.y + (b.y - a.y) * g
                let len = hypot(b.x - a.x, b.y - a.y)
                let ux = (b.x - a.x) / max(len, 0.01), uy = (b.y - a.y) / max(len, 0.01)
                c.glowLine(x - ux * 5, y - uy * 5, x, y, core: C(0xFFE0E0).alpha(alpha), glow: C(0xFF2A2A).alpha(alpha),
                           coreR: 0.6, glowR: 1.8)
            }
            if case .shoot = foeRole {
                drawShootout(c, f: f, t: t, m: m, me: me, foe: foe,
                             outcome: boltOutcome(t: t, offset: offset, defenderArmoured: foe.armoured), bolt: bolt)
                continue
            }
            var impact = foe.body
            var deflects = false
            if case .deflect = foeRole {
                // Where the defender's blade sits at the peak of its swing; the bolt is aimed there.
                let pr = deflectPeak * .pi / 180
                let u = min(max((m.y - foe.hand.y) / sin(pr) / foe.k, 4), 20)
                impact = foe.blade(deflectPeak, u)
                deflects = true
            }
            if f < boltArrival {
                bolt(from: m, to: impact, f / boltArrival)
            } else if f < boltArrival + 0.06 {
                drawSparks(c, x: impact.x, y: impact.y, t: t, size: 2)
            }
            if deflects && f >= boltArrival && f < boltArrival + 0.35 {
                // Bounced bolt flies off up and back over the shooter's head.
                let g = (f - boltArrival) / 0.35
                let x = impact.x - foe.side * -g * 30, yy = impact.y - g * 34
                c.glowLine(x, yy, x - foe.side * 3, yy + 3.4,
                           core: C(0xFFE0E0).alpha(1 - g), glow: C(0xFF2A2A).alpha(1 - g), coreR: 0.6, glowR: 1.8)
            }
        case .zap:
            let h = me.hand
            let from = (h.x, h.y - 2 * me.k)
            let to: (x: Double, y: Double)
            switch foeRole {
            case .block: to = foe.blade(-60, 13)
            case .zap: to = ((me.x + foe.x) / 2, h.y - 4)
            default: to = foe.body
            }
            drawLightning(c, from: from, to: (to.x, to.y), t: t + me.side)
            drawSparks(c, x: to.x, y: to.y, t: t + me.side, size: 2.5)
        default:
            break
        }
    }
}

// MARK: - Speech bubbles (drawn separately so they can flip to whichever side has room)

enum Bubble { static let width = 18, height = 13 }

/// What a Claude's bubble says. There's never real text: dots, "!", "?" or zZz.
enum BubbleKind {
    case thinking
    case waiting        // needs your attention
    case unknown        // session without hooks: we can't tell what it's doing
    case sleeping       // idle for a long time
}

/// Compact bubble — it only ever holds three thinking dots, a "!", a "?" or zZz.
/// `tailRight`: the bubble sits left of the head, so its tail points right. Only the frame is
/// mirrored for that — the symbol inside never reads backwards.
func drawBubble(_ c: PixelCanvas, kind: BubbleKind, t: Double, urgent: Bool = false, tailRight: Bool = false) {
    let border: Px
    switch kind {
    case .waiting: border = sin(t * (urgent ? 14 : 6)) > 0 ? C(0xE0303A) : C(0xFF6A6A)
    case .unknown: border = C(0xC98A1A)
    case .sleeping: border = C(0x6A5ACD)
    case .thinking: border = outline
    }
    c.rect(5, 1, 11, 7, white)
    c.rect(4, 2, 13, 5, white)
    c.rect(5, 0, 11, 1, border); c.rect(5, 8, 11, 1, border)
    c.rect(3, 2, 1, 5, border); c.rect(17, 2, 1, 5, border)
    c.px(4, 1, border); c.px(16, 1, border); c.px(4, 7, border); c.px(16, 7, border)
    c.rect(1, 10, 2, 2, white); c.px(1, 10, border)
    c.px(0, 12, border)
    if tailRight { c.flipHorizontally(); c.ox = -3 }   // box moved from x 3...17 to 0...14
    defer { c.ox = 0 }
    switch kind {
    case .waiting:
        c.rect(9, 2, 2, 3, border)
        c.rect(9, 6, 2, 1, border)
    case .unknown:
        c.pattern(8, 2, ["XXX", "..X", ".X.", "...", ".X."], ["X": border])
    case .sleeping:
        // zZz, drifting gently
        let off = Int(t * 1.5) % 2
        c.pattern(5, 3 + off, ["ZZ", ".Z", "ZZ"], ["Z": border.alpha(0.6)])
        c.pattern(8, 2, ["ZZZ", ".Z.", "ZZZ"], ["Z": border])
        c.pattern(12, 4 - off, ["ZZ", ".Z", "ZZ"], ["Z": border.alpha(0.6)])
    case .thinking:
        let step = Int(t * 3) % 4
        for i in 0..<3 where step > i { c.rect(6 + i * 3, 3, 2, 2, border) }
    }
}

/// Bobbing marker over the Claude whose terminal you're in right now.
func drawFocusCaret(_ c: PixelCanvas) {
    c.pattern(0, 0, [".Y.", "YYY", ".Y."], ["Y": C(0xFFE14A)])
}
