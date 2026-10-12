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
                                    muzzleX: Int(who.muzzle.x), muzzleY: Int(who.muzzle.y))
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

/// Cassian Andor: dark hair, stubble, the navy jacket, a blaster pistol. He keeps glancing over his shoulder.
func drawCassian(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role)
    let jacket = C(0x3A4250), jacketDark = C(0x2A303C), hair = C(0x2A1C14)
    let look = Look(leg: C(0x2E2A26), arm: jacket, eye: nil)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(18, 22, [
        "..HHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHhHHHHHHHHHhHHHHH",
        "HH.H............H.HH",
    ], ["H": hair, "h": C(0x3E2A1E)])
    let glance = !walking && sin(t * 0.8) > 0.75 ? -1 : 0           // a look back, just in case
    c.rect(22 + glance, 29, 2, 3, ink); c.rect(32 + glance, 29, 2, 3, ink)
    for x in stride(from: 21, through: 34, by: 2) { c.px(x, 32, C(0x8A4A34)) }   // stubble
    c.rect(18, 33, 20, 5, jacket)
    c.rect(18, 33, 20, 1, C(0x5A4430))                             // the collar
    c.rect(27, 34, 1, 4, jacketDark)
    c.rect(37, 33, 1, 5, jacketDark)
    heroPistol(c, .cassian, t: t, walking: walking, role: role, bob: bob, period: 0.95, phase: 0.5) { drawPistol($0, x: 40, y: 31) }
}

/// Bix Caleen: the mechanic of Ferrix, dark curls, a work jacket and a tool belt. Unarmed; now and then she lifts
/// her comm to call in.
func drawBix(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 4)
    let coat = C(0x6A5A44), coatDark = C(0x4E4232), hair = C(0x2A1A12)
    let calling = !walking && (t / 7).truncatingRemainder(dividingBy: 1) < 0.45
    let look = Look(leg: C(0x3A3430), arm: coat)
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look, armRight: calling ? 5 : 0)
    c.pattern(16, 19, [
        "....HH.HHHH.HH.HH.....",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHhHHHHhHHHHhHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHhHHHHHHHHHHHHHHhHHHH",
        "HHHH..............HHHH",
        ".HH................HHH",
        ".HH.................HH",
    ], ["H": hair, "h": C(0x4A3020)])
    c.rect(18, 33, 20, 5, coat)
    c.rect(37, 33, 1, 5, coatDark)
    c.rect(18, 36, 20, 1, C(0x3A2A1E))                             // tool belt…
    c.rect(21, 37, 2, 1, C(0x9AA0AE)); c.rect(32, 37, 3, 1, C(0x9AA0AE))
    if calling {                                                   // …and the comm, its light blinking
        c.rect(39, 26, 2, 4, C(0x2A2A30))
        c.px(39, 26, Int(t * 4) % 2 == 0 ? C(0x4AD86A) : C(0x1E5A2A))
        let f = (t * 1.5).truncatingRemainder(dividingBy: 1)
        c.px(42 + Int(f * 3), 24 - Int(f * 2), C(0xBFE0FF).alpha(1 - f))
        c.px(43 + Int(f * 3), 26 - Int(f * 2), C(0xBFE0FF).alpha(1 - f))
    }
}

/// Cobb Vanth, marshal of Freetown: sandy hair, a red scarf, a long brown duster with the marshal's badge, a
/// pistol that's always got a little smoke curling off the muzzle.
func drawCobbVanth(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let (step, bob) = heroBob(t, walking, role: role, rate: 3.5)
    let coat = C(0x6A4A30), coatDark = C(0x4E3622), hair = C(0x9A7A4E)
    let look = Look(leg: C(0x4A4038), arm: coat)
    c.oy = bob
    c.rect(17, 36, 3, 6, coatDark); c.rect(36, 36, 3, 6, coatDark)  // the duster's tails
    c.oy = 0
    drawLegs(c, look, step: step)
    c.oy = bob
    drawBody(c, look)
    c.pattern(18, 22, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHhHHHHHHHHHHhHHHH",
        "HH................HH",
    ], ["H": hair, "h": C(0x7A5A36)])
    c.rect(25, 32, 6, 1, C(0x7A5A36))                              // the moustache
    c.rect(18, 33, 20, 2, C(0x9A3A2A))                             // scarf
    c.rect(18, 35, 20, 3, coat)
    c.rect(37, 35, 1, 3, coatDark)
    c.px(32, 35, C(0xD8DCE4)); c.px(31, 36, C(0xD8DCE4)); c.px(33, 36, C(0xD8DCE4))   // the badge
    heroPistol(c, .cobbVanth, t: t, walking: walking, role: role, bob: bob, period: 1.0, phase: 0.15) {
        drawPistol($0, x: 40, y: 31, body: C(0x3A3A40), trim: C(0xB8BCC4))
    }
    if !walking {                                                  // smoke curling off the barrel
        for i in 0..<2 {
            let k = (t / 2.2 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
            c.px(47 + Int((sin(k * 9) * 1.5).rounded()), 30 - Int(k * 9), C(0xD8D8D8).alpha(0.6 * (1 - k)))
        }
    }
}

