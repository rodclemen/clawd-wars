import Foundation

// The second wave of the cast, on the same 72×52 Clawd layout as everyone else (see Characters.swift): heroes drawn
// whole like the companions there, villains as costumes `drawLeader` dresses (it handles their poses and weapons).

// MARK: - Shared

/// A hero's step and bob while it stands about or walks, and its hop while cheering.
private func heroBob(_ t: Double, _ walking: Bool, role: FightRole, rate: Double = 4.5) -> (step: Int, bob: Int) {
    let step = walkStep(t, walking)
    var bob = walking ? (step == 0 ? -1 : 0) : (sin(t * rate) > 0.6 ? -1 : 0)
    if case .cheer = role, !walking { bob = cheerHop(t) }
    return (step, bob)
}

/// A gown or robe from `top` to the floor, widening to the hem (drawn instead of legs).
private func drawSkirt(_ c: PixelCanvas, from top: Int = 38, _ main: Px, _ edge: Px) {
    for y in top...43 {
        let k = (y - top) / 2
        c.rect(18 - k, y, 20 + k * 2, 1, main)
        c.px(18 - k, y, edge); c.px(37 + k, y, edge)
    }
}

/// A small blaster pistol in the right hand; its muzzle is at (x + 7, y + 1).
func drawPistol(_ c: PixelCanvas, x: Int, y: Int, body: Px = C(0x2A2A30), trim: Px = C(0x8A8F9C)) {
    c.pattern(x, y, ["KKKKKKK", "KKTKKK.", "KK.....", "KK....."], ["K": body, "T": trim])
}

/// Firing (or lowered) pistol for a blaster hero, after its body: recoil and shake as `agentFire` says.
private func heroPistol(_ c: PixelCanvas, _ who: Companion, t: Double, walking: Bool, role: FightRole, bob: Int,
                        period: Double, phase: Double, draw: (PixelCanvas) -> Void) {
    let (recoil, shake) = agentFire(c, t: t, walking: walking, role: role, period: period, phase: phase,
                                    muzzleX: Int(who.muzzle.x))
    c.oy = bob - recoil
    c.ox = shake
    draw(c)
}

/// A Mandalorian helmet: the T visor, and on Bo-Katan the Nite Owl markings either side of it.
private func drawMandoHelmet(_ c: PixelCanvas, _ main: Px, _ shine: Px, marks: Px? = nil) {
    c.pattern(17, 19, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHhhHHHHHHHHHHHHHH..",
        ".HHhHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHMMMHHHHHHHHHHHHMMMHH",
        "HHHMMKKKKKKKKKKKKMMHHH",
        "HHHHHKKKKKKKKKKKKHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        "HHHHHHHHHKKKKHHHHHHHHH",
        ".HHHHHHHHKKKKHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHH..",
    ], ["H": main, "h": shine, "K": ink, "M": marks ?? main])
}

// MARK: - Heroes

/// Jar Jar Binks: a Gungan, all ears and eyestalks, arms everywhere. Unarmed (mesa no fight).
func drawJarJar(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 6)
    let skin = C(0xD9935A), skinDark = C(0xB0703C), cloth = C(0x6E5A3A), clothDark = C(0x54442A)
    let flail = Int(t * 5) % 2
    let look = Look(body: skin, shade: skinDark, leg: cloth, arm: skin, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    // Long ears hanging down both sides, under the arms.
    let ear = ["EE..", "EEE.", ".EE.", ".EEE", "..EE", "..EE", "..EE", "..EE", ".EEE", ".EEE", "EEE.", "EE..", "E..."]
    c.pattern(13, 26, ear, ["E": skinDark])
    c.pattern(39, 26, ear.map { String($0.reversed()) }, ["E": skinDark])
    drawBody(c, look, armLeft: flail == 0 ? 3 : 0, armRight: flail == 0 ? 0 : 3)
    // Eyes up on stalks, wobbling.
    let wob = sin(t * 7) > 0 ? 1 : 0
    c.rect(23, 21, 1, 5, skin); c.rect(32, 21, 1, 5, skin)
    for ex in [21 + wob, 30 + wob] {
        c.pattern(ex, 18, [".WWW.", "WWWkW", ".WWW."], ["W": C(0xF2E8C8), "k": ink])
    }
    c.rect(35, 30, 6, 3, skin)                  // the duck bill
    c.rect(36, 32, 5, 1, skinDark)
    c.rect(18, 34, 20, 4, cloth)
    c.rect(18, 34, 20, 1, clothDark)
}