/// A pit droid: a gangly tan droid with a flat dish of a head and a cluster of lenses. Now and then it gets bonked
/// on the nose and folds up into a neat little package, then springs back open.
func drawPitDroid(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let tan = C(0xC9A46A), tanLight = C(0xE2C48A), dark = C(0x8A6E44), metal = C(0x5A5C64), lens = C(0xE0602A)
    if !walking, abs((t / 8).truncatingRemainder(dividingBy: 1) - 0.6) < 0.075 {
        c.rect(22, 37, 12, 6, tan)
        c.rect(22, 37, 12, 1, tanLight)
        c.rect(22, 42, 12, 1, dark)
        c.ellipse(28, 36, 7, 1, dark)                              // the head, folded flat on top
        c.px(31, 39, Int(t * 6) % 2 == 0 ? lens : dark)
        return
    }
    let (step, bob) = heroBob(t, walking, role: role, rate: 6)
    for (i, lx) in [23, 31].enumerated() {
        let up = step == i ? 1 : 0
        c.rect(lx, 34, 2, 9 - up, dark)
        c.rect(lx - 1, 42 - up, 4, 1, metal)
    }
    c.oy = bob
    c.rect(22, 27, 12, 8, tan)
    c.rect(22, 27, 12, 1, tanLight)
    c.rect(22, 34, 12, 1, dark); c.rect(33, 27, 1, 8, dark)
    c.rect(19, 28, 3, 1, dark); c.rect(18, 28, 1, 6, dark)          // long arms
    if !walking && sin(t * 3) > 0.4 {                              // one up, waving
        c.rect(34, 28, 4, 1, dark); c.rect(37, 22, 1, 6, dark)
    } else {
        c.rect(34, 28, 3, 1, dark); c.rect(37, 28, 1, 6, dark)
    }
    c.rect(27, 20, 2, 7, metal)                                    // the neck…
    c.ellipse(28, 18, 10, 2, tan)                                  // …and the flat head
    c.rect(19, 18, 19, 1, tanLight)
    c.circle(34, 21, 2, metal); c.circle(34, 21, 1, lens); c.px(31, 21, lens)
}

/// Kuiil, the Ugnaught moisture farmer, riding his blurrg: a squat grey-brown biped with a huge wide-mouthed head.
/// Kuiil has a white beard, goggles on his cap and a long rifle. He has spoken.
func drawKuiil(_ c: PixelCanvas, t: Double, walking: Bool, role: FightRole) {
    let hide = C(0x8A8070), hideDark = C(0x6A6254), belly = C(0xB0A48A)
    let skin = C(0xD9A07A), beard = C(0xF0EEE6), leather = C(0x6A4A2E)
    let step = walking ? Int(t * 6) % 2 : -1
    var bob = walking ? (step == 0 ? -1 : 0) : (sin(t * 2) > 0.7 ? -1 : 0)
    if case .cheer = role, !walking { bob = cheerHop(t) }
    for (i, lx) in [22, 32].enumerated() {                         // the blurrg's legs
        let up = step == i ? 1 : 0
        c.rect(lx, 35, 5, 8 - up, hideDark)
        c.rect(lx - 1, 42 - up, 7, 1, C(0x4A4438))
    }
    c.oy = bob
    let sway = sin(t * 2.5) * 1.5
    c.glowLine(16, 31, 5, 36 + sway, core: hideDark, glow: C(0, 0), coreR: 1.4, glowR: 1.5)   // tail
    c.ellipse(28, 31, 13, 6, hide)
    c.ellipse(29, 34, 10, 2, belly)
    for (x, y) in [(20, 28), (26, 27), (33, 28), (23, 31)] { c.px(x, y, hideDark) }
    c.ellipse(49, 30, 10, 6, hide)                                 // the big head
    let chomp = !walking && sin(t * 1.7) > 0.85 ? 1 : 0
    c.rect(43, 32, 16, 1 + chomp, C(0x3A2A24))                     // the wide mouth
    c.rect(44, 33 + chomp, 14, 2, belly)
    c.rect(46, 24, 8, 1, hideDark)
    c.rect(51, 26, 2, 2, ink)
    c.rect(40, 35, 2, 3, hideDark)                                  // a stubby arm
    c.rect(21, 24, 13, 2, leather)                                 // saddle
    // Kuiil up top.
    c.rect(23, 15, 10, 9, leather)
    c.rect(23, 9, 10, 7, skin)
    c.rect(22, 7, 12, 3, C(0x5A4A3A))
    c.rect(25, 8, 3, 2, C(0x9A7A3A)); c.rect(29, 8, 3, 2, C(0x9A7A3A))   // goggles on the cap
    c.px(29, 11, ink); c.px(32, 11, ink)
    c.rect(31, 12, 3, 2, C(0xC07A5A))                              // snout
    c.pattern(22, 12, ["W..........", "WW.......W.", "WWWWWWWWWW.", ".WWWWWWWW..", "..WWWWWW..."], ["W": beard])
    let (recoil, shake) = agentFire(c, t: t, walking: walking, role: role, period: 1.3, phase: 0.35,
                                    muzzleX: Int(Companion.kuiil.muzzle.x), muzzleY: Int(Companion.kuiil.muzzle.y))
    c.oy = bob - recoil
    c.ox = shake
    c.rect(32, 18, 3, 2, skin)                                     // hand…
    c.pattern(30, 17, ["....KKKKKKKKKKKKKKKKKKK", "WWWWKK.................", "WW....................."],
              ["K": C(0x2E2A26), "W": C(0x6A4A2A)])                // …and rifle
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

/// Baylan Skoll: long grey hair and beard over a dark cloak (the cape `drawLeader` gives him). When he isn't
/// fighting he strokes his beard.
func drawBaylan(_ c: PixelCanvas, t: Double, step: Int, lift: Int, idle: Bool) {
    let base = c.oy
    let robe = C(0x3A302A), grey = C(0xB8B4AC), greyDark = C(0x8E8A84)
    drawLegs(c, Look(leg: C(0x2A2622)), step: step)
    c.oy = base + lift
    let stroke = idle && sin(t * 0.6) > 0.3
    drawBody(c, Look(arm: robe), armRight: stroke ? 4 : 0)
    c.pattern(17, 21, [
        ".....GGGGGGGGGGGG.....",
        "...GGGGGGGGGGGGGGGG...",
        "..GGGgGGGGGGGGGGgGGG..",
        ".GGGGGGGGGGGGGGGGGGGG.",
        ".GGG..............GGG.",
        "GGG................GGG",
        "GG..................GG",
        "GG..................GG",
    ], ["G": grey, "g": greyDark])
    c.rect(18, 34, 20, 4, robe)
    c.rect(37, 34, 1, 4, C(0x2A221E))
    c.rect(15, 33, 4, 2, C(0x5A4A3A))                               // the pauldron on his far shoulder
    c.pattern(19, 31, [
        "GG..............GG",
        "GGG...gggggg...GGG",
        "GGGGGGGGGGGGGGGGGG",
        ".GGGGGGGgGGGGGGGG.",
        "...GGGGGGGGGGGG...",
        ".....GGGGGGGG.....",
    ], ["G": grey, "g": greyDark])
}

/// Shin Hati: short platinum hair with a braid at the back, dark armoured robes, an orange saber.
func drawShinHati(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let suit = C(0x2E2E36), plate = C(0x4A4A56), hair = C(0xE8DCB0), hairDark = C(0xC2B488)
    drawLegs(c, Look(leg: C(0x26262C)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: suit))
    c.pattern(18, 21, [
        "......BBBBBBBB......",
        "...BBBBBBBBBBBBBB...",
        ".BBBBbBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBBBBBB",
        "BBb..............bBB",
        "BB................BB",
    ], ["B": hair, "b": hairDark])
    c.pattern(16, 24, ["BB", "Bb", "BB", ".b", ".B"], ["B": hair, "b": hairDark])   // the braid
    c.rect(18, 33, 20, 5, suit)
    c.rect(18, 33, 20, 1, plate)
    c.rect(20, 34, 5, 2, plate); c.rect(31, 34, 5, 2, plate)        // armour plates
    c.rect(18, 36, 20, 1, C(0x6A4A2E))
}

/// An ID9 seeker droid: a black ball with one red eye, hovering, five spindly legs dangling under it; now and
/// then it sweeps the ground ahead with a red scan (only ever an agent).
func drawSeekerDroid(_ c: PixelCanvas, t: Double) {
    let base = c.oy
    c.rect(21, 43, 14, 1, C(0x000000).alpha(0.22))                  // its shadow
    c.oy = base + Int((sin(t * 2.4) * 1.5).rounded()) - 3
    let shell = C(0x2E3036), dark = C(0x16171B), light = C(0x6A6E78), red = C(0xFF2A2A)
    for (i, lx) in [21.0, 24.5, 28, 31.5, 35].enumerated() {
        let sway = sin(t * 3 + Double(i) * 1.3) * 1.2
        let knee = (x: 28 + (lx - 28) * 1.3, y: 36.0)
        c.glowLine(28 + (lx - 28) * 0.6, 31, knee.x, knee.y, core: dark, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.glowLine(knee.x, knee.y, knee.x + sway, 42, core: dark, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    }
    c.circle(28, 27, 7, shell)
    c.rect(21, 28, 15, 1, dark)
    c.px(25, 22, light); c.px(24, 23, light); c.px(26, 21, light)  // a glint on top
    let look = Int((sin(t * 1.1) * 2).rounded())
    c.circle(31 + look, 26, 2, C(0x3A0A0A))
    c.px(31 + look, 26, red); c.px(32 + look, 26, red); c.px(31 + look, 25, C(0xFFB0A0))
    let f = (t / 3).truncatingRemainder(dividingBy: 1)
    if f < 0.35 {                                                   // the scan, sweeping the ground ahead
        let k = f / 0.35
        c.glowLine(33, 26, 40 + k * 14, 43, core: red.alpha(0.5), glow: red, coreR: 0.4, glowR: 1.2, strength: 0.35)
    }
}

/// The ring-shaped hilt of an Inquisitor's saber, 5×5 from (x, y).
func drawInquisitorRing(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [".SSS.", "S...S", "S...S", "S...S", ".SSS."], ["S": C(0x9AA0AA)])
}

/// The Grand Inquisitor: a Pau'an, grey skin and a tall ridged skull, red lines on the face, yellow eyes, black
/// Imperial armour.
func drawGrandInquisitor(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0xC8C4BE), skinDark = C(0xA09C96), armour = C(0x1E1E24), red = C(0xB02A2A)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: skinDark, arm: armour, eye: nil))
    c.pattern(19, 17, [
        "....SSSSSSSSSS....",
        "..SSSSSSSSSSSSSS..",
        ".SSSsSSSsSSsSSSSS.",
        "SSSSsSSSsSSsSSSSSS",
        "SSSSsSSSsSSsSSSSSS",
        "SSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSS",
    ], ["S": skin, "s": skinDark])
    c.rect(21, 28, 4, 1, skinDark); c.rect(31, 28, 4, 1, skinDark)  // the heavy brow
    c.rect(22, 29, 3, 2, C(0xF0C030)); c.rect(32, 29, 3, 2, C(0xF0C030))
    c.px(23, 29, red); c.px(33, 29, red)
    c.rect(20, 27, 1, 5, red); c.rect(36, 27, 1, 5, red)            // the red lines down the face
    c.rect(28, 25, 1, 3, red)
    c.rect(24, 32, 8, 1, C(0x5A5650))                               // the thin grin
    c.rect(18, 33, 20, 5, armour)
    c.rect(18, 33, 20, 1, C(0x4A4A54))
    c.rect(26, 35, 4, 1, C(0x8A8F99))
    c.rect(14, 32, 4, 2, C(0x3A3A44)); c.rect(38, 32, 4, 2, C(0x3A3A44))   // pauldrons
}