/// Lando Calrissian: neat moustache, sky-blue shirt and a cape lined in gold.
func drawLando(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let shirt = C(0x8FB4D9), hair = C(0x1E1612)
    c.oy = bob
    drawCape(c, t: t, speed: 1.4, color: C(0x24305A), edge: C(0xE0B84A))
    c.oy = 0
    let look = Look(leg: C(0x2A2E44), arm: shirt)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH................HH",
    ], ["H": hair])
    c.rect(24, 32, 8, 1, hair)                  // the moustache
    c.rect(18, 34, 20, 4, shirt)
    c.rect(18, 36, 20, 1, C(0x3A2A1C))
    heroPistol(c, .lando, t: t, walking: walking, role: role, bob: bob, period: 1.0, phase: 0.3) { drawPistol($0, x: 40, y: 31) }
}

/// Zorii Bliss: the bronze helmet with its dark visor and an orange glint, maroon flight suit.
func drawZorii(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let suit = C(0x5A2A3A)
    let look = Look(body: suit, shade: C(0x44202C), leg: C(0x3A2A30), arm: suit, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(17, 19, [
        ".....BBBBBBBBBBBB.....",
        "...BBBBBBBBBBBBBBBB...",
        "..BBhhBBBBBBBBBBBBBB..",
        ".BBhBBBBBBBBBBBBBBBBB.",
        ".BBBBBBBBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        "BBVVVVVVVVVVVVVVVVVVBB",
        "BBvvvvvvvvvvvvvvvvvvBB",
        "BBBBBBBBBBBBBBBBBBBBBB",
        ".BBBBBBBBGGGGBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBBB..",
    ], ["B": C(0xB8923E), "h": C(0xE8C870), "V": C(0x1A1410), "v": C(0xD86A2A), "G": C(0x5A4420)])
    c.rect(18, 36, 20, 1, C(0x2A1A1E))
    heroPistol(c, .zorii, t: t, walking: walking, role: role, bob: bob, period: 0.85, phase: 0.6) { drawPistol($0, x: 40, y: 31) }
}

/// Bo-Katan Kryze: blue Mandalorian armour, the Nite Owl helmet, a blaster in hand.
func drawBoKatan(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let blue = C(0x4A6EA8), suit = C(0x3A3E48)
    let look = Look(body: suit, shade: C(0x2C2F38), leg: C(0x2C2F38), arm: blue, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    drawMandoHelmet(c, C(0x5A7AB0), C(0x9AB4E0), marks: C(0x24345A))
    c.rect(19, 33, 18, 3, blue)                 // chest plate
    c.rect(19, 33, 18, 1, C(0x7A9AD0))
    c.rect(18, 36, 20, 1, C(0x5A4A3A))
    heroPistol(c, .boKatan, t: t, walking: walking, role: role, bob: bob, period: 0.8, phase: 0.1) { drawPistol($0, x: 40, y: 31) }
}

/// Maz Kanata: small and orange, with the big round goggles that see right through you.
func drawMaz(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 3)
    let skin = C(0xD98E4A), skinDark = C(0xB06E34)
    let look = Look(body: skin, shade: skinDark, leg: C(0x5A4430), arm: skin, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(18, 22, [
        "...WWWWWWWWWWWWWW...",
        ".WWWWwWWWWWWWWwWWWW.",
        "WWWWWWWWWWWWWWWWWWWW",
    ], ["W": C(0x6A4A32), "w": C(0x8A6A4A)])
    // The goggles: brass rims, dark lenses, eyes swimming behind them (they focus now and then).
    let focus = sin(t * 0.9) > 0.85
    for ex in [23, 33] {
        c.circle(ex, 30, 3, C(0x8A6A3A))
        c.circle(ex, 30, 2, C(0x2A3A4A))
        c.rect(ex, 30, focus ? 1 : 2, focus ? 1 : 2, C(0x1A1008))
        c.px(ex - 1, 29, C(0xBFE0F0))
    }
    c.rect(26, 30, 4, 1, C(0x8A6A3A))
    c.rect(18, 34, 20, 4, C(0x8A6A4A))
    c.rect(22, 34, 12, 1, C(0xD8B040))           // beads
}

/// Wedge Antilles: an X-wing pilot, orange flight suit and white helmet with red flashes.
func drawWedge(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let suit = C(0xE0782A), white = C(0xEDEDED)
    let look = Look(leg: suit, arm: suit)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(17, 19, [
        ".....WWWWWWWWWWWW.....",
        "...WWWWWWWWWWWWWWWW...",
        "..WWRRRWWWWWWWWRRRWW..",
        ".WWWWWWWWWWWWWWWWWWWW.",
        ".WWWWWWWWWWWWWWWWWWWW.",
        "WWGGGGGGGGGGGGGGGGGGWW",
        "WW..................WW",
        "WW..................WW",
        "W....................W",
    ], ["W": white, "R": C(0xD84A2A), "G": C(0x5A5A64)])
    c.rect(18, 33, 20, 5, suit)
    c.rect(21, 33, 2, 5, white); c.rect(33, 33, 2, 5, white)    // harness
    c.rect(18, 35, 20, 1, white)
    c.rect(25, 33, 6, 2, C(0x6A6E78))                           // chest box
    heroPistol(c, .wedge, t: t, walking: walking, role: role, bob: bob, period: 0.9, phase: 0.45) { drawPistol($0, x: 40, y: 31) }
}

/// L3-37: Lando's self-made droid, patched together from parts, fist up for droid rights.
func drawL337(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 3.5)
    let tan = C(0xCBB89A), tanDark = C(0x9E8C70), grey = C(0x5A5C64)
    let protest = !walking && Int(t * 0.8) % 2 == 0
    let look = Look(body: tan, shade: tanDark, leg: grey, arm: grey, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look, armRight: protest ? 6 : 0)
    c.rect(18, 30, 20, 1, tanDark)
    c.rect(20, 32, 5, 4, C(0xB06A3A))           // a rusty patch
    c.rect(30, 33, 4, 3, C(0x7A7E88))
    c.rect(24, 24, 2, 2, grey); c.rect(30, 24, 2, 2, grey)     // neck struts
    c.pattern(21, 16, [
        "...TTTTTTTT...",
        ".TTTTTTTTTTTT.",
        "TTTTTTTTTTTTTT",
        "TTTTTTTTTBBBTT",
        "TTTTTTTTBbbbBT",
        "TTTTTTTTBbbbBT",
        "TTTTTTTTTBBBTT",
        ".TTTTTTTTTTTT.",
    ], ["T": C(0xE8DCC4), "B": C(0x3A3A44), "b": C(0x6FC8FF)])
}

/// Mon Mothma: white robes to the floor, short auburn hair, a silver medallion.
func drawMonMothma(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (_, bob) = heroBob(t, walking, role: role, rate: 2.5)
    let robe = C(0xF0EEE6), robeShade = C(0xD2D0C8)
    c.oy = bob
    drawSkirt(c, robe, robeShade)
    var look = Look(arm: robe)
    look.legs = false
    drawBody(c, look)
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHH..............HHH",
        "HH................HH",
    ], ["H": C(0x9A5A30)])
    c.rect(18, 33, 20, 5, robe)
    c.rect(37, 33, 1, 5, robeShade)
    c.rect(26, 34, 4, 2, C(0xC8CCD4))
}