/// The Second Sister: the black Inquisitor helmet with its grey faceplate and dark eye slits, black armour.
func drawSecondSister(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let black = C(0x1E1E26), blackDark = C(0x121218)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: black, shade: blackDark, arm: black, eye: nil))
    c.pattern(17, 18, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHhhHHHHHHHHHHHHHH..",
        ".HHhHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHFFFFFFFFFFFFFFFFHHH",
        "HHFVVVVVVFFFFVVVVVVFHH",
        "HHFFVVVVFFFFFFVVVVFFHH",
        "HHFFFFFFFFFFFFFFFFFFHH",
        "HHHFFFFFFFRRFFFFFFFHHH",
        "HHHHFFFFFFFFFFFFFFHHHH",
        ".HHHHFFFFFFFFFFFFHHHH.",
        "..HHHHHHHHHHHHHHHHHH..",
        "...HHHHHHHHHHHHHHHH...",
    ], ["H": C(0x16161C), "h": C(0x4A4A58), "F": C(0x6A6C76), "V": C(0x0A0A0E), "R": C(0xC02A2A)])
    c.rect(18, 33, 20, 5, C(0x24242C))
    c.rect(18, 36, 20, 1, C(0x8A8F99))
    c.rect(26, 34, 4, 1, C(0xA02020))
}

/// A bantha: a huge shaggy beast of Tatooine, dark brown fur to the knees, great spiral horns. It chews and swishes
/// its tail.
func drawBantha(_ c: PixelCanvas, t: Double, step: Int, lift: Int) {
    let base = c.oy
    let fur = C(0x5A4636), furDark = C(0x3E3024), furLight = C(0x76604C), horn = C(0xCDB892), hornDark = C(0x9A8462)
    for (i, lx) in [15, 22, 38, 45].enumerated() {
        let up = step >= 0 && i % 2 == step ? 1 : 0
        c.rect(lx, 33, 5, 10 - up, furDark)
        c.rect(lx, 42 - up, 5, 1, C(0x221A14))                      // hooves
    }
    c.oy = base + lift
    let sway = sin(t * 1.5) * 1.5
    c.glowLine(10, 23, 6 + sway, 33, core: furDark, glow: C(0, 0), coreR: 1.0, glowR: 1.1)
    c.ellipse(30, 25, 21, 10, fur)
    for x in 10...50 {                                              // the long fringe hanging off its sides
        c.rect(x, 31, 1, 4 + Int(noise(x * 7) * 4), x % 3 == 0 ? furDark : fur)
    }
    for (x, y) in [(16, 20), (22, 18), (30, 17), (38, 19), (44, 22), (19, 26), (27, 24), (35, 25), (41, 28)] {
        c.rect(x, y, 1, 3, furLight)
    }
    c.ellipse(53, 28, 7, 7, fur)                                    // the head
    for x in 48...58 { c.rect(x, 34, 1, 2 + Int(noise(x * 5 + 1) * 3), furDark) }   // beard
    c.ellipse(57, 31, 4, 3, furDark)                                // muzzle
    let chew = Int(t * 3) % 2
    c.rect(56, 33 + chew, 4, 1, C(0x221A14))
    c.rect(55, 26, 2, 1, ink)
    c.pattern(45, 18, [                                             // a great curled horn
        "..HHHHH..",
        ".HHhhhHH.",
        "HHh...hHH",
        "HH.....HH",
        "HH...hHHH",
        ".HH..HHH.",
        "..H.HH...",
        "....H....",
    ], ["H": horn, "h": hornDark])
    c.oy = base
}