/// Padmé Amidala, as at Geonosis: white suit, dark hair in a bun, a pistol.
func drawPadme(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let suit = C(0xF2F0EA), hair = C(0x4A2A1A)
    let look = Look(leg: suit, arm: suit)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(18, 22, ["...HHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHH", "HH..............HH"], ["H": hair])
    c.pattern(13, 22, [".HHH.", "HHHHH", "HHHHH", ".HHH."], ["H": hair])      // the bun at the back
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, C(0xD4D2CC))
    c.rect(18, 36, 20, 1, C(0x6A5A4A))
    heroPistol(c, .padme, t: t, walking: walking, role: role, bob: bob, period: 1.1, phase: 0.2) { drawPistol($0, x: 40, y: 31) }
}

/// Admiral Ackbar: a Mon Calamari, salmon dome and big side eyes, in his white admiral's uniform.
func drawAckbar(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 3)
    let skin = C(0xC9724A), shade = C(0xA0583A), uniform = C(0xEDECE6)
    let look = Look(body: skin, shade: shade, leg: C(0xD8D6CE), arm: uniform, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(17, 17, [
        ".......SSSSSSSS.......",
        ".....SSSSSSSSSSSS.....",
        "....SSSSSSSSSSSSSS....",
        "...SSSSsSSSSSSSSSSS...",
        "...SSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSSSSSS.",
        ".SSSSSSSSSSSSSSSSSSSS.",
    ], ["S": skin, "s": C(0xE0946A)])
    let look2 = sin(t * 1.3) > 0.7 ? 1 : 2                     // the eyes swivel
    for ex in [15, 36] {
        c.pattern(ex, 25, [".EEE.", "EEEEE", "EEEEE", "EEEEE", ".EEE."], ["E": C(0xE0962E)])
        c.px(ex + look2 + 1, 27, C(0x2A1A10))
    }
    c.rect(24, 31, 8, 1, shade)                 // whiskers
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, C(0xC8C6BE))
    c.px(21, 35, C(0xD84A2A)); c.px(22, 35, C(0x3A6ED8)); c.px(23, 35, C(0xE0B84A))
}

/// Grogu: very small, very green, enormous ears, a beige robe. Lifts a hand to the Force now and then.
func drawGrogu(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (_, bob) = heroBob(t, walking, role: role, rate: 3)
    let green = C(0x9BBF78), ear = C(0x8DB06A), inner = C(0xC98F7A), robe = C(0xC8AE80), robeDark = C(0xA08A60)
    c.oy = bob
    for y in 34...43 {
        let k = (y - 34) / 3
        c.rect(20 - k, y, 16 + k * 2, 1, robe)
        c.px(20 - k, y, robeDark); c.px(35 + k, y, robeDark)
    }
    c.rect(21, 34, 14, 1, robeDark)
    c.pattern(8, 24, ["EE...........", "EEEEE........", ".EEEEEEEEE...", "..EEeeeeEEEEE", "....EEEEEEEEE"], ["E": ear, "e": inner])
    c.pattern(35, 24, ["...........EE", "........EEEEE", "...EEEEEEEEE.", "EEEEEeeeeEE..", "EEEEEEEEE...."], ["E": ear, "e": inner])
    c.pattern(21, 23, [
        "....GGGGGGG....",
        "..GGGGGGGGGGG..",
        ".GGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGKKKGGGGKKKGG",
        "GGGKKWGGGGKKWGG",
        "GGGKKKGGGGKKKGG",
        "GGGGGGGGGGGGGGG",
        ".GGGGGGddGGGGG.",
        "..GGGGGGGGGGG..",
    ], ["G": green, "K": ink, "W": white, "d": C(0x7A9A5A)])
    // The Force: a little hand up, and a shimmer in front of it.
    let force = !walking && sin(t * 0.7) > 0.5
    c.rect(36, force ? 31 : 36, 2, 2, green)
    if force {
        let f = (t * 2).truncatingRemainder(dividingBy: 1)
        c.px(40 + Int(f * 4), 30, C(0xBFE0FF).alpha(1 - f)); c.px(41 + Int(f * 3), 32, C(0xFFFFFF).alpha(1 - f))
    }
}

/// Babu Frik: a tiny Anzellan droidsmith, mostly head (wrinkled, a white tuft, a bulbous nose), his loupe of
/// lenses out in front of one eye, standing on a crate to reach the work, sparks flying from his tool. Hey hey!
func drawBabuFrik(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (_, bob) = heroBob(t, walking, role: role, rate: 5)
    let skin = C(0xE2B49A), wrinkle = C(0xC0907A), nose = C(0xD49480), hair = C(0xF2F2F2)
    let coat = C(0x4A2E22), wood = C(0x8A6238), woodDark = C(0x6A4A2A), brass = C(0x9A7A3A)
    // The crate he stands on.
    c.rect(17, 37, 22, 7, wood)
    c.rect(17, 37, 22, 1, C(0xA87A48))
    c.rect(17, 40, 22, 1, woodDark)
    c.rect(17, 37, 1, 7, woodDark); c.rect(38, 37, 1, 7, woodDark); c.rect(27, 38, 1, 6, woodDark)
    c.oy = bob
    // A very small body in a dark coat, little feet.
    c.rect(24, 35, 2, 2, coat); c.rect(30, 35, 2, 2, coat)
    c.rect(23, 31, 11, 5, coat)
    c.rect(23, 31, 11, 1, C(0x6A4434))
    // The head.
    c.pattern(20, 16, [
        ".....H..H.H.....",
        "....HHHHHHHH....",
        "...HHHHHHHHHH...",
        "..SSSSSSSSSSSS..",
        ".SSSwSSSSSSwSSS.",
        ".SSSSSSSSSSSSSSS",
        "SSSwwSSSSSSwwSSS",
        "GGGGGGGGGGGGGGGG",
        "SSSSKSSSSSSSSSSS",
        "SSSSSSSSSSSSNNNS",
        "SSSSSSSSSSSNNNNS",
        ".SSSSSSSSSSSNNS.",
        ".SSSSMMMMSSSSSS.",
        "..SSSSSSSSSSSS..",
        "....SSSSSSSS....",
    ], ["H": hair, "S": skin, "w": wrinkle, "N": nose, "G": C(0x3A2A22), "K": ink, "M": C(0x8A4A3A)])
    // The loupe: lenses on an arm out in front of his near eye, the big one wobbling as he peers.
    let peer = sin(t * 2.2) > 0.3 ? 1 : 0
    c.rect(35, 23, 3, 1, brass)
    c.circle(37, 24, 2, brass); c.circle(37, 24, 1, C(0x8FD8FF))
    c.circle(41 + peer, 24, 3, brass); c.circle(41 + peer, 24, 2, C(0xBFEFFF)); c.px(41 + peer, 24, ink)
    c.circle(36, 20, 1, brass)                                             // a spare lens flipped up
    // His hand and tool, and the sparks.
    c.rect(34, 32, 3, 2, skin)
    c.rect(37, 32, 4, 1, C(0x9AA0AE))
    if !walking, (t / 1.5).truncatingRemainder(dividingBy: 1) < 0.3 { drawSparks(c, x: 41.5, y: 32.5, t: t, size: 2) }
}