/// Bib Fortuna, Jabba's majordomo: a pale Twi'lek, a long head-tail down his back and one over his shoulder, red
/// eyes, pointed teeth, dark robes to the floor.
func drawBibFortuna(_ c: PixelCanvas, t: Double, lift: Int) {
    let skin = C(0xE6D8C8), skinDark = C(0xBFAE9C), robe = C(0x2E2420), robeEdge = C(0x4A3A30)
    drawSkirt(c, from: 36, robe, robeEdge)
    c.oy += lift
    let sway = sin(t * 1.2)
    for (r, col) in [(1.9, skinDark), (1.1, skin)] {               // the long lekku down his back
        c.glowLine(19, 24, 14, 31, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
        c.glowLine(14, 31, 13 + sway, 41, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
    var look = Look(body: skin, shade: skinDark, arm: robe, eye: nil)
    look.legs = false
    drawBody(c, look)
    c.pattern(19, 21, [
        "....SSSSSSSSSS....",
        "..SSSSSSSSSSSSSS..",
        ".SSSSsSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSS",
    ], ["S": skin, "s": C(0xF4EAE0)])
    c.rect(21, 28, 4, 1, skinDark); c.rect(31, 28, 4, 1, skinDark)
    c.rect(22, 29, 2, 2, C(0xA82A2A)); c.rect(32, 29, 2, 2, C(0xA82A2A))
    c.pattern(24, 32, ["KKKKKKKK", "KWKWKWKK"], ["K": ink, "W": white])   // the grin
    c.rect(18, 34, 20, 4, robe)
    c.rect(37, 34, 1, 4, robeEdge)
    c.rect(22, 34, 12, 1, C(0x9A8A6A))                              // the collar
    for (r, col) in [(1.5, skinDark), (0.8, skin)] {               // the other lekku, over his shoulder
        c.glowLine(35, 25, 36, 36, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

/// Watto: a Toydarian junk dealer, hovering on a blur of wings. Blue-grey, pot-bellied, a trunk of a nose and a
/// little cap; one hand always out, haggling.
func drawWatto(_ c: PixelCanvas, t: Double, lift: Int) {
    let base = c.oy
    c.rect(20, 43, 16, 1, C(0x000000).alpha(0.22))                  // his shadow
    c.oy = base + Int((sin(t * 3) * 1.5).rounded()) - 2
    let skin = C(0x6E8CA8), skinDark = C(0x52708A), vest = C(0x8A6A3A)
    let up = Int(t * 20) % 2 == 0
    c.ellipse(15, up ? 15 : 22, 7, up ? 4 : 2, C(0xC8D8E8).alpha(0.55))   // the wings, buzzing
    c.ellipse(19, up ? 14 : 21, 6, up ? 3 : 2, C(0xE0ECF8).alpha(0.7))
    c.rect(25, 38, 2, 4, skinDark); c.rect(30, 38, 2, 4, skinDark)  // dangling legs
    c.rect(24, 42, 3, 1, skinDark); c.rect(30, 42, 3, 1, skinDark)
    c.ellipse(28, 32, 9, 7, skin)                                   // the belly
    c.ellipse(29, 34, 5, 3, C(0x86A2BC))
    c.rect(20, 27, 3, 9, vest); c.rect(34, 27, 3, 9, vest)
    c.rect(19, 36, 18, 1, C(0x4A3420))
    c.rect(16, 30, 3, 3, skin)
    let haggle = sin(t * 2) > 0.2
    c.rect(37, haggle ? 25 : 30, 3, 3, skin)                       // a hand out: how much?
    c.ellipse(29, 20, 7, 5, skin)                                   // the head
    c.rect(25, 13, 9, 3, C(0x6A5030)); c.rect(24, 15, 11, 1, C(0x4A3820))   // cap
    c.rect(29, 18, 2, 2, C(0xF0E0A0)); c.rect(33, 18, 2, 2, C(0xF0E0A0))
    c.px(30, 18, ink); c.px(34, 18, ink)
    c.rect(34, 20, 3, 3, skinDark); c.rect(36, 22, 2, 5, skinDark)  // the trunk
    c.px(33, 23, white)                                             // a tusk
    for (x, y) in [(26, 23), (28, 24), (30, 24), (32, 24)] { c.px(x, y, skinDark) }   // stubble
    c.oy = base
}

/// Moff Gideon: black Imperial uniform and cape (`drawLeader` gives him both cape and Darksaber), close-cropped hair.
func drawMoffGideon(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let uniform = C(0x1E1E26)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: uniform))
    c.pattern(18, 23, ["..HHHHHHHHHHHHHHHH..", "HHHHHHHHHHHHHHHHHHHH", "HH................HH"], ["H": C(0x1A1410)])
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, C(0x34343E))
    c.px(21, 35, C(0xD84A2A)); c.px(22, 35, C(0x3A6ED8)); c.px(23, 35, C(0xD84A2A))   // rank plaque
    c.rect(18, 36, 20, 1, C(0x3A3A44))
}

/// A death trooper: black armour, the black helmet with its dark green-glinting visor.
func drawDeathTrooper(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let black = C(0x1C1C22)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: black, shade: C(0x101014), arm: black, eye: nil))
    c.pattern(17, 19, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHhhHHHHHHHHHHHHHH..",
        ".HHhHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHVVVVVHHHHHHHHVVVVVHH",
        "HHHVVgVHHHHHHHHVVgVHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHGGGGGGHHHHHHHH",
        "HHHHHHHHGsGsGGHHHHHHHH",
        ".HHHHHHHGGGGGGHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHH..",
    ], ["H": C(0x16161C), "h": C(0x4A4C58), "V": C(0x22332C), "g": C(0x7AE0A0), "G": C(0x2E2E36), "s": C(0x6A6E78)])
    c.rect(18, 33, 20, 4, C(0x24242C))
    c.rect(18, 36, 20, 1, C(0x3A3A44))
    c.rect(22, 34, 3, 1, C(0x4A4C58)); c.rect(31, 34, 3, 1, C(0x4A4C58))
}