/// The Mandalorian: beskar helmet and armour, a brown cape, the long Amban rifle.
func drawMando(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 3.5)
    let beskar = C(0xC9CDD6), suit = C(0x6A6252)
    c.oy = bob
    drawCape(c, t: t, speed: 1.2, color: C(0x5A4430), edge: C(0x3E2E20))
    c.oy = 0
    let look = Look(body: suit, shade: C(0x4E4838), leg: C(0x5A5446), arm: suit, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    drawMandoHelmet(c, beskar, C(0xF2F4F8))
    c.rect(19, 33, 18, 3, beskar)
    c.rect(19, 33, 18, 1, C(0xE8ECF2))
    c.rect(18, 36, 20, 1, C(0x3A2A1C))
    heroPistol(c, .mando, t: t, walking: walking, role: role, bob: bob, period: 1.25, phase: 0.7) { c in
        c.pattern(38, 31, [
            "...........SS.......",
            "KKKKKKKKKKKKKKKKKKKK",
            "KKWW................",
            "KK..................",
        ], ["K": C(0x2E2A26), "W": C(0x6A4A2A), "S": C(0x8A8F9C)])
    }
}

/// K-2SO: a tall reprogrammed Imperial security droid, black, with a small head and round white eyes.
func drawK2SO(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 2.5)
    let black = C(0x2C2E34)
    let look = Look(body: black, shade: C(0x1E2024), leg: C(0x3A3C44), arm: black, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(19, 14, [
        "...KKKKKKKKKKKK...",
        ".KKKKKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKEEEKKEEE",
        "KKKKKKKKKKEEEKKEEE",
        "KKKKKKKKKKKKKKKKKK",
        ".KKKKKKKKKKKKKKKK.",
        "...KKKKKKKKKKKK...",
        ".......NNNN.......",
        "......NNNNNN......",
        ".....NNNNNNNN.....",
        ".....NNNNNNNN.....",
    ], ["K": black, "E": C(0xDCE4EC), "N": C(0x4A4C54)])
    c.rect(18, 26, 20, 4, black)                // over the face: a droid's body, no eyes
    c.rect(20, 28, 2, 2, C(0xDCE4EC))           // the Imperial mark on the shoulder
    c.rect(18, 33, 20, 1, C(0x4A4C54))
    heroPistol(c, .k2so, t: t, walking: walking, role: role, bob: bob, period: 1.05, phase: 0.85) { drawE11($0, x: 37, y: 30) }
}

/// A GNK power droid: a walking battery box on stubby feet. Gonk.
func drawGonk(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let step = Int(t * (walking ? 8 : 2)) % 2
    var hop = 0
    if case .cheer = role, !walking { hop = cheerHop(t) }
    let body = C(0x8C8A78), dark = C(0x5A5848), light = C(0xAEAC98)
    c.ox = step == 0 ? 0 : 1
    c.rect(20, 38 + (step == 0 ? 0 : 1), 4, 6 - (step == 0 ? 0 : 1), dark)
    c.rect(32, 38 + (step == 1 ? 0 : 1), 4, 6 - (step == 1 ? 0 : 1), dark)
    c.oy = hop
    c.rect(17, 23, 22, 16, body)
    c.rect(17, 23, 22, 2, light)
    c.rect(36, 23, 3, 16, dark)
    c.rect(17, 30, 22, 2, dark)
    c.rect(20, 34, 6, 3, dark); c.rect(28, 34, 6, 3, dark)
    c.px(21, 27, Int(t * 2) % 2 == 0 ? C(0xFF4A3A) : C(0x7A2A20))
    c.px(23, 27, C(0x4AD86A))
}

// MARK: - Villains

/// Sebulba in his pod racer: two big orange engines out front, the cockpit tub behind, hovering. The flame jet
/// he used on Anakin is its weapon (fired from the front of the near engine).
func drawSebulbaPod(_ c: PixelCanvas, t: Double, lift: Int) {
    let base = c.oy
    c.rect(10, 43, 58, 1, C(0x000000).alpha(0.22))                   // its shadow on the ground
    c.oy = base + Int((sin(t * 3) * 1.2).rounded()) - 2
    let orange = C(0xD86A1E), orangeDark = C(0xA84E14), metal = C(0x8A8F99), dark = C(0x2E2E34)
    // The far engine, up and behind, and the energy binder between the two.
    c.rect(42, 19, 24, 6, orangeDark)
    c.rect(64, 19, 3, 6, dark)
    let binder = Int(t * 12) % 2 == 0 ? C(0x9FD8FF) : C(0x6FB8FF)
    c.rect(52, 25, 1, 3, binder); c.rect(58, 25, 1, 3, binder)
    // The near engine.
    c.rect(38, 27, 30, 8, orange)
    c.rect(38, 33, 30, 2, orangeDark)
    c.rect(38, 28, 30, 1, C(0xF0904A))
    c.rect(66, 27, 3, 8, metal); c.rect(68, 28, 2, 6, dark)          // the intake
    c.rect(42, 24, 6, 3, orangeDark)                                 // its fin
    c.rect(54, 35, 4, 2, orangeDark)
    if Int(t * 15) % 2 == 0 { c.rect(35, 29, 3, 4, C(0xFF9A2A)) } else { c.rect(36, 30, 2, 2, C(0xFFE27A)) }
    // Control cables back to the cockpit.
    c.glowLine(38, 31, 30, 32, core: metal, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    c.glowLine(42, 23, 30, 30, core: metal, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    // Sebulba, a Dug, up in the cockpit: leather cap, small eyes, the big mouth.
    c.oy += lift
    c.pattern(15, 21, [
        "...LLLLLL...",
        ".LLLLLLLLLL.",
        "LSSSSSSSSSSL",
        "SSSSSSKSSSKS",
        "SSSSSSSSSSSS",
        "SSSSSMMMMMMS",
        "SSSSSSSSSSSS",
        ".SSSSSSSSSS.",
    ], ["L": C(0x5A3A22), "S": C(0xB89068), "K": ink, "M": C(0x5A2A1A)])
    c.rect(26, 28, 3, 2, C(0xB89068))                                // a hand on the controls
    c.oy -= lift
    // The cockpit tub.
    c.pattern(8, 28, [
        "......OOOOOOOOOOOOOOOOOO",
        "...OOOOOOOOOOOOOOOOOOOOO",
        ".OOOOOOOOOOOOOOOOOOOOOOO",
        "OOOOOOOOOOOOOOOOOOOOOOOO",
        "OOOOOoOOOOOOOOOOOOoOOOOO",
        "oOOOOOOOOOOOOOOOOOOOOOOo",
        ".oooOOOOOOOOOOOOOOOOOoo.",
        "...ooooooooooooooooooo..",
    ], ["O": orange, "o": orangeDark])
    c.rect(14, 31, 12, 1, dark)
    c.oy = base
}

/// Salacious B. Crumb: Jabba's cackling Kowakian monkey-lizard, ears out wide and a long tail.
func drawSalacious(_ c: PixelCanvas, t: Double, lift: Int) {
    let skin = C(0xC8A070), dark = C(0x9A7448)
    let laugh = sin(t * 11) > 0
    let base = c.oy
    c.rect(24, 38, 2, 5, dark); c.rect(31, 38, 2, 5, dark)
    c.rect(23, 43, 4, 1, dark); c.rect(30, 43, 4, 1, dark)
    c.glowLine(22, 36, 12, Double(30 + (laugh ? 1 : 0)), core: dark, glow: C(0, 0), coreR: 0.6, glowR: 0.7)   // tail
    c.oy = base + lift + (laugh ? -1 : 0)
    c.rect(22, 29, 13, 10, skin)
    c.rect(22, 37, 13, 1, dark)
    c.rect(35, 31, 3, 2, skin)                                       // a little arm, slapping a knee
    c.pattern(18, 18, [
        "EEE................EEE",
        "EEEE..............EEEE",
        ".EEEE..SSSSSSSS..EEEE.",
        "..EEEESSSSSSSSSSEEEE..",
        "...EEESSSSSSSSSSSEE...",
        "......SSSSSSSSSSSS....",
        "......SSSKSSSSKSSS....",
        "......SSSSSSSSSSSSNNN.",
        "......SSSSSSSSSSSSNN..",
        laugh ? "......SSMMMMMMSSSS...." : "......SSSMMMMSSSSS....",
        ".......SSSSSSSSSS.....",
    ], ["E": dark, "S": skin, "K": ink, "N": dark, "M": C(0x5A1A1A)])
    c.px(27, 17, dark); c.px(29, 16, dark)                          // a tuft
    c.oy = base
}

/// General Grievous: a white bone mask with yellow eyes over a grey cyborg body (his four sabers are his weapon).
func drawGrievous(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let metal = C(0x9AA0A8), metalDark = C(0x6E747C)
    drawLegs(c, Look(leg: metalDark), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: metal, shade: metalDark, arm: metal, eye: nil))
    c.rect(13, 31, 3, 3, metal)                                      // the second pair of arms
    c.rect(38, 30, 3, 3, metalDark)
    c.rect(22, 31, 12, 5, C(0x5A4A3A))                               // the organ sack
    c.rect(22, 31, 12, 1, metalDark)
    c.pattern(18, 14, [
        "......BBBBBBBB......",
        "....BBBBBBBBBBBB....",
        "...BBBBBBBBBBBBBBB..",
        "..BBBBBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBB.",
        "...BBBBBBBBBBBBBBB..",
        "...BBbbbBBBBBbbbBB..",
        "...BBbYbBBBBBbYbBB..",
        "....BBBBBBBBBBBBB...",
        ".....BBBdBdBdBBB....",
        ".....BBBBBBBBBBB....",
        "......BBBBBBBBB.....",
    ], ["B": C(0xEDE6D2), "b": C(0x2A2418), "Y": C(0xF0D040), "d": C(0x8A8270)])
}

/// The Tusken Raider's gaffi stick: a metal-capped club, flared at the head.
func drawGaffi(_ c: PixelCanvas, angle: Double) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), px = -uy, py = ux
    c.glowLine(hx - ux * 6, hy - uy * 6, hx + ux * 17, hy + uy * 17, core: C(0x8A7458), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    for s in [-1.0, 1.0] {
        c.glowLine(hx + ux * 15, hy + uy * 15, hx + ux * 18 + px * 3 * s, hy + uy * 18 + py * 3 * s,
                   core: C(0xA9AEB8), glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    }
    c.glowLine(hx - ux * 6, hy - uy * 6, hx - ux * 8, hy - uy * 8, core: C(0xA9AEB8), glow: C(0, 0), coreR: 0.8, glowR: 0.9)
}

/// A Tusken Raider: sand-coloured wrappings, goggle tubes, the breath mask. Always angry.
func drawTusken(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let wrap = C(0xC8B48A), wrapDark = C(0xA08A64), robe = C(0x7A5A3A), metal = C(0x7A7E88)
    drawLegs(c, Look(leg: wrapDark), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: wrap, shade: wrapDark, arm: wrap, eye: nil))
    c.pattern(17, 19, [
        ".....WWWWWWWWWWWW.....",
        "...WWWWwWWWWWWwWWWW...",
        "..WWWWWWWWWWWWWWWWWW..",
        ".WWwWWWWWWWWWWWWWwWWW.",
        ".WWWWWWWWWWWWWWWWWWWW.",
        "WWWWWwWWWWWWWWWwWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWWW",
    ], ["W": wrap, "w": wrapDark])
    for x in [19, 24, 33] { c.rect(x, 27, 1, 5, wrapDark) }         // the wrappings
    for ex in [22, 31] {                                              // goggle tubes
        c.rect(ex, 28, 4, 3, metal)
        c.rect(ex + 1, 29, 2, 1, ink)
    }
    c.rect(26, 32, 4, 2, metal)                                       // breath mask
    c.px(25, 33, metal); c.px(30, 33, metal)
    c.rect(18, 34, 20, 4, robe)
    for i in 0..<9 { c.px(19 + i * 2, 34 + i / 3, C(0x4A3420)) }     // a strap across
}