/// A scout trooper on a 74-Z speeder bike, hovering: the long body, the steering vanes out on their rods, the
/// cannon underneath (its weapon), and the trooper hunched over the handlebars.
func drawScoutBike(_ c: PixelCanvas, t: Double, lift: Int) {
    let base = c.oy
    c.rect(8, 43, 58, 1, C(0x000000).alpha(0.22))                   // its shadow
    c.oy = base + Int((sin(t * 3) * 1.0).rounded()) - 3
    let hull = C(0x7A7A6A), hullLight = C(0x9A9A88), dark = C(0x3A3A36), white = C(0xEEEEEA)
    c.rect(40, 31, 20, 1, C(0x4A4A50)); c.rect(40, 34, 20, 1, C(0x4A4A50))   // the rods…
    c.rect(59, 28, 2, 10, dark); c.rect(61, 29, 3, 8, C(0x5A5A52)) // …and the steering vanes
    c.rect(40, 36, 8, 1, dark)                                     // the cannon
    c.rect(8, 29, 6, 8, dark)                                      // engine
    c.rect(7, 31, 1, 4, Int(t * 15) % 2 == 0 ? C(0xFF9A2A) : C(0xFFE27A))
    c.pattern(12, 29, [
        "..HHHHHHHHHHHHHHHHHHHHHHHHH..",
        ".HLLLLLLLLLLLLLLLLLLLLLLLLLHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHHHH.....",
        "...dddddddddddddddddd........",
    ], ["H": hull, "L": hullLight, "d": dark])
    c.oy += lift
    c.rect(26, 27, 8, 3, white); c.rect(32, 30, 3, 3, ink)          // leg and boot
    c.rect(22, 19, 12, 9, white)
    c.rect(22, 25, 12, 1, ink)
    c.rect(33, 22, 6, 2, white); c.rect(38, 23, 2, 2, ink)          // arms forward to the handlebars
    c.pattern(21, 11, [
        "....WWWWWW....",
        "..WWWWWWWWWW..",
        ".WWWWWWWWWWWW.",
        "WWWWWWWWWWWWWW",
        "WWKKKKKKKKKKKW",
        "WWWWWWWWWWKKWW",
        "WWWWWWWWWKKKKW",
        ".WWWWWWWWWKKK.",
    ], ["W": white, "K": ink])
    c.oy = base
}

/// Asajj Ventress: bald and pale with dark markings over the head, pale blue eyes, dark robes; twin red sabers.
func drawVentress(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0xE4DCD8), robe = C(0x2A2630), mark = C(0x5A4A5A)
    drawLegs(c, Look(leg: robe), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: C(0xC0B6B2), arm: robe, eye: nil))
    c.pattern(19, 22, ["...SSSSSSSSSSSS...", ".SSSSSSSSSSSSSSSS.", "SSSSSSSSSSSSSSSSSS"], ["S": skin])
    c.rect(23, 23, 1, 4, mark); c.rect(28, 22, 1, 5, mark); c.rect(33, 23, 1, 4, mark)
    c.rect(22, 29, 2, 3, C(0x3A5A8A)); c.rect(32, 29, 2, 3, C(0x3A5A8A))
    c.px(22, 29, C(0x8AB0E0)); c.px(32, 29, C(0x8AB0E0))
    c.rect(18, 33, 20, 5, robe)
    c.rect(18, 33, 20, 1, C(0x4A4250))
    c.rect(18, 36, 20, 1, C(0x5A4A3A))
}

/// Savage Opress: a huge Zabrak, yellow skin striped with black, a crown of horns, armour on the shoulders.
func drawSavageOpress(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0xD8B04A), stripe = C(0x1A1410), horn = C(0xE8DCC0)
    drawLegs(c, Look(leg: C(0x2A2028)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: C(0xB08A30), arm: skin, eye: nil))
    for (x, h) in [(19, 3), (23, 5), (27, 6), (31, 5), (35, 3)] {    // the horns
        c.rect(x, 26 - h, 2, h, horn); c.px(x, 26 - h, C(0xC8BCA0))
    }
    for x in [19, 36] { c.rect(x, 26, 1, 7, stripe) }
    c.rect(27, 26, 2, 3, stripe)                                      // down the brow
    c.px(21, 28, stripe); c.px(34, 28, stripe); c.rect(25, 32, 6, 1, stripe)
    c.rect(22, 29, 2, 2, C(0xF0D040)); c.rect(32, 29, 2, 2, C(0xF0D040))
    c.rect(18, 33, 20, 5, C(0x3A3A44))
    c.rect(18, 33, 20, 1, C(0x6A6E78))
    c.rect(14, 31, 4, 3, C(0x6A6E78)); c.rect(38, 31, 4, 3, C(0x6A6E78))   // pauldrons
}