/// Cad Bane: wide-brimmed hat, blue Duros skin and red eyes, the high-collared coat; twin blasters.
func drawCadBane(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0x5A8A9A), coat = C(0x6A4A32), coatDark = C(0x4A3222), hat = C(0x7A5A3A)
    drawLegs(c, Look(leg: C(0x3A3A40)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: C(0x467080), arm: coat, eye: nil))
    c.rect(19, 23, 18, 3, skin)
    c.pattern(10, 15, [
        "...........HHHHHHHHHHHHHH...........",
        "...........HHHHHHHHHHHHHH...........",
        "...........HHHHHHHHHHHHHH...........",
        "...........hhhhhhhhhhhhhh...........",
        "..BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB..",
        "....BBBBBBBBBBBBBBBBBBBBBBBBBBBB....",
    ], ["H": hat, "h": C(0x3A2A1A), "B": C(0x5A4028)])
    c.rect(22, 28, 3, 2, C(0xE0302A)); c.rect(31, 28, 3, 2, C(0xE0302A))
    c.rect(35, 30, 2, 3, C(0x8A8F99))                                 // breathing tube
    c.rect(18, 31, 20, 2, coatDark)                                   // the high collar
    c.rect(18, 33, 20, 5, coat)
    c.rect(18, 36, 20, 1, coatDark)
}

/// Grand Admiral Thrawn: blue skin, glowing red eyes, slicked black hair, the white uniform.
func drawThrawn(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let uniform = C(0xF2F2EC), shade = C(0xC8C8C0)
    drawLegs(c, Look(leg: C(0xE0E0D8)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: C(0x4A6AC0), shade: C(0x3A56A0), arm: uniform, eye: C(0xFF3A3A)))
    c.pattern(18, 22, ["...KKKKKKKKKKKKKK...", ".KKKKKKKKKKKKKKKKKK.", "KKKKKKKKKKKKKKKKKKKK", "KK................KK"], ["K": C(0x14141C)])
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, shade)
    c.rect(37, 33, 1, 5, shade)
    c.px(21, 35, C(0xD84A2A)); c.px(22, 35, C(0x3A6ED8)); c.px(23, 35, C(0xE0B84A))   // rank plaque
    c.rect(15, 32, 3, 1, C(0xE0B84A)); c.rect(38, 32, 3, 1, C(0xE0B84A))               // epaulettes
}

/// Hammerhead (Momaw Nadon, of the cantina): an Ithorian, the long T-shaped head on a tall neck, in robes.
func drawHammerhead(_ c: PixelCanvas, lift: Int) {
    let skin = C(0x8A6A4A), skinDark = C(0x6A4E34), robe = C(0x8A3A2A), robeDark = C(0x6A2A1E)
    drawSkirt(c, from: 36, robe, robeDark)
    c.oy += lift
    var look = Look(body: robe, shade: robeDark, arm: skin, eye: nil)
    look.legs = false
    drawBody(c, look)
    c.pattern(12, 10, [
        ".SSS..........................SSS.",
        "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
        "SWWSSSSSSSSSSSSSSSSSSSSSSSSSSSSWWS",
        "SWESSSSSSSSSSSSSSSSSSSSSSSSSSSSEWS",
        ".sSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSs.",
        "...ssSSSSSSSSSSSSSSSSSSSSSSSSss...",
        ".........SSSSSSSSSSSSSSSS.........",
        "............SSSSSSSSSS............",
        "............SSSSSSSSSs............",
        "............SSSSSSSSSs............",
        "............SSSSSSSSSs............",
        "............SSSSSSSSSs............",
        "............SSSSSSMMSs............",
        "............SSSSSSSSSs............",
        "............SSSSSSSSSs............",
        "............SSSSSSSSSs............",
        "...........SSSSSSSSSSSS...........",
    ], ["S": skin, "s": skinDark, "E": ink, "W": C(0xF0E2B0), "M": skinDark])
    c.rect(18, 33, 20, 1, robeDark)
}

/// An MSE-6 "mouse" droid: a little black box on wheels, scurrying back and forth (only ever an agent).
func drawMouseDroid(_ c: PixelCanvas, t: Double) {
    let run = sin(t * 1.3)
    c.ox += Int((run * 6).rounded())
    let black = C(0x1E1E22)
    c.rect(20, 42, 4, 2, C(0x3A3A42)); c.rect(33, 42, 4, 2, C(0x3A3A42))
    c.rect(18, 36, 22, 6, black)
    c.rect(19, 35, 20, 1, C(0x3A3A42))
    c.rect(22, 37, 6, 2, C(0x6A6E78)); c.rect(30, 37, 6, 2, C(0x6A6E78))
    c.px(39, 38, Int(t * 4) % 2 == 0 ? C(0xFF3A3A) : C(0x7A2A20))
}