/// Jango Fett: silver-blue armour over a dark blue suit, the T-visor helmet, a jetpack (`drawLeader`), a Westar pistol.
func drawJangoFett(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let suit = C(0x3A4A6A)
    drawLegs(c, Look(leg: suit), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: suit, shade: C(0x2C3A56), arm: suit, eye: nil))
    drawMandoHelmet(c, C(0xA8B4C6), C(0xD8E0EC), marks: C(0x3A5A9A))
    c.rect(19, 33, 18, 3, C(0x9AA8BC))
    c.rect(19, 33, 18, 1, C(0xC8D0DC))
    c.rect(18, 36, 20, 1, C(0x5A4A3A))
}

/// Bossk: a Trandoshan bounty hunter, green and scaly, slit eyes, a toothy jaw, his yellow flight suit.
func drawBossk(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let scales = C(0x6A8A4A), scalesDark = C(0x4E6A36), suit = C(0xD8C060)
    drawLegs(c, Look(leg: suit), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: scales, shade: scalesDark, arm: suit, eye: nil))
    c.pattern(19, 21, ["...SSSSSSSSSSSS...", ".SSSSsSSSSSsSSSSS.", "SSSSSSSSSSSSSSSSSS", "SSsSSSSSSsSSSSSsSS"], ["S": scales, "s": scalesDark])
    for (x, y) in [(20, 27), (26, 28), (35, 27), (29, 31), (19, 31)] { c.px(x, y, scalesDark) }
    c.rect(22, 29, 3, 2, C(0xE07A2A)); c.rect(32, 29, 3, 2, C(0xE07A2A))
    c.rect(23, 29, 1, 2, ink); c.rect(33, 29, 1, 2, ink)
    c.pattern(24, 32, ["KWKWKWKW"], ["K": ink, "W": white])
    c.rect(18, 33, 20, 5, suit)
    c.rect(18, 33, 20, 1, C(0xB8A040))
    c.rect(18, 36, 20, 1, C(0x5A4A3A))
}

/// Dengar: his head wrapped in grey-white bandages, padded armour, a long blaster rifle.
func drawDengar(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let pad = C(0x6A6A5E)
    drawLegs(c, Look(leg: C(0x5A5A50)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: pad))
    c.pattern(17, 19, [
        ".....WWWWWWWWWWWW.....",
        "...WWwWWWWwWWWWwWWW...",
        "..WWWWWWwWWWWWWWWWWW..",
        ".WWwWWWWWWWWwWWWWWWWW.",
        ".WWWWWWWWWWWWWWWWwWWW.",
        "WWWWWwWWWWWWWWWWWWWWWW",
        "WWwWWWWWWWWWwWWWWWWWWW",
        "WW..................WW",
        "WW..................WW",
    ], ["W": C(0xD8D2C4), "w": C(0xA8A294)])
    c.rect(18, 33, 20, 5, pad)
    c.rect(18, 35, 20, 1, C(0x4E4E44))
    c.rect(37, 33, 1, 5, C(0x4E4E44))
}

/// A droideka: rolls in as a bronze wheel, then unfolds on three legs, head down, both gun arms forward, and (while
/// it's fighting) its shield shimmering around it.
func drawDroideka(_ c: PixelCanvas, t: Double, walking: Bool, fighting: Bool, lift: Int) {
    let bronze = C(0xA8804A), bronzeLight = C(0xC8A06A), dark = C(0x6A5030), metal = C(0x8A8070)
    if walking {
        c.circle(28, 35, 8, bronze); c.circle(28, 35, 6, dark); c.circle(28, 35, 4, bronze)
        for k in 0..<3 {
            let a = t * 12 + Double(k) * 2.094
            c.glowLine(28, 35, 28 + cos(a) * 7, 35 + sin(a) * 7, core: bronzeLight, glow: C(0, 0), coreR: 0.6, glowR: 0.7)
        }
        return
    }
    c.oy += lift
    c.glowLine(22, 30, 14, 43, core: metal, glow: C(0, 0), coreR: 0.8, glowR: 0.9)      // legs
    c.glowLine(31, 32, 38, 43, core: metal, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    c.glowLine(27, 32, 27, 43, core: dark, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    c.ellipse(25, 25, 8, 6, bronze)                                  // the curved back
    c.ellipse(24, 23, 6, 3, bronzeLight)
    c.ellipse(34, 30, 5, 3, bronze)                                  // the head, down at the front
    c.px(37, 30, C(0xFF4A3A)); c.px(36, 31, ink)
    c.rect(30, 26, 12, 2, dark)                                      // the gun arms
    c.rect(42, 26, 3, 2, metal)
    c.rect(42, 30, 6, 1, dark); c.rect(42, 32, 6, 1, dark)
    c.oy -= lift
    if fighting {
        for k in 0..<48 {
            let a = Double(k) / 48 * 2 * .pi
            let x = 28 + cos(a) * 17, y = 30 + sin(a) * 14
            guard y <= 43 else { continue }
            c.px(Int(x.rounded()), Int(y.rounded()), C(0x7FC8FF).alpha(0.35 + 0.25 * sin(t * 6 + Double(k) * 0.7)))
        }
    }
}

/// Captain Phasma: chrome armour head to foot, a black cape lined in red (`drawLeader`), a chrome blaster.
func drawPhasma(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let chrome = C(0xC8CCD4), light = C(0xF0F2F6), dark = C(0x8A8E98)
    drawLegs(c, Look(leg: dark), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: chrome, shade: dark, arm: chrome, eye: nil))
    c.pattern(17, 19, [
        ".....CCCCCCCCCCCC.....",
        "...CCCCCCCCCCCCCCCC...",
        "..CCllCCCCCCCCCCCCCC..",
        ".CClCCCCCCCCCCCCCCCCC.",
        ".CCCCCCCCCCCCCCCCCCCC.",
        "CCCKKKKKKKCCKKKKKKKCCC",
        "CCCCKKKKKKCCKKKKKKCCCC",
        "CCCCCCCCCKCCKCCCCCCCCC",
        "CCCCCCCCCCCCCCCCCCCCCC",
        "CCCCCCdCdCdCdCdCCCCCCC",
        ".CCCCCCCCCCCCCCCCCCCC.",
        "..CCCCCCCCCCCCCCCCCC..",
    ], ["C": chrome, "l": light, "K": ink, "d": dark])
    c.rect(19, 33, 18, 3, light)
    c.rect(19, 35, 18, 1, dark)
    c.rect(18, 36, 20, 1, C(0x2A2A30))
}

/// Director Krennic: the white uniform and white cape (`drawLeader`), grey-blond hair, a pistol.
func drawKrennic(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let uniform = C(0xF2F2EC)
    drawLegs(c, Look(leg: C(0xE0E0D8)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: uniform))
    c.pattern(18, 22, ["...HHHHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH", "HH................HH"], ["H": C(0xB8AC90)])
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, C(0xC8C8C0))
    c.px(21, 35, C(0xD84A2A)); c.px(22, 35, C(0x3A6ED8)); c.px(23, 35, C(0xE0B84A))
    c.rect(18, 36, 20, 1, C(0x2A2A30))
}

/// Grand Moff Tarkin: the olive-grey uniform with its rank plaque, slicked grey hair, gaunt cheeks. Unarmed: he
/// gives the order.
func drawTarkin(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let uniform = C(0x6A6E5E), dark = C(0x4E5244)
    drawLegs(c, Look(leg: C(0x3A3A34)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: uniform))
    c.pattern(18, 22, ["....HHHHHHHHHHHH....", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH", "HH................HH"], ["H": C(0xA8A8A0)])
    c.rect(21, 32, 1, 1, clawdShade); c.rect(34, 32, 1, 1, clawdShade)   // hollow cheeks
    c.rect(18, 33, 20, 5, uniform)
    c.rect(18, 33, 20, 1, dark)
    for (i, col) in [C(0xD84A2A), C(0x3A6ED8), C(0xD84A2A), C(0xE0B84A)].enumerated() {
        c.px(21 + i, 35, col); c.px(21 + i, 36, i % 2 == 0 ? C(0x3A6ED8) : C(0xD84A2A))
    }
}

/// The Fifth Brother: a big grey-skinned Inquisitor, bald, a heavy brow over yellow eyes, black armour.
func drawFifthBrother(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let skin = C(0x9A9C98), skinDark = C(0x7A7C78), armour = C(0x1E1E24)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(body: skin, shade: skinDark, arm: armour, eye: nil))
    c.pattern(19, 22, ["...SSSSSSSSSSSS...", ".SSSSSSSSSSSSSSSS.", "SSSSSSSSSSSSSSSSSS"], ["S": skin])
    c.rect(21, 28, 14, 1, skinDark)
    c.rect(22, 29, 2, 2, C(0xF0C030)); c.rect(32, 29, 2, 2, C(0xF0C030))
    c.rect(24, 32, 8, 1, skinDark)
    c.rect(18, 33, 20, 5, armour)
    c.rect(18, 33, 20, 1, C(0x3A3A44))
    c.rect(14, 31, 5, 3, C(0x3A3A44)); c.rect(37, 31, 5, 3, C(0x3A3A44))
}

/// Reva, the Third Sister: dark hair pulled back into a bun, the black Inquisitor suit, a spinning ring saber.
func drawReva(_ c: PixelCanvas, step: Int, lift: Int) {
    let base = c.oy
    let suit = C(0x1E1E26), hair = C(0x14100E)
    drawLegs(c, Look(leg: C(0x1A1A20)), step: step)
    c.oy = base + lift
    drawBody(c, Look(arm: suit))
    c.pattern(18, 22, ["...HHHHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHHHH.", "HHHHHHHHHHHHHHHHHHHH", "HH................HH"], ["H": hair])
    c.pattern(14, 22, [".HHH.", "HHHHH", ".HHH."], ["H": hair])
    c.rect(18, 33, 20, 5, suit)
    c.rect(18, 33, 20, 1, C(0x3A3A44))
    c.rect(18, 36, 20, 1, C(0x8A8F99))
}
