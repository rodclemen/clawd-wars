import AppKit

// Window-mode backdrops: one Star Wars location per character, drawn as pixel art in code.
// The first-spawned Claude decides where the crew is (or pick one from the Location menu).
// Every scene gets a canvas of w×h pixels whose bottom `floorRows` rows are the ground the crew stands on.

enum Location: String, CaseIterable {
    case cantina, deathStar, sarlaccPit, jabbasPalace, supremacy, theed, emperorThrone, geonosis, naboo, executor
    case larsFarm, obiWanHut, sandcrawler, dagobah, falcon, tantive, tuskenDesert, jakku, jediCouncil, endor, hoth, rancorPit

    var name: String {
        switch self {
        case .cantina: return "Mos Eisley Cantina"
        case .deathStar: return "Death Star"
        case .sarlaccPit: return "Great Pit of Carkoon"
        case .jabbasPalace: return "Jabba's Palace"
        case .supremacy: return "Supremacy Throne Room"
        case .theed: return "Theed Generator Complex"
        case .emperorThrone: return "Death Star II Throne Room"
        case .geonosis: return "Geonosis"
        case .naboo: return "Plains of Naboo"
        case .executor: return "Executor Bridge"
        case .larsFarm: return "Lars Homestead"
        case .obiWanHut: return "Obi-Wan's Hut"
        case .sandcrawler: return "Jawa Sandcrawler"
        case .dagobah: return "Dagobah"
        case .falcon: return "Millennium Falcon"
        case .tantive: return "Tantive IV"
        case .tuskenDesert: return "Jundland Wastes"
        case .jakku: return "Jakku"
        case .jediCouncil: return "Jedi Council Chamber"
        case .endor: return "Forest Moon of Endor"
        case .hoth: return "Battle of Hoth"
        case .rancorPit: return "Rancor Pit"
        }
    }

    static func home(of leader: Leader) -> Location {
        switch leader {
        case .vader: return .deathStar
        case .boba: return .sarlaccPit
        case .jabba, .gamorrean: return .jabbasPalace
        case .trooper: return .cantina
        case .kylo: return .supremacy
        case .maul: return .theed
        case .emperor: return .emperorThrone
        case .dooku: return .geonosis
        case .rogr: return .naboo
        case .ig88: return .executor
        case .atst: return .endor
        case .atat: return .hoth
        case .rancor: return .rancorPit
        case .greedo: return .cantina
        case .royalGuard: return .emperorThrone
        case .sebulba, .tusken: return .tuskenDesert
        case .salacious: return .jabbasPalace
        case .grievous: return .geonosis
        case .cadBane, .hammerhead: return .cantina
        case .thrawn: return .executor
        case .mse6: return .deathStar
        case .baylan, .shinHati: return .jakku
        case .id9: return .obiWanHut
        case .grandInquisitor: return .tuskenDesert
        case .secondSister: return .executor
        case .bantha, .watto: return .tuskenDesert
        case .bibFortuna: return .jabbasPalace
        case .moffGideon, .bossk, .dengar: return .executor
        case .deathTrooper, .krennic, .tarkin: return .deathStar
        case .scoutTrooper: return .endor
        case .ventress, .jangoFett: return .geonosis
        case .savageOpress, .droideka: return .theed
        case .phasma: return .supremacy
        case .fifthBrother: return .tuskenDesert
        case .reva: return .larsFarm
        }
    }

    static func home(of hero: Companion) -> Location {
        switch hero {
        case .luke: return .larsFarm
        case .obiwan: return .obiWanHut
        case .jawa, .r2d2: return .sandcrawler
        case .yoda: return .dagobah
        case .han, .chewie: return .falcon
        case .leia, .c3po: return .tantive
        case .quigon: return .tuskenDesert
        case .rey: return .jakku
        case .mace, .ahsoka: return .jediCouncil
        case .ewok: return .endor
        case .tauntaun: return .hoth
        case .jarjar: return .naboo
        case .padme: return .theed
        case .lando, .l337: return .falcon
        case .zorii: return .jakku
        case .boKatan: return .geonosis
        case .maz: return .cantina
        case .wedge: return .hoth
        case .monMothma: return .tantive
        case .ackbar: return .endor
        case .grogu: return .dagobah
        case .babuFrik, .gonk: return .sandcrawler
        case .mando: return .tuskenDesert
        case .k2so, .cassian: return .executor
        case .bix, .pitDroid: return .sandcrawler
        case .cobbVanth: return .tuskenDesert
        case .kuiil: return .jakku
        }
    }

    /// Background tint for the card area, so the whole window feels like the place.
    var panel: NSColor {
        func c(_ hex: UInt32) -> NSColor {
            NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        switch self {
        case .cantina, .obiWanHut: return c(0x2B2119)
        case .deathStar, .emperorThrone, .executor: return c(0x16181D)
        case .sarlaccPit, .tuskenDesert, .larsFarm, .jakku: return c(0x2E2418)
        case .jabbasPalace: return c(0x241A12)
        case .supremacy: return c(0x2A0A0D)
        case .theed: return c(0x141A22)
        case .geonosis: return c(0x2E1712)
        case .naboo: return c(0x14231A)
        case .sandcrawler: return c(0x261A12)
        case .dagobah: return c(0x111C15)
        case .falcon: return c(0x1E1F21)
        case .tantive: return c(0x1C2229)
        case .jediCouncil: return c(0x22180F)
        case .endor: return c(0x15200F)
        case .hoth: return c(0x1C2430)
        case .rancorPit: return c(0x1A140F)
        }
    }

    /// The parts of the scene that never move (cached per window size).
    func drawStatic(_ c: PixelCanvas, floorRows f: Int) {
        guard c.w > 0, c.h > f, f >= 0 else { return }
        let g = c.h - f    // ground line
        switch self {
        case .cantina: Cantina.drawRoom(c, floorRows: f)
        case .deathStar: Scenes.deathStar(c, g)
        case .sarlaccPit: Scenes.sarlaccPit(c, g)
        case .jabbasPalace: Scenes.jabbasPalace(c, g)
        case .supremacy: Scenes.supremacy(c, g)
        case .theed: Scenes.theed(c, g)
        case .emperorThrone: Scenes.emperorThrone(c, g)
        case .geonosis: Scenes.geonosis(c, g)
        case .naboo: Scenes.naboo(c, g)
        case .executor: Scenes.executor(c, g)
        case .larsFarm: Scenes.larsFarm(c, g)
        case .obiWanHut: Scenes.obiWanHut(c, g)
        case .sandcrawler: Scenes.sandcrawler(c, g)
        case .dagobah: Scenes.dagobah(c, g)
        case .falcon: Scenes.falcon(c, g)
        case .tantive: Scenes.tantive(c, g)
        case .tuskenDesert: Scenes.tuskenDesert(c, g)
        case .jakku: Scenes.jakku(c, g)
        case .jediCouncil: Scenes.jediCouncil(c, g)
        case .endor: Scenes.endor(c, g)
        case .hoth: Scenes.hoth(c, g)
        case .rancorPit: Scenes.rancorPit(c, g)
        }
    }

    /// Whether `drawAnimated` draws anything here (the rest are still pictures, with no per-frame layer).
    var hasAnimatedLayer: Bool {
        switch self {
        case .supremacy, .geonosis, .naboo, .larsFarm, .tantive, .tuskenDesert, .jediCouncil: return false
        case .cantina, .deathStar, .executor, .sarlaccPit, .jabbasPalace, .theed, .emperorThrone, .dagobah, .falcon,
             .sandcrawler, .obiWanHut, .jakku, .endor, .hoth, .rancorPit: return true
        }
    }

    /// `hasAnimatedLayer` for a canvas `rows` tall: full screen, a still place can have moving extras too.
    func animates(rows: Int) -> Bool { hasAnimatedLayer || (rows >= Scenes.tallRows && self == .jediCouncil) }

    /// The moving bits, drawn every frame on a transparent canvas of the same size.
    func drawAnimated(_ c: PixelCanvas, floorRows f: Int, t: Double) {
        guard animates(rows: c.h), c.w > 0, c.h > f, f >= 0 else { return }
        let tall = Scenes.isTall(c)
        let g = c.h - f
        switch self {
        case .cantina:
            // Tonight's band: the Modal Nodes or, on some nights, the Max Rebo Band (re-rolled on each visit).
            if Cantina.maxReboTonight { Scenes.maxReboBand(c, g - 4, t: t, at: 2) } else { Cantina.drawBand(c, floorRows: f, t: t) }
            Cantina.drawBarCrowd(c, floorRows: f, t: t)
        case .deathStar, .executor:
            Scenes.blinkLights(c, g, t: t, seed: self == .deathStar ? 1 : 2)
            if self == .deathStar { Scenes.starDestroyer(c, g, t: t) }
            if tall { Scenes.tieFlyby(c, g, t: t, viewport: self == .deathStar) }
        case .sarlaccPit: Scenes.sarlaccTentacles(c, g, t: t)
        case .jabbasPalace: Scenes.jabbaLamps(c, g, t: t); Scenes.maxReboBand(c, g, t: t)
        case .theed: Scenes.laserGates(c, g, t: t)
        case .emperorThrone: Scenes.spaceBattle(c, g, t: t)
        case .dagobah: Scenes.swampFog(c, g, t: t)
        case .falcon: Scenes.dejarik(c, g, t: t)
        case .sandcrawler: Scenes.crawlerLights(c, g, t: t)
        case .obiWanHut: Scenes.obiWanHologram(c, g, t: t)
        case .jakku: Scenes.jakkuWind(c, g, t: t)
        case .endor: Scenes.endorForest(c, g, t: t)
        case .hoth: if tall { Scenes.hothSpeeders(c, g, t: t) }; Scenes.snowfall(c, g, t: t)
        case .rancorPit: Scenes.grateLight(c, g, t: t)
        case .jediCouncil: Scenes.councilTraffic(c, g, t: t)
        case .supremacy, .geonosis, .naboo, .larsFarm, .tantive, .tuskenDesert: break
        }
    }
}

/// The classic Star Wars wipes between places, shared by the window and the screen saver: what's left of the old
/// picture `k` of the way through — right of an edge sweeping left to right, or what a clock hand sweeping round from
/// twelve hasn't reached yet.
enum Wipe {
    static let duration = 1.2

    static func remaining(_ k: Double, clock: Bool, in r: CGRect) -> CGPath {
        let path = CGMutablePath()
        if clock {
            let c = CGPoint(x: r.midX, y: r.midY), top = CGFloat.pi / 2
            path.move(to: c)
            path.addArc(center: c, radius: hypot(r.width, r.height), startAngle: top - 2 * .pi * k,
                        endAngle: top - 2 * .pi, clockwise: true)
            path.closeSubpath()
        } else {
            path.addRect(CGRect(x: r.minX + r.width * k, y: r.minY, width: r.width * (1 - k), height: r.height))
        }
        return path
    }

    /// One picture from several stacked (the place and what moves there), to freeze for a wipe.
    static func flatten(_ images: [CGImage]) -> CGImage? {
        guard let first = images.first else { return nil }
        let w = first.width, h = first.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        for img in images { ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h)) }
        return ctx.makeImage()
    }
}

// MARK: - Drawing helpers

func lerp(_ a: Px, _ b: Px, _ t: Double) -> Px {
    let k = max(0, min(1, t))
    return Px(r: UInt8(Double(a.r) + (Double(b.r) - Double(a.r)) * k), g: UInt8(Double(a.g) + (Double(b.g) - Double(a.g)) * k),
              b: UInt8(Double(a.b) + (Double(b.b) - Double(a.b)) * k), a: UInt8(Double(a.a) + (Double(b.a) - Double(a.a)) * k))
}

extension PixelCanvas {
    /// Vertical gradient from row y0 (top colour) to y1 (bottom colour), quantised into bands like old pixel art.
    func gradient(_ y0: Int, _ y1: Int, _ top: Px, _ bottom: Px, bands: Int = 6) {
        guard y1 > y0 else { return }
        for y in y0..<y1 {
            let k = (Double(y - y0) / Double(y1 - y0) * Double(bands)).rounded(.down) / Double(bands)
            rect(0, y, w, 1, lerp(top, bottom, k))
        }
    }

    func circle(_ cx: Int, _ cy: Int, _ r: Int, _ col: Px) {
        guard r > 0 else { px(cx, cy, col); return }
        for dy in -r...r {
            let half = Int((Double(r * r - dy * dy)).squareRoot().rounded())
            rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }

    func ellipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ col: Px) {
        guard rx > 0, ry > 0 else { return }
        for dy in -ry...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }

    /// Stars scattered over a box, or only the part of it `inside` says is open sky (a round window).
    func stars(_ y0: Int, _ y1: Int, density: Int = 40, seed: Int = 0, x0: Int = 0, x1: Int? = nil,
               inside: ((Int, Int) -> Bool)? = nil) {
        let xe = x1 ?? w
        guard y1 > y0, xe > x0 else { return }
        for i in 0..<((xe - x0) * (y1 - y0) / density) {
            let x = x0 + Int(noise(i * 3 + seed * 1000) * Double(xe - x0))
            let y = y0 + Int(noise(i * 3 + 1 + seed * 1000) * Double(y1 - y0))
            if let inside, !inside(x, y) { continue }
            px(x, y, white.alpha(noise(i * 3 + 2 + seed * 1000) > 0.8 ? 0.95 : 0.5))
        }
    }

    /// Rolling dunes or hills: fills from a wavy line down to `bottom`.
    func dunes(base: Int, amp: Double, freq: Double, phase: Double, bottom: Int, _ col: Px, shade: Px? = nil) {
        for x in 0..<w {
            let top = base - Int((sin(Double(x) * freq + phase) * 0.6 + sin(Double(x) * freq * 2.3 + phase * 1.7) * 0.4) * amp)
            if top < bottom { rect(x, top, 1, bottom - top, col) }
            if let shade, top < bottom { px(x, top, shade) }
        }
    }

    /// Ground strip with a highlighted edge and speckles.
    func ground(_ g: Int, _ col: Px, edge: Px, speck: Px, seed: Int = 0) {
        rect(0, g, w, h - g, col)
        rect(0, g, w, 1, edge)
        for i in 0..<(w * (h - g) / 6) {
            px(Int(noise(i * 11 + 3 + seed) * Double(w)), g + 1 + Int(noise(i * 11 + 4 + seed) * Double(max(1, h - g - 1))), speck)
        }
    }
}

// MARK: - The scenes

enum Scenes {
    // Vader — a Death Star corridor: grey panels, light strips, and a viewport onto space.
    static func deathStar(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x4A4E57), C(0x2C2F36), bands: 4)
        c.rect(0, 0, c.w, 5, C(0x1E2025))
        for y in stride(from: 9, to: g - 4, by: 9) { c.rect(0, y, c.w, 1, C(0x23262C)) }
        for x in stride(from: 0, to: c.w, by: 24) { c.rect(x, 5, 1, g - 5, C(0x23262C)) }
        // wall light panels
        for x in stride(from: 6, to: c.w, by: 24) {
            for y in stride(from: 12, to: g - 10, by: 18) {
                c.rect(x, y, 10, 3, C(0x9EA6B2)); c.rect(x + 1, y + 1, 8, 1, C(0xE8F0FF))
            }
        }
        if isTall(c) { deathStarHigh(c, g) }
        // The viewport: stars, and a planet's curve rising along its bottom edge (a Star Destroyer drifts past now and
        // then, in the animated layer). All of it cut off at the frame, so it reads as outside.
        let v = deathStarViewport(c, g), vx = v.minX, vw = v.width, vh = v.height
        c.rect(vx - 2, 8, vw + 4, vh + 4, C(0x15171B))
        c.rect(vx, 10, vw, vh, C(0x05060A))
        c.stars(10, 10 + vh, density: 25, seed: 3, x0: vx, x1: vx + vw)
        let pr = vw, pcx = vx + vw * 2 / 5, pcy = 10 + vh + pr - max(3, vh / 5)        // just a cap of it showing
        for y in 10..<(10 + vh) {
            for x in vx..<(vx + vw) {
                let d = (x - pcx) * (x - pcx) + (y - pcy) * (y - pcy)
                if d <= pr * pr { c.px(x, y, d >= (pr - 1) * (pr - 1) ? C(0x8EC0F0) : (d >= (pr - 4) * (pr - 4) ? C(0x5C92D6) : C(0x3A6FB0))) }
            }
        }
        for x in stride(from: vx + vw / 3, to: vx + vw, by: max(1, vw / 3)) { c.rect(x, 10, 1, vh, C(0x15171B)) }
        c.ground(g, C(0x1C1E23), edge: C(0x6E7480), speck: C(0x2A2D33), seed: 1)
        for x in stride(from: 0, to: c.w, by: 12) { c.rect(x, g + 2, 6, 1, C(0x30343B)) }
    }

    /// The Death Star corridor's viewport, in canvas pixels (row 0 at the top).
    static func deathStarViewport(_ c: PixelCanvas, _ g: Int) -> (minX: Int, minY: Int, width: Int, height: Int) {
        (c.w * 2 / 3, 10, min(70, c.w / 3), max(14, g / 2))
    }

    /// Whether a column of the viewport is one of its bars (what passes outside goes behind them).
    static func deathStarBar(_ c: PixelCanvas, _ g: Int, x: Int) -> Bool {
        let v = deathStarViewport(c, g), step = max(1, v.width / 3)
        return x >= v.minX + v.width / 3 && (x - v.minX - v.width / 3) % step == 0
    }

    /// A Star Destroyer drifting slowly past the Death Star's viewport, right to left, once a minute.
    static func starDestroyer(_ c: PixelCanvas, _ g: Int, t: Double) {
        let v = deathStarViewport(c, g)
        let p = (t / 60).truncatingRemainder(dividingBy: 1) / 0.75            // crosses in the first 45 seconds
        guard p < 1 else { return }
        let len = max(12, min(v.width * 2 / 3, v.height)), half = max(2, len / 7)
        let x0 = v.minX + v.width + 2 - Int(p * Double(v.width + len + 4)), mid = v.minY + v.height * 2 / 5
        func dot(_ x: Int, _ y: Int, _ col: Px) {
            guard x >= v.minX, x < v.minX + v.width, y >= v.minY, y < v.minY + v.height, !deathStarBar(c, g, x: x) else { return }
            c.px(x, y, col)
        }
        for i in 0..<len {                       // the wedge: a point at the nose, widest at the stern
            let h = max(0, half * i / len)
            for y in (mid - h)...(mid + h) { dot(x0 + i, y, y < mid ? C(0xA8AEB8) : (y == mid ? C(0x8A909C) : C(0x6E7480))) }
        }
        let tx = x0 + len * 3 / 4, tw = max(2, len / 8)                         // the bridge tower
        for y in (mid - half - max(2, half / 2))..<(mid - half * 3 / 4) { for x in tx..<(tx + tw) { dot(x, y, C(0x9AA0AC)) } }
        for y in (mid - half / 2)...(mid + half / 2) { dot(x0 + len, y, C(0x7AB8FF)) }   // engines
    }

    static func blinkLights(_ c: PixelCanvas, _ g: Int, t: Double, seed: Int) {
        let n = max(4, c.w / 30)
        for i in 0..<n {
            let x = Int(noise(i * 5 + seed * 77) * Double(c.w - 6)) + 2
            let y = g - 5 - Int(noise(i * 5 + 1 + seed * 77) * 6)
            let on = noise(Int(t * 3) + i * 13 + seed) > 0.4
            let col = [C(0xE0303A), C(0x3BD15A), C(0x3A7BEA), C(0xFFD23D)][i % 4]
            c.rect(x, y, 2, 1, on ? col : col.alpha(0.25))
        }
    }

    // Boba — the Great Pit of Carkoon: dunes, Jabba's sail barge, and the sarlacc.
    static func sarlaccPit(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x9FC3E0), C(0xF2DCB0), bands: 5)
        if isTall(c) { carkoonSky(c, g) }
        c.dunes(base: g - 10, amp: 3, freq: 0.05, phase: 1, bottom: g, C(0xD8B47A), shade: C(0xE8C892))
        // the sail barge (Khetanna), hovering in the distance
        let bx = c.w / 5, by = max(14, g / 3)
        if isTall(c) {
            sailBarge(c, bx, by, g)                                 // full screen: the barge at full size
        } else {
            c.rect(bx, by, 46, 5, C(0x8A6A48)); c.rect(bx + 4, by + 5, 38, 2, C(0x6E5236))
            c.rect(bx - 3, by + 1, 3, 3, C(0x8A6A48))
            for sx in [bx + 12, bx + 26] { c.rect(sx, by - 12, 1, 12, C(0x5A4636)); c.rect(sx + 1, by - 11, 8, 9, C(0xE6D6B4)) }
            c.rect(bx + 4, by + 9, 40, 1, C(0xC9A87A, 0.4))           // shadow on the sand
        }
        // the pit
        let px = c.w * 3 / 4
        c.ellipse(px, g - 3, 26, 5, C(0xC09A62))
        c.ellipse(px, g - 3, 18, 3, C(0x8A6A40))
        c.ellipse(px, g - 3, 8, 2, C(0x3A2416))
        for i in 0..<6 { c.px(px - 6 + i * 2, g - 4, C(0xF4EEDC)) }  // beak teeth
        if isTall(c) { skiffs(c, g) }
        c.ground(g, C(0xDCB97E), edge: C(0xEACB94), speck: C(0xC9A468), seed: 2)
    }

    static func sarlaccTentacles(_ c: PixelCanvas, _ g: Int, t: Double) {
        let px = Double(c.w * 3 / 4)
        for i in 0..<3 {
            let side = Double(i - 1)
            let base = (px + side * 5, Double(g - 3))
            let sway = sin(t * 2 + Double(i)) * 3
            let tip = (base.0 + side * 6 + sway, base.1 - 7 - cos(t * 1.7 + Double(i)) * 2)
            c.glowLine(base.0, base.1, tip.0, tip.1, core: C(0x8A5A3A), glow: C(0, 0), coreR: 0.8, glowR: 0.9)
        }
    }

    // Jabba / Gamorrean — the throne room in Return of the Jedi: smoky amber sandstone with rounded alcoves and light
    // falling from vents above, Han Solo frozen in carbonite on the wall, Jabba's tiered dais with cushions and the
    // hookah, and the round trapdoor over the rancor pit in front of it.
    static func jabbasPalace(_ c: PixelCanvas, _ g: Int) {
        // Walls: dark, smoky ceiling down to warm sandstone.
        c.gradient(0, g, C(0x1A110B), C(0x6E4C30), bands: 7)
        for i in 0..<(c.w * g / 22) {   // plaster grain
            c.px(Int(noise(i * 9) * Double(c.w)), Int(noise(i * 9 + 1) * Double(g)), C(0x2A1C12, 0.35))
        }
        // A ledge running along the back wall.
        c.rect(0, g - 34, c.w, 2, C(0x8A6444, 0.55)); c.rect(0, g - 32, c.w, 1, C(0x2A1C12, 0.6))
        if isTall(c) { jabbaArcade(c, g) }

        // Rounded alcoves, softly lit from inside (between the throne end and the band).
        var ax = 150
        while ax + 26 < c.w - 70 {
            let top = g - 28, r = 9
            for y in top..<(g - 2) {
                var half = r
                if y - top < r { let dy = Double(r - (y - top)); half = Int((Double(r * r) - dy * dy).squareRoot()) }
                let k = Double(y - top) / Double(g - 2 - top)
                c.rect(ax + r - half, y, half * 2, 1, lerp(C(0x2A1A10), C(0x5A3A22), k))
            }
            c.ellipse(ax + r, g - 8, 6, 3, C(0xFFB050, 0.10))      // the glow of whatever's burning in there
            ax += 48
        }

        // Vents high in the wall, with dusty light shafts falling from them.
        for (i, vx) in [96, 210, 300].enumerated() where vx < c.w - 70 {
            c.ellipse(vx, 6, 5, 2, C(0xFFD9A0, 0.55)); c.ellipse(vx, 6, 3, 1, C(0xFFF0D0, 0.8))
            for y in 8..<(g - 2) {
                let spread = 3 + (y - 8) / 4, shift = (y - 8) / 3 * (i % 2 == 0 ? 1 : -1)
                c.rect(vx - spread + shift, y, spread * 2, 1, C(0xFFD9A0, 0.05))
            }
        }

        // Han Solo in carbonite, hanging on the wall.
        let hx = 112, hy = g - 40
        c.rect(hx - 1, hy - 1, 20, 34, C(0x3A3530))                   // shadow / mount
        c.rect(hx, hy, 18, 32, C(0x5E6266))                            // the slab
        c.rect(hx, hy, 18, 1, C(0x8C9196)); c.rect(hx, hy, 1, 32, C(0x7A7F84))
        c.rect(hx + 17, hy, 1, 32, C(0x44474B)); c.rect(hx, hy + 31, 18, 1, C(0x44474B))
        c.rect(hx + 2, hy + 2, 14, 28, C(0x6A6E72))                    // the relief panel
        c.circle(hx + 9, hy + 9, 3, C(0x7E8388)); c.px(hx + 8, hy + 8, C(0x9AA0A5))   // face
        c.rect(hx + 3, hy + 4, 2, 5, C(0x7E8388)); c.rect(hx + 13, hy + 4, 2, 5, C(0x7E8388))  // hands up
        c.rect(hx + 6, hy + 13, 7, 12, C(0x767A7F)); c.rect(hx + 7, hy + 25, 2, 4, C(0x767A7F)); c.rect(hx + 10, hy + 25, 2, 4, C(0x767A7F))
        c.rect(hx + 5, hy + 12, 9, 1, C(0x9AA0A5, 0.6))
        for (i, col) in [C(0xFF5A3A), C(0x6CFF7A), C(0xFFD24A)].enumerated() { c.px(hx + 4 + i * 2, hy + 29, col) }   // the control panel

        // Jabba's dais: two curved tiers, cushions and the hookah.
        func tier(_ x0: Int, _ w: Int, _ top: Int, _ h: Int, _ face: Px, _ lip: Px) {
            for y in top..<(top + h) {
                let dy = Double(y - top) / Double(max(1, h - 1))
                let curve = Int((1 - dy) * 4)                         // rounded front edge
                c.rect(x0, y, w - curve, 1, face)
            }
            c.rect(x0, top, w - 4, 1, lip)
        }
        tier(0, 84, g - 6, 6, C(0x5A3E28), C(0x8A6444))
        tier(0, 66, g - 12, 6, C(0x6A4A30), C(0x9A7452))
        c.rect(8, g - 15, 18, 3, C(0x8E2A1E)); c.rect(8, g - 15, 18, 1, C(0xB8452E))   // cushions
        c.rect(28, g - 14, 12, 2, C(0x7A5A1E)); c.rect(28, g - 14, 12, 1, C(0xA88A3A))
        // the hookah: base, glass bowl, stem, and a hose curling back toward the throne
        let kx = 52
        c.rect(kx - 3, g - 14, 7, 2, C(0x8A6A2A))
        c.ellipse(kx, g - 18, 3, 3, C(0x7AB0A0, 0.85)); c.px(kx - 1, g - 19, C(0xD8F0E8))
        c.rect(kx, g - 30, 1, 10, C(0xC9A44A)); c.ellipse(kx, g - 31, 2, 1, C(0xE0B85A))
        for i in 0..<14 { c.px(kx - 2 - i, g - 22 + Int(sin(Double(i) * 0.45) * 3), C(0x6A3A2A)) }

        // Floor, and the round trapdoor over the rancor pit in front of the dais.
        c.ground(g, C(0x5A4230), edge: C(0x8A6444), speck: C(0x4A3424), seed: 3)
        let tx = 104, ty = g + (c.h - g) / 2
        c.ellipse(tx, ty, 17, max(2, (c.h - g) / 2 - 1), C(0x2A1C12))
        c.ellipse(tx, ty, 15, max(1, (c.h - g) / 2 - 2), C(0x120B07))
        for i in stride(from: tx - 14, through: tx + 14, by: 3) { c.rect(i, ty - (c.h - g) / 2 + 2, 1, max(1, c.h - g - 4), C(0x8A7660)) }
    }

    /// Jabba's hanging braziers (flickering) and smoke drifting up from the hookah.
    static func jabbaLamps(_ c: PixelCanvas, _ g: Int, t: Double) {
        for (i, x) in [78, 176, 268].enumerated() where x < c.w - 70 {
            let f = noise(Int(t * 9) + i * 7)
            c.rect(x, 0, 1, g - 44, C(0x2A1C12))                       // chain
            c.rect(x - 3, g - 44, 7, 2, C(0x6E4A24)); c.rect(x - 2, g - 42, 5, 1, C(0x4A3018))
            c.rect(x - 1, g - 47, 3, 3, C(0xFF8A2A)); c.px(x + (f > 0.5 ? 1 : 0), g - 48, C(0xFFE27A))
            c.circle(x, g - 45, 7, C(0xFF9A2A, 0.07 + f * 0.05))
        }
        // hookah smoke: a few soft puffs rising and drifting
        for i in 0..<4 {
            let p = (t * 0.25 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
            let y = g - 32 - Int(p * 26), x = 52 + Int(sin(p * 5 + Double(i)) * 4 + p * 8)
            c.circle(x, y, 1 + Int(p * 3), C(0xD8CFC0, 0.18 * (1 - p)))
        }
    }

    // Kylo — Snoke's throne room on the Supremacy: red curtains and a black mirrored floor.
    static func supremacy(_ c: PixelCanvas, _ g: Int) {
        c.rect(0, 0, c.w, g, C(0xA8111A))
        for x in stride(from: 0, to: c.w, by: 7) {
            c.rect(x, 0, 2, g, C(0x7E0C13))
            c.rect(x + 3, 0, 1, g, C(0xC21C26))
        }
        if isTall(c) { supremacyHigh(c, g) }
        // the throne and two Praetorian guards
        let tx = c.w / 2
        c.rect(tx - 6, g - 18, 12, 18, C(0x111114)); c.rect(tx - 8, g - 4, 16, 4, C(0x1A1A1F))
        for gx in [tx - 40, tx + 34] {
            c.rect(gx, g - 16, 6, 16, C(0xC8202A)); c.rect(gx + 1, g - 19, 4, 3, C(0xC8202A))
            c.rect(gx + 6, g - 22, 1, 20, C(0x8A8F9C))
        }
        c.rect(0, g, c.w, c.h - g, C(0x0C0B0D))
        c.rect(0, g, c.w, 1, C(0x3A0A0E))
        for x in stride(from: 0, to: c.w, by: 7) { c.rect(x + 3, g + 1, 1, c.h - g - 1, C(0x5A0C12, 0.6)) }   // reflections
    }

    // Maul — the Theed generator complex: catwalks, pipes, and the laser gates.
    static func theed(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x1A2230), C(0x2E3A4C), bands: 5)
        if isTall(c) { theedDepth(c, g) }
        for y in [g / 3, g * 2 / 3] {
            c.rect(0, y, c.w, 3, C(0x48546A)); c.rect(0, y, c.w, 1, C(0x7A889E))
            for x in stride(from: 4, to: c.w, by: 10) { c.rect(x, y + 3, 1, 5, C(0x3A4456)) }
        }
        for x in stride(from: 12, to: c.w, by: 40) {
            c.rect(x, 0, 4, g, C(0x3A4456)); c.rect(x + 1, 0, 1, g, C(0x5A6A82))
        }
        if isTall(c) { theedUpperGates(c, g) }
        // the laser corridor at the back, with its round frames
        let lx = c.w * 3 / 5
        for i in 0..<4 { c.rect(lx + i * 12, g - 26, 3, 26, C(0x56647C)) }
        c.ground(g, C(0x262C38), edge: C(0x8A98B0), speck: C(0x2E3644), seed: 4)
    }

    static func laserGates(_ c: PixelCanvas, _ g: Int, t: Double) {
        let lx = c.w * 3 / 5
        let on = (t.truncatingRemainder(dividingBy: 4)) < 2.6
        for i in 0..<3 where on {
            c.glowLine(Double(lx + i * 12 + 7), Double(g - 25), Double(lx + i * 12 + 7), Double(g - 1),
                       core: C(0xFFD6D6), glow: C(0xFF2A2A), coreR: 0.4, glowR: 1.6, strength: 0.85)
        }
        let up = isTall(c) && ((t + 1.3).truncatingRemainder(dividingBy: 4)) < 2.6   // the high catwalk's gates, out of step
        for i in 0..<3 where up {
            c.glowLine(Double(lx + i * 12 + 7), Double(g / 3 - 25), Double(lx + i * 12 + 7), Double(g / 3 - 1),
                       core: C(0xFFD6D6), glow: C(0xFF2A2A), coreR: 0.4, glowR: 1.6, strength: 0.6)
        }
    }

    // The Emperor — the Death Star II throne room: the great round window onto Endor and the fleet.
    static func emperorThrone(_ c: PixelCanvas, _ g: Int) {
        c.rect(0, 0, c.w, g, C(0x1E2026))
        if isTall(c) { emperorWalls(c, g) }
        let cx = c.w / 2, cy = g / 2 + 2, r = max(12, min(g / 2 - 2, c.w / 5))
        c.circle(cx, cy, r + 2, C(0x3A3D46))
        c.circle(cx, cy, r, C(0x04050A))
        c.stars(cy - r, cy + r, density: 18, seed: 6, x0: cx - r, x1: cx + r) { x, y in   // only through the round window
            (x - cx) * (x - cx) + (y - cy) * (y - cy) < (r - 1) * (r - 1)
        }
        c.circle(cx + r / 3, cy + r / 3, r / 3, C(0x2E6A3A)); c.circle(cx + r / 3 - 1, cy + r / 3 - 1, r / 3 - 2, C(0x4A8A50))
        for k in 0..<8 {                        // window spokes
            let a = Double(k) * .pi / 4
            c.glowLine(Double(cx), Double(cy), Double(cx) + cos(a) * Double(r), Double(cy) + sin(a) * Double(r),
                       core: C(0x3A3D46), glow: C(0, 0), coreR: 0.6, glowR: 0.7)
        }
        c.circle(cx, cy, 3, C(0x3A3D46))
        if isTall(c) { emperorStairs(c, g) }
        // steps and the throne
        for i in 0..<3 { c.rect(cx - 30 + i * 6, g - 3 - i * 2, 60 - i * 12, 2, C(0x2E3138)) }
        c.rect(cx - 5, g - 16, 10, 10, C(0x15161A))
        c.ground(g, C(0x15161A), edge: C(0x4A4E57), speck: C(0x1E2026), seed: 6)
    }

    static func spaceBattle(_ c: PixelCanvas, _ g: Int, t: Double) {
        let cx = c.w / 2, cy = g / 2 + 2, r = max(12, min(g / 2 - 2, c.w / 5))
        for i in 0..<3 {
            let k = Int(t * 2) + i * 17
            let x = cx - r / 2 + Int(noise(k) * Double(r)), y = cy - r / 2 + Int(noise(k + 1) * Double(r / 2))
            if noise(k + 2) > 0.45 {
                c.px(x, y, C(0xFFE27A)); c.px(x + 1, y, C(0xFF9A2A, 0.6))
                c.glowLine(Double(x - 6), Double(y + 2), Double(x - 2), Double(y + 1), core: C(0x7AFF8A), glow: C(0, 0), coreR: 0.4, glowR: 0.5)
            }
        }
    }

    // Dooku — Geonosis: an orange sky, red mesas and rock spires.
    static func geonosis(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0xE89A5A), C(0xF2C48A), bands: 5)
        c.circle(c.w / 6, g / 4, 4, C(0xFFF0C8))
        if isTall(c) { geonosisFar(c, g) }
        for (i, x) in stride(from: 10, to: c.w, by: 34).enumerated() {
            let hgt = Int(Double(g) * (0.35 + noise(i * 3) * 0.35))
            let wid = 6 + Int(noise(i * 3 + 1) * 8)
            c.rect(x, g - hgt, wid, hgt, C(0xA8442E))
            c.rect(x - 2, g - hgt / 2, wid + 4, hgt / 2, C(0xA8442E))
            c.rect(x, g - hgt, 2, hgt, C(0xC86A48))
        }
        c.dunes(base: g - 4, amp: 2, freq: 0.07, phase: 0, bottom: g, C(0xB85A3A))
        c.ground(g, C(0xB0583A), edge: C(0xD07A54), speck: C(0x96462C), seed: 7)
    }

    // R0-GR — the plains of Naboo, with the Trade Federation's tanks on the horizon.
    static func naboo(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x6FA8E0), C(0xCFE6F2), bands: 5)
        for (i, x) in stride(from: 20, to: c.w, by: 70).enumerated() {      // clouds
            c.ellipse(x, 8 + Int(noise(i) * 6), 9, 2, C(0xF4F8FC))
        }
        if isTall(c) { nabooFar(c, g) }
        c.dunes(base: g - 12, amp: 4, freq: 0.03, phase: 2, bottom: g, C(0x6FA05A), shade: C(0x8ABF6E))
        c.dunes(base: g - 5, amp: 3, freq: 0.05, phase: 0.5, bottom: g, C(0x5A8A48))
        if isTall(c) { gunganShield(c, g) }
        for (i, x) in stride(from: c.w / 3, to: c.w, by: 40).enumerated() {  // MTTs
            let y = g - 10 - Int(noise(i + 9) * 3)
            c.rect(x, y, 10, 4, C(0x9A8A6E)); c.rect(x + 7, y - 2, 4, 3, C(0x9A8A6E)); c.px(x + 10, y - 1, C(0x5A4E3A))
        }
        c.ground(g, C(0x5E8E4A), edge: C(0x7AAE60), speck: C(0x4E7A3E), seed: 8)
    }

    // IG-88 — the Executor's bridge: the big angled windows, crew pits and consoles.
    static func executor(_ c: PixelCanvas, _ g: Int) {
        c.rect(0, 0, c.w, g, C(0x2A2D34))
        let top = 6, bottom = g - 14
        c.rect(0, top, c.w, bottom - top, C(0x05060A))
        c.stars(top, bottom, density: 22, seed: 9)
        for (i, x) in stride(from: 30, to: c.w, by: 90).enumerated() {        // star destroyers outside
            let y = top + 6 + Int(noise(i + 4) * Double(max(1, bottom - top - 12)))
            for k in 0..<12 { c.rect(x + k, y + k / 3, 24 - k * 2, 1, C(0x8A8F9C, 0.8)) }
        }
        if isTall(c) { executorView(c, g) }
        for x in stride(from: 0, to: c.w, by: 22) { c.rect(x, top, 2, bottom - top, C(0x2A2D34)) }
        c.rect(0, bottom, c.w, 14, C(0x3A3D46))
        for x in stride(from: 8, to: c.w - 20, by: 40) { c.rect(x, bottom + 3, 24, 6, C(0x1A1C21)) }   // crew pits
        c.ground(g, C(0x22252B), edge: C(0x6E7480), speck: C(0x2C2F36), seed: 10)
    }

    // Luke — the Lars homestead at twin-sunset: the dome, the vaporators, the dunes.
    static func larsFarm(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x5A4A8A), C(0xF2A85A), bands: 6)
        let sy = max(8, g / 2)
        c.circle(c.w * 2 / 3, sy, 5, C(0xFFE8B0)); c.circle(c.w * 2 / 3 + 14, sy + 4, 4, C(0xFFD08A))
        c.circle(c.w * 2 / 3, sy, 9, C(0xFFE8B0, 0.15)); c.circle(c.w * 2 / 3 + 14, sy + 4, 8, C(0xFFD08A, 0.15))
        if isTall(c) { larsSky(c, g) }
        c.dunes(base: g - 6, amp: 3, freq: 0.04, phase: 1.2, bottom: g, C(0xC8945A), shade: C(0xDCAA6E))
        // the dome entrance
        let dx = c.w / 4
        c.ellipse(dx, g, 21, 14, C(0xD8C8A8)); c.ellipse(dx, g, 21, 2, C(0xB8A888))
        c.rect(dx - 6, g - 9, 12, 9, C(0x3A2C22))
        // moisture vaporators
        for x in [dx + 32, c.w - 40] where x < c.w - 6 {
            c.rect(x, g - 33, 3, 33, C(0xB9BEC8))
            for y in [g - 30, g - 21, g - 12] { c.rect(x - 3, y, 9, 2, C(0x8A8F9C)) }
            c.rect(x - 1, g - 36, 5, 3, C(0xD7DCE4))
        }
        if isTall(c) { landspeeder(c, dx + 52, g) }
        c.ground(g, C(0xD0A066), edge: C(0xE6BA80), speck: C(0xB88A52), seed: 11)
    }

    // Obi-Wan — inside his domed hut in the Jundland Wastes (A New Hope): a cave-like plaster dome, desert sun
    // through the round window, the open chest that held Anakin's lightsaber, his robe on a peg, a sleeping nook,
    // and the projector where Leia's message plays (animated in `obiWanHologram`).
    static func obiWanHut(_ c: PixelCanvas, _ g: Int) {
        // Warm plaster walls.
        c.gradient(0, g, C(0xC8AC84), C(0xA4865F), bands: 5)
        for i in 0..<(c.w * g / 30) { c.px(Int(noise(i * 5) * Double(c.w)), Int(noise(i * 5 + 1) * Double(g)), C(0x9A7C58, 0.5)) }
        // The dome: rough rock outside an arch spanning the room, with a smoothed plaster rim.
        for x in 0..<c.w {
            let u = (Double(x) / Double(c.w - 1)) * 2 - 1                  // -1 … 1 across the room
            let curve = Int(3 + (1 - (1 - u * u).squareRoot()) * Double(g - 14))
            c.rect(x, 0, 1, curve, C(0x5E4630))
            for i in 0..<(curve / 3) { c.px(x, Int(noise(x * 13 + i) * Double(curve)), C(0x4A3524)) }
            c.px(x, curve, C(0xE0C8A0)); c.px(x, curve + 1, C(0xB8996E))
        }

        if isTall(c) { obiWanHigh(c, g) }
        // The round window, with a beam of desert sun falling across the room.
        let wx = c.w / 2 + 40, wy = g / 2 - 2
        c.circle(wx, wy, 8, C(0x7A5E40)); c.circle(wx, wy, 6, C(0xFFF1CF))
        c.rect(wx - 6, wy, 13, 1, C(0x7A5E40)); c.rect(wx, wy - 6, 1, 13, C(0x7A5E40))
        for y in wy..<g {
            let d = y - wy, x0 = wx - 6 - d * 3 / 2
            c.rect(x0, y, 12 + d / 2, 1, C(0xFFF1CF, 0.10))
        }

        // His robe on a peg.
        let rx = 16
        c.rect(rx, g - 34, 3, 1, C(0x5A4030))
        for y in 0..<20 { let half = 2 + y / 4; c.rect(rx + 1 - half, g - 33 + y, half * 2 + 1, 1, C(0x6A4A30)) }
        c.rect(rx - 1, g - 33, 4, 3, C(0x4E3624))                              // the hood

        // The sleeping nook: a curved recess with cushions.
        let nx = c.w - 120
        c.ellipse(nx + 22, g - 10, 24, 12, C(0x8A6C4A)); c.rect(nx - 2, g - 10, 48, 10, C(0xA4865F))
        c.rect(nx + 2, g - 9, 40, 4, C(0xC9B08A)); c.rect(nx + 4, g - 11, 9, 3, C(0x8E5A3A)); c.rect(nx + 31, g - 11, 9, 3, C(0x7A8A6A))

        // The chest that held Anakin's lightsaber, lid open, the hilt glinting inside.
        let cx = 30
        c.rect(cx, g - 9, 20, 9, C(0x5A4030)); c.rect(cx, g - 9, 20, 1, C(0x8A6A48))
        c.rect(cx + 1, g - 16, 18, 6, C(0x4A3424)); c.rect(cx + 1, g - 16, 18, 1, C(0x7A5A3C))   // lid, up
        c.rect(cx + 6, g - 10, 8, 1, C(0xB8BEC6)); c.px(cx + 9, g - 10, C(0x2A2A2E)); c.px(cx + 13, g - 11, C(0xFFFFFF))

        // Floor, the round woven rug and the low table with the hologram projector.
        c.ground(g, C(0x8A6C4A), edge: C(0xB8996E), speck: C(0x7A5E40), seed: 12)
        let mid = 92                                   // left of centre, where the crew doesn't stand in front of it
        c.ellipse(mid, g + (c.h - g) / 2, 34, max(2, (c.h - g) / 2 - 1), C(0x9A4A30))
        c.ellipse(mid, g + (c.h - g) / 2, 28, max(1, (c.h - g) / 2 - 2), C(0xB8683E))
        c.ellipse(mid, g + (c.h - g) / 2, 16, max(1, (c.h - g) / 2 - 3), C(0x9A4A30))
        c.rect(mid - 9, g - 6, 18, 2, C(0x6A4A30)); c.rect(mid - 7, g - 4, 2, 4, C(0x5A4030)); c.rect(mid + 5, g - 4, 2, 4, C(0x5A4030))
        c.ellipse(mid, g - 7, 3, 1, C(0x8A8F9C)); c.px(mid, g - 8, C(0x9AD8FF))
    }

    /// Leia's message flickering above the projector ("Help me, Obi-Wan Kenobi"), and dust drifting in the sunbeam.
    static func obiWanHologram(_ c: PixelCanvas, _ g: Int, t: Double) {
        let mid = 92, base = g - 9
        let flicker = noise(Int(t * 14)) > 0.12 ? 1.0 : 0.35
        let a = (0.55 + 0.15 * sin(t * 9)) * flicker
        let blue = C(0x8AD4FF, a), dim = C(0x5AA8E8, a * 0.7)
        c.rect(mid - 4, base - 18, 9, 18, C(0x6ABFFF, 0.06 * flicker))   // the projection cone
        // Leia: the buns, head, gown
        c.rect(mid - 1, base - 18, 3, 4, blue)                                       // head
        c.rect(mid - 4, base - 17, 2, 2, blue); c.rect(mid + 3, base - 17, 2, 2, blue)   // the side buns
        c.px(mid, base - 16, dim)                                                     // face shadow
        c.rect(mid, base - 14, 1, 2, dim)                                             // neck
        for y in 0..<10 { let half = 1 + y / 3; c.rect(mid - half, base - 12 + y, half * 2 + 1, 1, y % 2 == 0 ? blue : dim) }
        if noise(Int(t * 5)) > 0.8 { c.rect(mid - 3, base - 10 + Int(noise(Int(t * 20)) * 10), 7, 1, C(0xFFFFFF, 0.4)) }  // a scan glitch
        // dust motes in the sunbeam
        let wx = c.w / 2 + 40, wy = g / 2 - 2
        for i in 0..<7 {
            let p = (t * 0.05 + Double(i) / 7).truncatingRemainder(dividingBy: 1)
            let y = wy + 4 + Int(p * Double(g - wy - 6)), x = wx - 4 - Int(p * Double(g - wy) * 1.2) + Int(sin(t + Double(i)) * 2)
            c.px(x, y, C(0xFFF6E0, 0.5 * (1 - abs(p - 0.5) * 2)))
        }
    }

    // Jawa / R2-D2 — the sandcrawler's hold: rusty plates, sagging cables, a magnet crane with an R2 unit dangling
    // from it, and heaps of scavenged junk — broken droid heads, arms, wheels, pipes and crates — piled everywhere.
    static func sandcrawler(_ c: PixelCanvas, _ g: Int) {
        // Rusty hull plates with rivets, dark at the ceiling.
        c.gradient(0, g, C(0x24180F), C(0x5A3C24), bands: 5)
        for y in stride(from: 8, to: g, by: 11) {
            c.rect(0, y, c.w, 1, C(0x1E140C))
            for x in stride(from: 4, to: c.w, by: 9) { c.px(x, y + 2, C(0x8A5E3A)) }
        }
        for x in stride(from: 0, to: c.w, by: 46) { c.rect(x, 0, 3, g, C(0x2E1E12)); c.rect(x + 1, 0, 1, g, C(0x4A3220)) }   // ribs
        for i in 0..<(c.w * g / 26) {   // rust streaks
            let x = Int(noise(i * 7 + 2) * Double(c.w)), y = Int(noise(i * 7 + 3) * Double(g))
            c.rect(x, y, 1, 1 + Int(noise(i * 7 + 4) * 4), C(0x7A4426, 0.35))
        }
        c.rect(0, 0, c.w, 5, C(0x1A110A))
        if isTall(c) { crawlerHigh(c, g) }
        // The Jawas' dark doorway at the back (their eyes glow in it — see crawlerLights).
        let dx = c.w / 2 + 70
        c.rect(dx, g - 26, 18, 26, C(0x0E0905)); c.rect(dx - 1, g - 27, 20, 1, C(0x6E4A2E))

        // Cables sagging from the ceiling.
        for (i, x0) in stride(from: 10, to: c.w - 30, by: 57).enumerated() {
            let span = 30 + i % 3 * 8, sag = 7 + i % 2 * 5
            for x in 0..<span {
                let u = Double(x) / Double(span) * 2 - 1
                c.px(x0 + x, 5 + Int(Double(sag) * (1 - u * u)), i % 2 == 0 ? C(0x1A1A1A) : C(0x6A2A1E))
            }
        }

        // The magnet crane, with an R2 unit hanging off it.
        let mx = c.w / 2 - 54
        c.rect(mx - 30, 5, 60, 2, C(0x3A2818)); c.rect(mx, 7, 1, 14, C(0x2A2A2A))
        c.rect(mx - 4, 21, 9, 3, C(0x5A5A62)); c.rect(mx - 4, 21, 9, 1, C(0x8A8A92))
        drawJunkDroidDome(c, mx, 26, tilt: 1)

        // Junk everywhere: low heaps along the back wall, tall piles at both ends.
        func heap(_ cx: Int, _ rx: Int, _ ry: Int, seed: Int) {
            c.ellipse(cx, g, rx, ry, C(0x3A281A))
            c.ellipse(cx, g + 1, rx - 2, ry - 2, C(0x4A3422))
            // parts scattered over its surface
            // packed all the way into the heap, back to front, so the surface is solid junk
            let n = rx * ry / 7
            for i in 0..<n {
                let u = noise(seed * 100 + i * 3) * 2 - 1
                let x = cx + Int(u * Double(rx - 3))
                let surface = g - Int(Double(ry) * (1 - u * u).squareRoot()) + 2
                let depth = Int(pow(noise(seed * 100 + i * 3 + 1), 2) * Double(max(1, g - surface)))
                drawJunkPart(c, x, min(g, surface + depth), kind: Int(noise(seed * 100 + i * 3 + 2) * 9), seed: seed * 31 + i)
            }
        }
        heap(22, 44, 40, seed: 1)               // the big pile on the left
        heap(c.w - 24, 46, 44, seed: 2)         // and the right
        heap(c.w / 2 - 80, 30, 16, seed: 3)     // lower ones behind the crew
        heap(c.w / 2 - 20, 22, 9, seed: 6)
        heap(c.w / 2 + 34, 32, 13, seed: 4)
        heap(c.w / 2 + 112, 24, 18, seed: 5)

        // Floor grating, littered.
        c.ground(g, C(0x3A2818), edge: C(0x8A6A42), speck: C(0x4A3424), seed: 13)
        for x in stride(from: 0, to: c.w, by: 4) { c.rect(x, g + 1, 1, c.h - g - 1, C(0x2A1C10)) }
        for i in 0..<14 {   // bolts, nuts and scraps on the floor
            let x = Int(noise(i * 17 + 5) * Double(c.w)), y = g + 2 + Int(noise(i * 17 + 6) * Double(max(1, c.h - g - 3)))
            c.rect(x, y, 1 + i % 3, 1, [C(0x9A9AA2), C(0x8A5E3A), C(0x6E7480)][i % 3])
        }
    }

    /// An R2-style dome head (dented, one eye out).
    static func drawJunkDroidDome(_ c: PixelCanvas, _ x: Int, _ y: Int, tilt: Int = 0) {
        c.rect(x - 4, y, 9, 6, C(0xC8CCD4)); c.ellipse(x, y, 4, 3, C(0xA9AEB8))
        c.rect(x - 4, y + 2, 9, 1, C(0x3A62A8)); c.px(x - 1 + tilt, y - 1, C(0x1A1A22)); c.px(x + 2, y + 3, C(0x3A62A8))
        c.rect(x - 3, y + 6, 2, 2, C(0x8A8F9C)); c.rect(x + 2, y + 6, 2, 2, C(0x8A8F9C))
    }

    /// One piece of scavenged junk, by `kind`.
    static func drawJunkPart(_ c: PixelCanvas, _ x: Int, _ y: Int, kind: Int, seed: Int) {
        let rust = C(0x8A5E3A), metal = C(0x8A8F9C), dark = C(0x4A4E58), gold = C(0xC9A44A)
        switch kind {
        case 0: drawJunkDroidDome(c, x, y - 4)                                             // R2 dome
        case 1: c.ellipse(x, y - 2, 3, 3, gold); c.px(x - 1, y - 3, C(0x2A2A2E)); c.px(x + 1, y - 3, C(0xFFD24A))   // protocol droid head, one eye lit
        case 2: c.rect(x - 4, y - 5, 9, 6, C(0x6E6A5A)); c.rect(x - 4, y - 5, 9, 1, C(0x8A8670)); c.px(x, y - 3, C(0x2A2A2E))   // GONK box
        case 3: c.rect(x - 3, y - 3, 7, 3, dark); c.rect(x - 4, y - 1, 9, 1, metal); c.px(x + 3, y - 3, C(0xE0303A))   // mouse droid
        case 4: c.circle(x, y - 2, 2, C(0x2A2A2E)); c.px(x, y - 2, metal)                    // wheel
        case 5: for i in 0..<6 { c.px(x - 3 + i, y - 1 - (i > 3 ? i - 3 : 0), metal) }; c.rect(x + 3, y - 4, 2, 2, dark)   // a bent droid arm
        case 6: c.rect(x - 4, y - 2, 8, 2, rust); c.px(x - 4, y - 2, C(0xA87048))           // pipe
        case 7: c.rect(x - 3, y - 4, 7, 5, C(0x6A4A2C)); c.rect(x - 3, y - 4, 7, 1, C(0x8A6A42)); c.rect(x - 3, y - 2, 7, 1, C(0x4A3220))   // crate
        default: c.rect(x - 2, y - 2, 5, 2, [rust, metal, dark, gold][seed % 4])               // scrap plate
        }
    }

    /// Flickering work lights, Jawa eyes blinking in the doorway, and sparks from a broken droid on the pile.
    static func crawlerLights(_ c: PixelCanvas, _ g: Int, t: Double) {
        for (i, x) in stride(from: 24, to: c.w, by: 46).enumerated() {
            let flick = noise(Int(t * 6) + i * 9) > 0.15
            c.rect(x, 5, 6, 2, flick ? C(0xFFC86A) : C(0x6E4A2E))
            if flick { c.circle(x + 3, 7, 8, C(0xFFC86A, 0.07)) }
        }
        // two pairs of Jawa eyes in the doorway, blinking out of step
        let dx = c.w / 2 + 70
        for (j, (ex, ey)) in [(dx + 4, g - 18), (dx + 11, g - 14)].enumerated() {
            let blink = (t * 0.6 + Double(j) * 0.37).truncatingRemainder(dividingBy: 1) < 0.06
            if !blink {
                c.px(ex, ey, C(0xFFD84A)); c.px(ex + 2, ey, C(0xFFD84A))
                c.circle(ex + 1, ey, 3, C(0xFFD84A, 0.10))
            }
        }
        // sparks spitting from a droid on the right pile
        let sp = (t * 1.3).truncatingRemainder(dividingBy: 1)
        if sp < 0.25 {
            let sx = c.w - 30, sy = g - 26
            for k in 0..<5 {
                let a = Double(k) * 1.1 + t * 7, d = sp * 18
                c.px(sx + Int(cos(a) * d), sy - Int(abs(sin(a)) * d) + Int(sp * sp * 30), C(0xFFE27A, 1 - sp * 4))
            }
        }
        // the crane's R2 swaying a little
        let mx = c.w / 2 - 54, sway = Int(sin(t * 1.2) * 1.4)
        if sway != 0 { c.px(mx + sway * 3, 31, C(0xC8CCD4, 0.25)) }
    }

    // Yoda — Dagobah (The Empire Strikes Back): misty layered swamp, the gnarled tree over the dark side cave,
    // Luke's X-wing sinking nose-up in the bog, vines and moss, and Yoda's mud hut glowing in the murk.
    static func dagobah(_ c: PixelCanvas, _ g: Int) {
        // Murky green air, palest in the fog band near the ground.
        c.gradient(0, g / 2, C(0x14241A), C(0x3E5A44), bands: 5)
        c.gradient(g / 2, g, C(0x3E5A44), C(0x7A9478), bands: 4)
        // Far trees: pale silhouettes in the mist.
        for i in 0..<9 {
            let x = Int(noise(i * 5 + 40) * Double(c.w)), tw = 3 + i % 3
            c.rect(x, 0, tw, g, C(0x4E6A54, 0.55))
            c.ellipse(x + tw / 2, 6 + i % 3 * 4, 14 + i % 4 * 3, 6, C(0x405C46, 0.5))
        }

        // The gnarled tree over the dark side cave (left), roots arching over its mouth.
        let tx = 46
        c.rect(tx - 8, 0, 16, g - 18, C(0x1E1C14))
        for (j, (dx, w)) in [(-14, 6), (10, 5), (-4, 4)].enumerated() {   // twisted trunk strands
            for y in 0..<(g - 18) { c.rect(tx + dx / 2 + Int(sin(Double(y) * 0.15 + Double(j)) * 3), y, w, 1, C(0x2A2618)) }
        }
        c.ellipse(tx, g - 4, 26, 14, C(0x1E1C14))                          // the root mass
        c.ellipse(tx + 2, g - 2, 11, 9, C(0x050806))                      // the cave mouth
        c.ellipse(tx + 2, g - 1, 7, 5, C(0x020302))
        for (rx, rw) in [(-24, 10), (20, 12), (-34, 8)] {                 // roots arching into the ground
            for k in 0..<rw { c.px(tx + rx + k, g - 3 - Int(sin(Double(k) / Double(rw) * .pi) * 6), C(0x2A2618)) }
        }
        // its branches with hanging moss
        for (bx, by, bl) in [(tx, 12, 40), (tx - 6, 22, -30)] {
            for k in 0..<abs(bl) { c.px(bx + (bl > 0 ? k : -k), by - k / 6, C(0x1E1C14)); c.px(bx + (bl > 0 ? k : -k), by - k / 6 + 1, C(0x1E1C14)) }
            for k in stride(from: 4, to: abs(bl), by: 5) {
                let mx = bx + (bl > 0 ? k : -k)
                c.rect(mx, by - k / 6 + 2, 1, 4 + k % 7, C(0x5A7A44))
            }
        }

        // Mid trees: dark, twisted, with vines.
        for (i, x) in [118, 158, 236, 288].enumerated() {
            let tw = 5 + i % 2 * 2
            for y in 0..<g { c.rect(x + Int(sin(Double(y) * 0.11 + Double(i)) * 2), y, tw, 1, C(0x26281C)) }
            c.rect(x - 3, g - 4, tw + 6, 4, C(0x26281C))
            for k in 0..<3 { let vx = x + tw + 2 + k * 4; c.rect(vx, 0, 1, 10 + (i + k) % 3 * 7, C(0x4A6A3A)) }
        }

        if isTall(c) { dagobahCanopy(c, g) }
        // Ground: muddy bank, and the bog spreading under the X-wing on the right.
        c.rect(0, g, c.w, c.h - g, C(0x2A3420))
        c.rect(0, g, c.w, 1, C(0x5A7A4A))
        for i in 0..<(c.w / 3) { c.rect(Int(noise(i * 7) * Double(c.w)), g + 2 + Int(noise(i * 7 + 1) * Double(max(1, c.h - g - 3))), 3, 1, C(0x3E4E30)) }
        let bx = c.w - 120
        c.rect(bx - 40, g, 140, c.h - g, C(0x1E2E26))
        c.rect(bx - 40, g, 140, 1, C(0x4E6A5A))
        for i in 0..<10 { c.rect(bx - 26 + Int(noise(i * 3 + 70) * 110), g + 2 + i % 3 * 2, 6, 1, C(0x5E7E6E, 0.5)) }   // ripples

        // Luke's X-wing, nose up with its tail sunk in the bog: the long tapered nose with its red stripes, the canopy
        // and R2 behind it, the boxy rear with a big round engine at each wing root, the S-foils splayed in an X and the
        // long laser cannons out at their tips. Drawn flat (x toward the nose, y up, in units), tilted nose-up and
        // filled pixel by pixel; under the water line nothing shows.
        xWing(c, stern: CGPoint(x: Double(bx - 14), y: Double(g - 1)), scale: 1.55, tilt: 26, water: g)
        let xw = bx - 14
        c.rect(xw - 14, g, 110, 1, C(0x8AA89A, 0.5))                        // where it meets the water
        c.ellipse(xw + 40, g + 1, 52, 1, C(0x8AA89A, 0.18))                 // its reflection

        // Yoda's hut on the far right: a mud dome with a glowing round window and doorway.
        let hx = c.w - 26
        c.ellipse(hx, g - 1, 16, 12, C(0x5A5438)); c.ellipse(hx, g - 2, 14, 10, C(0x6E6644))
        c.circle(hx - 5, g - 7, 2, C(0xFFC86A)); c.circle(hx - 5, g - 7, 7, C(0xFFC86A, 0.14))
        c.rect(hx + 3, g - 6, 4, 6, C(0x2A2414)); c.rect(hx + 4, g - 5, 2, 5, C(0xFFB050, 0.6))
        c.rect(hx + 8, g - 14, 2, 4, C(0x4A4430))                          // the chimney
    }

    /// Luke's T-65 X-wing (see `dagobah`), its stern at `stern`, `scale` pixels per unit, `tilt` degrees nose-up.
    static func xWing(_ c: PixelCanvas, stern: CGPoint, scale: Double, tilt: Double, water: Int) {
        typealias P = (Double, Double)
        func box(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> [P] { [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] }
        let white = C(0xDCDCD4), light = C(0xEDEDE6), shade = C(0xA4A49C), dark = C(0x5E5E64), red = C(0xC03A2A)
        let gun = C(0x8A8A90), ring = C(0xB8B8B0), wing = C(0xC4C4BC), seam = C(0x7A7A78)
        // Back to front: what's further from us first.
        let shapes: [([P], Px)] = [
            ([(0, 2), (10, 2), (4, 18), (-2, 18)], shade),                          // far upper wing
            (box(-4, 17.2, 20, 18.2), dark), (box(20, 16.4, 22, 19), dark),          // its cannon
            (box(-6, 2.5, 7, 6.5), shade), (box(7, 2.5, 8, 6.5), dark),              // its engine
            ([(2, -2), (12, -2), (2, -20), (-4, -20)], white),                       // lower wings, mostly under water
            (box(-8, -9, 6, -4), shade), (box(6, -9.5, 7.5, -3.5), ring),           // near lower engine
            (box(7.5, -8.5, 8.2, -4.5), dark),
            (box(-2, -4.5, 18, 4.5), white), (box(-2, -4.5, 18, -2.5), shade),       // the rear body
            ([(18, 4.5), (18, -4.5), (52, -1.5), (57, 0), (53, 2)], white),          // the nose
            ([(18, -4.5), (52, -1.5), (52, -0.3), (18, -2.5)], shade),
            ([(50, 0), (53, 2), (57, 0), (52, -1.5)], C(0xC8C8C0)),
            ([(26, -1), (34, -0.2), (34, 1.6), (26, 2.2)], red),                     // stripes
            ([(40, -0.8), (44, -0.5), (44, 1.2), (40, 1.5)], red),
            ([(14, 4.5), (26, 3.4), (22, 7), (16, 7)], C(0x2E4A6A)),                 // canopy
            ([(16, 7), (22, 7), (21.6, 6.3), (16.3, 6.3)], C(0x8AB0D0)),
            (box(8, 4.5, 12, 7), white), (box(8.5, 7, 11.5, 8.2), light),            // R2
            (box(9.5, 5.4, 10.5, 6.3), C(0x3A6AC0)),
            ([(-2, 6), (12, 6), (2, 26), (-6, 26)], wing),                           // near upper wing
            ([(-2, 6), (12, 6), (11.6, 6.9), (-2.2, 6.9)], seam),
            ([(-2.8, 10), (10, 10), (9, 12), (-3.2, 12)], red),
            ([(-3.8, 15), (7.5, 15), (6.8, 16.5), (-4.1, 16.5)], red),
            (box(-7, 5.5, 11, 11), ring), (box(-7, 10, 11, 11), light),              // near engine: a cylinder on the
            (box(-7, 5.5, 11, 6.3), seam), (box(-8, 6, -7, 10.5), dark),             // wing root, its round intake
            (box(11, 5, 13, 11.5), white), (box(11.6, 6.2, 12.6, 10.3), dark),       // facing forward
            (box(-7, 25, 26, 26.4), gun), (box(26, 24, 28, 27.4), dark),             // its cannon
        ]
        func inside(_ poly: [P], _ x: Double, _ y: Double) -> Bool {
            var hit = false, j = poly.count - 1
            for i in poly.indices {
                let (xi, yi) = poly[i], (xj, yj) = poly[j]
                if (yi > y) != (yj > y), x < (xj - xi) * (y - yi) / (yj - yi) + xi { hit.toggle() }
                j = i
            }
            return hit
        }
        let a: Double = tilt * .pi / 180, ca = cos(a), sa = sin(a)
        // Every corner, turned and scaled, bounds the pixels to look at.
        let corners: [(Double, Double)] = shapes.flatMap(\.0).map { (x: Double, y: Double) -> (Double, Double) in
            (stern.x + scale * (x * ca - y * sa), stern.y - scale * (x * sa + y * ca))
        }
        let x0 = Int(corners.map(\.0).min()!.rounded(.down)), x1 = Int(corners.map(\.0).max()!.rounded(.up))
        let y0 = Int(corners.map(\.1).min()!.rounded(.down)), y1 = min(water, Int(corners.map(\.1).max()!.rounded(.up)))
        guard x0 < x1, y0 < y1 else { return }
        for py in y0..<y1 {
            for px in x0..<x1 {
                let dx = (Double(px) + 0.5 - stern.x) / scale, dy = (stern.y - Double(py) - 0.5) / scale
                let lx = dx * ca + dy * sa, ly = -dx * sa + dy * ca
                if let hit = shapes.last(where: { inside($0.0, lx, ly) }) { c.px(px, py, hit.1) }
            }
        }
    }

    /// Drifting fog, fireflies, bubbles rising in the bog, and eyes surfacing in the water now and then.
    static func swampFog(_ c: PixelCanvas, _ g: Int, t: Double) {
        guard c.w > 0, g > 0 else { return }
        let span = c.w + 120                 // puffs wrap from 60 px past the right edge to 60 px before the left
        for i in 0..<3 {
            let y = g - 6 - i * 7
            let off = Int((t * (4 + Double(i) * 2)).truncatingRemainder(dividingBy: Double(span)))
            for x in stride(from: -60, to: c.w + 60, by: 60) {
                c.ellipse(((x + 60 + off) % span + span) % span - 60, y, 26, 2, C(0xDDE8DD, 0.10))
            }
        }
        // fireflies
        for i in 0..<8 {
            let x = Int(noise(i * 11 + 3) * Double(c.w)) + Int(sin(t * 0.7 + Double(i)) * 6)
            let y = g / 3 + Int(noise(i * 11 + 4) * Double(g / 2)) + Int(cos(t * 0.9 + Double(i) * 2) * 3)
            let on = (t * 0.8 + Double(i) * 0.31).truncatingRemainder(dividingBy: 1) < 0.6
            if on { c.px(x, y, C(0xE8FF8A)); c.circle(x, y, 2, C(0xE8FF8A, 0.15)) }
        }
        // bubbles in the bog
        let bx = c.w - 120
        for i in 0..<3 {
            let p = (t * 0.5 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
            if p < 0.3 { c.circle(bx - 20 + i * 37, g + 3, p < 0.2 ? 1 : 0, C(0xA8C8B8, 0.7)) }
        }
        // something in the water, watching
        let e = (t * 0.07).truncatingRemainder(dividingBy: 1)
        if e > 0.82 && e < 0.94 { c.px(bx + 68, g + 3, C(0xFFE84A)); c.px(bx + 71, g + 3, C(0xFFE84A)) }
    }

    // Han / Chewbacca — the Millennium Falcon's main hold (A New Hope): curved hull with ribs, walls crowded with
    // pipes, valves and blinking panels, the dejarik table with its curved padded bench, and a round hatch down the
    // corridor to the cockpit, where hyperspace streaks past the window (animated in `dejarik`).
    static func falcon(_ c: PixelCanvas, _ g: Int) {
        // Walls: warm grey, darker up into the curve of the hull.
        c.gradient(0, g, C(0x3A3934), C(0x8E8A7E), bands: 6)
        // The hull curving overhead at both ends.
        for x in 0..<c.w {
            let u = Double(x) / Double(c.w - 1) * 2 - 1
            let curve = Int(pow(abs(u), 3) * Double(g / 2))
            if curve > 0 { c.rect(x, 0, 1, curve, C(0x262521)) }
            c.px(x, curve, C(0x5A5850))
        }
        // Ribs.
        for x in stride(from: 6, to: c.w, by: 34) { c.rect(x, 0, 4, g, C(0x5E5B52)); c.rect(x + 1, 0, 1, g, C(0xA6A294)); c.rect(x + 3, 0, 1, g, C(0x3A3934)) }
        // Pipes and conduits along the walls.
        for (y, col, hi) in [(10, C(0x6E5A48), C(0x9A8268)), (15, C(0x4E5A5E), C(0x7A8A90)), (g - 30, C(0x6A6658), C(0x9A9688))] {
            c.rect(0, y, c.w, 3, col); c.rect(0, y, c.w, 1, hi)
            for x in stride(from: 20, to: c.w, by: 47) { c.rect(x, y - 1, 3, 5, C(0x3A3934)) }   // clamps
        }
        // Panels, vents, valve wheels and a hose loop, scattered between the ribs.
        for (i, x) in stride(from: 14, to: c.w - 20, by: 34).enumerated() {
            let y = 22 + (i % 3) * 7
            switch i % 4 {
            case 0:   // a light panel
                c.rect(x, y, 14, 8, C(0x2E2D29)); c.rect(x + 1, y + 1, 12, 6, C(0x3E3D38))
                for k in 0..<4 { c.px(x + 2 + k * 3, y + 3, [C(0xE0303A), C(0x6CFF7A), C(0xFFD24A), C(0x5AB4FF)][(i + k) % 4]) }
            case 1:   // a vent
                c.rect(x, y, 16, 9, C(0x4A4840)); for k in 0..<4 { c.rect(x + 1, y + 1 + k * 2, 14, 1, C(0x2A2925)) }
            case 2:   // valve wheel on a pipe stub
                c.rect(x + 6, y - 2, 3, 12, C(0x6E5A48)); c.circle(x + 7, y + 3, 4, C(0x8A3A2A)); c.circle(x + 7, y + 3, 2, C(0x3A3934)); c.px(x + 7, y + 3, C(0xC86A48))
            default:  // a hose looping down
                for k in 0..<14 { c.px(x + k, y + Int(sin(Double(k) / 13 * .pi) * 6), C(0x2A2A2A)); c.px(x + k, y + 1 + Int(sin(Double(k) / 13 * .pi) * 6), C(0x2A2A2A)) }
            }
        }

        if isTall(c) { falconHigh(c, g) }
        // The round hatch to the cockpit corridor (right), big enough to see the cockpit window at the end of it.
        let hx = c.w - 74, hy = g - 32, hr = 32
        c.circle(hx, hy, hr + 2, C(0x4A4840)); c.circle(hx, hy, hr, C(0xB0AC9E)); c.circle(hx, hy, hr - 3, C(0x16161A))
        c.rect(hx - hr + 3, hy, (hr - 3) * 2 + 1, g - hy, C(0x16161A))     // the opening goes down to the floor
        c.rect(hx - hr, hy, 3, g - hy, C(0xB0AC9E)); c.rect(hx + hr - 2, hy, 3, g - hy, C(0xB0AC9E))
        for k in stride(from: -hr + 6, to: hr - 4, by: 9) { c.px(hx + k, hy - Int((Double(hr * hr - k * k)).squareRoot()) + 1, C(0x6E6A5E)) }   // rivets
        // the corridor walls narrowing toward the cockpit
        for y in (hy - 18)..<(g) { let w = 8 + (y - (hy - 18)) / 2; c.rect(hx - 26, y, max(0, 26 - w), 1, C(0x22221E)); c.rect(hx + w, y, max(0, 26 - w), 1, C(0x22221E)) }
        // the cockpit window: wide, framed by struts, the console below it
        c.ellipse(hx, hy - 4, 22, 14, C(0x05060C))
        c.ellipse(hx, hy - 4, 22, 14, C(0x1E2E50, 0.35))
        for k in [-12, -4, 4, 12] { c.rect(hx + k, hy - 18, 1, 28, C(0x2E2E32)) }
        c.rect(hx - 22, hy - 5, 44, 1, C(0x2E2E32))
        c.rect(hx - 24, hy + 10, 48, 4, C(0x3A3934)); c.rect(hx - 24, hy + 10, 48, 1, C(0x6A6658))
        for k in 0..<8 { c.px(hx - 20 + k * 5, hy + 12, [C(0xE0303A), C(0x6CFF7A), C(0xFFD24A), C(0x5AB4FF)][k % 4]) }
        // the two pilot seats, silhouetted
        c.rect(hx - 14, hy + 4, 7, 9, C(0x0A0A0C)); c.rect(hx + 8, hy + 4, 7, 9, C(0x0A0A0C))

        // The dejarik table with its curved padded bench (left).
        let tx = 74
        for y in 0..<14 {                                                  // the bench: a padded half-ring behind the table
            let half = Int(Double(26) * (1 - pow(Double(13 - y) / 14, 2)).squareRoot())
            c.rect(tx - half, g - 18 + y, half * 2, 1, y % 4 == 0 ? C(0xBCB6A2) : C(0xD8D2BC))
        }
        c.rect(tx - 26, g - 6, 52, 6, C(0xC8C2AC)); c.rect(tx - 26, g - 6, 52, 1, C(0xE8E2CC))
        c.ellipse(tx, g - 7, 14, 3, C(0x3A3A36)); c.rect(tx - 2, g - 6, 4, 6, C(0x2A2A28))
        for k in 0..<7 { c.rect(tx - 12 + k * 4, g - 8, 2, 1, k % 2 == 0 ? C(0x2E5A3A) : C(0x1E3A2A)) }   // the board
        c.ellipse(tx, g - 7, 12, 2, C(0x1E3A2A, 0.4))

        // Deck plates with a lit strip.
        c.ground(g, C(0x3A3A36), edge: C(0x9A968A), speck: C(0x2E2E2A), seed: 14)
        for x in stride(from: 0, to: c.w, by: 3) { c.rect(x, g + 1, 1, c.h - g - 1, C(0x2A2A28)) }
        c.rect(0, g + 2, c.w, 1, C(0xFFD8A0, 0.25))
    }

    /// The dejarik monsters squaring off, Luke's training remote hovering and zapping, and hyperspace streaking past
    /// the cockpit window down the corridor.
    static func dejarik(_ c: PixelCanvas, _ g: Int, t: Double) {
        let tx = 74
        let flick = 0.55 + 0.3 * noise(Int(t * 12))
        let hop = Int(sin(t * 3) * 1.2)
        c.rect(tx - 8, g - 13 + hop, 3, 4, C(0x7AFFB0, flick)); c.px(tx - 7, g - 14 + hop, C(0x7AFFB0, flick))
        c.rect(tx + 4, g - 12 - hop, 4, 3, C(0x7AC8FF, flick)); c.px(tx + 7, g - 13 - hop, C(0x7AC8FF, flick))

        // The training remote, bobbing above the bench, firing a little zap now and then.
        let rx = 132 + Int(sin(t * 0.9) * 10), ry = g - 40 + Int(cos(t * 1.7) * 4)
        c.circle(rx, ry, 3, C(0x3A3A3E)); c.circle(rx, ry, 2, C(0x5A5A62))
        c.px(rx - 1, ry - 1, C(0x9A9AA2)); c.px(rx + 1, ry, C(0xFF5A3A))
        for k in [-4, 4] { c.px(rx + k, ry, C(0x8A8A92)) }                 // its little antennae
        let z = (t * 0.7).truncatingRemainder(dividingBy: 1)
        if z < 0.12 { for k in 0..<10 { c.px(rx - 3 - k * 2, ry + 2 + k, C(0xFF4A3A, 1 - z * 6)) } }

        // Hyperspace past the cockpit window: streaks racing out from the centre, stretching as they go.
        let hx = c.w - 74, hy = g - 36
        c.ellipse(hx, hy, 3, 2, C(0xDDEEFF, 0.5))
        for i in 0..<34 {
            let a = Double(i) * 2.39996 + noise(i * 7)
            let p = (t * 1.4 + noise(i * 13)).truncatingRemainder(dividingBy: 1)
            let r0 = p * p * 22, r1 = min(22, r0 + 1 + p * 9)
            for k in 0...4 {
                let r = r0 + (r1 - r0) * Double(k) / 4
                let x = hx + Int((cos(a) * r).rounded()), y = hy + Int((sin(a) * r * 0.62).rounded())
                c.px(x, y, C(k == 4 ? 0xFFFFFF : 0xB8D8FF, (0.25 + 0.75 * p) * (0.4 + Double(k) * 0.15)))
            }
        }
    }

    // Leia / C-3PO — the Tantive IV: white ribbed corridor.
    static func tantive(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0xF2F4F6), C(0xC8CED6), bands: 4)
        for x in stride(from: 0, to: c.w, by: 16) {
            c.rect(x, 0, 4, g, C(0xDDE2E8)); c.rect(x, 0, 1, g, C(0xA8B0BA))
        }
        c.rect(0, 0, c.w, 4, C(0xA8B0BA))
        for x in stride(from: 6, to: c.w, by: 32) { c.rect(x, 4, 8, 2, C(0xFFFFFF)) }
        if isTall(c) { tantiveHigh(c, g) }
        c.ellipse(c.w * 3 / 4, g / 2, 10, g / 3, C(0xA8B0BA)); c.ellipse(c.w * 3 / 4, g / 2, 8, g / 3 - 2, C(0x8A939E))
        c.ground(g, C(0xB8C0CA), edge: C(0xFFFFFF), speck: C(0xA8B0BA), seed: 15)
    }

    // Qui-Gon — the Jundland Wastes: canyon rocks, Tusken Raiders and a bantha.
    static func tuskenDesert(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x8AB8E0), C(0xF0DCB0), bands: 5)
        c.circle(c.w / 5, 7, 3, C(0xFFF4D0)); c.circle(c.w / 5 + 9, 9, 2, C(0xFFE8B0))
        if isTall(c) { tuskenFar(c, g) }
        for (i, x) in stride(from: 0, to: c.w, by: 60).enumerated() {
            let hgt = g / 2 + Int(noise(i) * Double(g / 4))
            // rough, flat-topped mesa with sloping flanks and a sunlit ledge
            for k in 0..<34 {
                let flank = max(0, abs(k - 17) - 9) * 2
                let rough = Int(noise(k + i * 31) * 3)
                let top = g - hgt + flank + rough
                c.rect(x + k, top, 1, g - top, k < 17 ? C(0xC0905E) : C(0xA8784C))
            }
            c.rect(x + 10, g - hgt + 6, 12, 1, C(0xD8A878))
        }
        // a Tusken on a rock, gaffi stick raised
        let tx = c.w * 2 / 3
        c.rect(tx - 6, g - 10, 14, 10, C(0x9A7048))
        c.rect(tx, g - 18, 3, 8, C(0xC8B48A)); c.rect(tx, g - 21, 3, 3, C(0xD8C8A8)); c.px(tx + 1, g - 20, C(0x2A1C10))
        c.rect(tx + 3, g - 24, 1, 10, C(0x5A4636)); c.rect(tx + 2, g - 25, 3, 1, C(0x8A8F9C))
        // a bantha
        let bx = c.w / 3
        c.ellipse(bx, g - 6, 9, 5, C(0x5A4232)); c.rect(bx - 7, g - 3, 2, 3, C(0x4A3424)); c.rect(bx + 5, g - 3, 2, 3, C(0x4A3424))
        c.circle(bx + 9, g - 8, 3, C(0x4A3424)); c.px(bx + 12, g - 10, C(0xE8DCC0)); c.px(bx + 12, g - 7, C(0xE8DCC0))
        c.ground(g, C(0xD8B07A), edge: C(0xE8C894), speck: C(0xC09A66), seed: 16)
    }

    // Rey — Jakku, the Graveyard of Giants (The Force Awakens): a HUGE crashed Star Destroyer half-buried across the
    // whole scene, Rey's salvaged speeder and a TIE wing in the sand, under a white-hot sun (heat shimmer, blowing
    // sand and BB-8 rolling about in `jakkuWind`).
    static func jakku(_ c: PixelCanvas, _ g: Int) {
        // Bleached sky, hazy toward the horizon, and the sun with its glare.
        c.gradient(0, g, C(0x9EBCD4), C(0xF6E2B8), bands: 7)
        let sunX = 40, sunY = 12
        for r in stride(from: 20, through: 6, by: -7) { c.circle(sunX, sunY, r, C(0xFFF6DC, 0.12)) }
        c.circle(sunX, sunY, 5, C(0xFFFCF0))
        if isTall(c) { jakkuFar(c, g) }

        // The crashed Star Destroyer, HUGE: nose buried in the sand on the left, the hull rising across most of the
        // sky to its stern on the right, with the stepped superstructure, the bridge tower and three engine bells on
        // its back face. Washed out by distance.
        let base = g - 6
        let noseX = 8, sternX = c.w - 62
        let deck = Double(base - 3 - 24) / Double(sternX - noseX)          // slope: the stern deck sits 24 px from the top
        let hull = C(0xB4BAC2), hullDark = C(0x949AA4), hullLight = C(0xD2D6DC), seam = C(0xA2A8B0)
        func deckY(_ x: Int) -> Int { base - Int(Double(x - noseX) * deck) - 3 }
        for x in noseX...sternX {
            let top = deckY(x)
            c.rect(x, top, 1, base - top, (x - noseX) % 23 == 0 ? hullDark : hull)
            c.px(x, top, hullLight)
            // the lower flank in shadow, a band under the deck edge
            let flank = top + max(3, (base - top) / 3)
            c.rect(x, flank, 1, base - flank, hullDark)
            if (x - noseX) % 9 == 0 { c.rect(x, top + 2, 1, max(1, (flank - top) - 3), seam) }   // plating
        }
        // the stepped superstructure on the rear half, following the deck's tilt
        for (i, (from, len, rise)) in [(0.42, 0.58, 4), (0.6, 0.4, 8), (0.76, 0.24, 12)].enumerated() {
            let x0 = noseX + Int(Double(sternX - noseX) * from), x1 = min(sternX, x0 + Int(Double(sternX - noseX) * len))
            for x in x0..<x1 {
                let top = deckY(x) - rise
                c.rect(x, top, 1, rise, i % 2 == 0 ? hull : C(0xBEC4CA)); c.px(x, top, hullLight)
            }
        }
        // the bridge tower and its two shield domes, near the stern
        let bx = sternX - 26, by = deckY(bx) - 12
        c.rect(bx - 2, by - 6, 5, 6, hull); c.rect(bx - 10, by - 9, 21, 3, C(0xC4CAD0)); c.rect(bx - 10, by - 9, 21, 1, hullLight)
        c.ellipse(bx - 8, by - 10, 3, 1, C(0xCCD2D8)); c.ellipse(bx + 8, by - 10, 3, 1, C(0xCCD2D8))
        // the stern face with its three engine bells
        let sTop = deckY(sternX) - 12
        c.rect(sternX, sTop, 10, base - sTop, hullDark); c.rect(sternX, sTop, 1, base - sTop, hullLight)
        for (k, ey) in [sTop + 9, sTop + 21, sTop + 33].enumerated() where ey < base - 4 {
            let r = k == 0 ? 6 : 5
            c.circle(sternX + 8, ey, r, C(0x7A808A)); c.circle(sternX + 8, ey, r - 2, C(0x4A4E56))
        }
        // sand heaped against it and spilling over the buried nose
        c.dunes(base: base, amp: 3, freq: 0.06, phase: 1.1, bottom: g, C(0xE4C68E), shade: C(0xF0D6A2))
        c.ellipse(noseX + 8, base - 1, 22, 4, C(0xE4C68E))

        // Back dunes.
        c.dunes(base: g - 8, amp: 5, freq: 0.03, phase: 0.6, bottom: g, C(0xE6C488), shade: C(0xF2D8A2))

        // A crashed TIE wing stuck in the sand (far right, past the stern).
        let tw = c.w - 34
        for k in 0..<18 {                                                  // a hexagonal wing panel stuck in the sand at a tilt
            c.rect(tw + k / 3, g - 4 - k, 12, 1, k % 6 == 0 ? C(0x3A3E46) : C(0x4E545E))
        }
        for k in 0..<4 { c.rect(tw + 2 + k * 3 + k / 2, g - 20 + k, 1, 14, C(0x2A2E36)) }

        // Rey's speeder, parked in the foreground: the big intake, the tarp and the net of salvage.
        let px = 60
        c.rect(px, g - 9, 22, 5, C(0x8A8A82)); c.rect(px, g - 9, 22, 1, C(0xB0B0A6))
        c.circle(px + 3, g - 7, 4, C(0x5A5A54)); c.circle(px + 3, g - 7, 2, C(0x2A2A28))   // the intake
        c.rect(px + 10, g - 13, 10, 4, C(0x8E6A44)); c.rect(px + 10, g - 13, 10, 1, C(0xA8845A))   // tarp-wrapped salvage
        for k in 0..<5 { c.px(px + 11 + k * 2, g - 12, C(0x5A4A3A)) }     // the net
        c.rect(px + 4, g - 4, 14, 1, C(0x000000, 0.18))                    // its shadow, hovering

        // Foreground sand.
        c.ground(g, C(0xE0B87C), edge: C(0xF4D49C), speck: C(0xC8A066), seed: 17)
    }

    /// Heat shimmer off the sand, blowing grit, and BB-8 rolling back and forth.
    static func jakkuWind(_ c: PixelCanvas, _ g: Int, t: Double) {
        // BB-8: a white ball with orange rings, rolling, its domed head riding on top and bobbing.
        let span = Double(c.w - 140), p = (t * 0.045).truncatingRemainder(dividingBy: 2)
        let u = p < 1 ? p : 2 - p                                          // there and back
        let bx = 120 + Int(u * span), dir = p < 1 ? 1.0 : -1.0
        let by = g + 1, roll = t * 5 * dir
        c.circle(bx, by - 5, 5, C(0xF2F0EA)); c.circle(bx, by - 5, 5, C(0xF2F0EA))
        for k in 0..<2 {                                                   // the orange rings turn as it rolls
            let a = roll + Double(k) * .pi
            let rx = bx + Int(cos(a) * 3), ry = by - 5 + Int(sin(a) * 3)
            c.circle(rx, ry, 1, C(0xE8862A)); c.px(rx, ry, C(0xC8C8C0))
        }
        c.rect(bx - 5, by - 1, 11, 1, C(0x000000, 0.15))                   // its shadow
        let bob = Int(abs(sin(t * 6)) * 1)
        c.ellipse(bx + Int(dir), by - 11 - bob, 3, 2, C(0xF2F0EA))         // the head
        c.rect(bx - 3 + Int(dir), by - 10 - bob, 7, 1, C(0xE8862A))
        c.px(bx + Int(dir * 2), by - 12 - bob, C(0x1A1A1E))                // the eye
        c.px(bx + Int(dir), by - 14 - bob, C(0x9A9A9A))                     // antenna

        for i in 0..<5 {   // shimmer: faint wavering bands just above the dunes
            let y = g - 10 - i * 3
            for x in stride(from: 0, to: c.w, by: 6) {
                let o = sin(Double(x) * 0.15 + t * 3 + Double(i)) * 1.2
                c.px(x + Int(o), y, C(0xFFF4DC, 0.10))
            }
        }
        for i in 0..<26 {  // grit blowing across, low over the ground
            let p = (t * (0.18 + noise(i * 5) * 0.12) + noise(i * 7)).truncatingRemainder(dividingBy: 1)
            let x = Int(p * Double(c.w + 20)) - 10, y = g - 2 - Int(noise(i * 3) * 14) + Int(sin(t * 2 + Double(i)) * 1.5)
            c.px(x, y, C(0xF0D29C, 0.6)); c.px(x - 1, y, C(0xF0D29C, 0.3))
        }
    }

    // Mace Windu / Ahsoka — the Jedi Council chamber: tall windows onto the Coruscant skyline.
    static func jediCouncil(_ c: PixelCanvas, _ g: Int) {
        c.rect(0, 0, c.w, g, C(0x6E5236))
        let top = 4, bottom = g - 8
        for x in stride(from: 4, to: c.w - 14, by: 24) {
            for y in top..<bottom {
                let k = Double(y - top) / Double(max(1, bottom - top))
                c.rect(x, y, 18, 1, lerp(C(0xF2A85A), C(0xE87A6A), k))
            }
            for (i, bx) in stride(from: x, to: x + 18, by: 3).enumerated() {        // skyscrapers
                let hgt = 6 + Int(noise(i + x) * Double(max(4, bottom - top - 6)))
                c.rect(bx, bottom - hgt, 3, hgt, C(0x3A2A3A))
                if noise(i * 3 + x) > 0.6 { c.px(bx + 1, bottom - hgt + 2, C(0xFFE27A)) }
            }
            c.rect(x - 2, top, 2, bottom - top, C(0x4A3624))
        }
        if isTall(c) { councilHigh(c, g) }
        for x in stride(from: 10, to: c.w, by: 32) { c.rect(x, g - 9, 10, 9, C(0x4A3624)); c.rect(x + 1, g - 12, 8, 3, C(0x5A4430)) }   // council seats
        c.ground(g, C(0x8A6A48), edge: C(0xB08A60), speck: C(0x7A5C3E), seed: 18)
        for x in stride(from: 0, to: c.w, by: 10) { c.rect(x, g + 2, 5, 1, C(0x9A7A56)) }
    }

    // AT-ST / Ewoks — the forest moon of Endor (Return of the Jedi): layered giant redwoods with sunbeams through the
    // canopy, the Ewok village of thatched huts and rope bridges up in the trees, the Imperial bunker of the shield
    // generator in a mossy mound, a scout trooper's speeder bike crashed against a trunk, and ferns everywhere.
    static func endor(_ c: PixelCanvas, _ g: Int) {
        // Deep green-blue haze, brighter toward the canopy gaps.
        c.gradient(0, g, C(0x1E3A2E), C(0x5E7E56), bands: 6)
        // Far trees: pale and misty.
        for i in 0..<14 {
            let x = Int(noise(i * 7 + 90) * Double(c.w)), tw = 3 + i % 3
            c.rect(x, 0, tw, g, C(0x4E6A54, 0.6))
        }
        if isTall(c) { endorFar(c, g) }
        // Sunbeams slanting down through the canopy.
        for (i, sx) in [70, 170, 260].enumerated() {
            for y in 0..<g {
                let w = 5 + y / 6, x = sx + y / 2 + i * 3
                c.rect(x - w / 2, y, w, 1, C(0xF4F0C0, 0.06))
            }
        }
        // Mid redwoods: tall, reddish, with bark grooves.
        func redwood(_ x: Int, _ tw: Int, _ bark: Px, _ light: Px, _ dark: Px) {
            c.rect(x, 0, tw, g, bark)
            c.rect(x + 1, 0, max(1, tw / 4), g, light); c.rect(x + tw - max(1, tw / 4), 0, max(1, tw / 4), g, dark)
            for k in stride(from: 2, to: tw - 2, by: 3) { c.rect(x + k, 0, 1, g, dark.alpha(0.5)) }   // grooves
            c.rect(x - tw / 3, g - 5, tw + tw * 2 / 3, 5, bark)                                   // flared roots
            c.rect(x - tw / 2, g - 2, tw * 2, 2, dark)
        }
        for (i, x) in [40, 104, 222, 300].enumerated() { redwood(x, 10 + i % 2 * 4, C(0x6A4028), C(0x8A5636), C(0x4A2A1A)) }
        if isTall(c) { endorCanopy(c, g) }

        // The Ewok village up in the trees: platforms, thatched cone huts, rope bridges, lanterns.
        let huts: [(x: Int, y: Int)] = [(46, 18), (110, 10), (228, 16), (306, 8)]
        for (i, h) in huts.enumerated() {
            c.rect(h.x - 12, h.y + 8, 30, 2, C(0x8A6238)); c.rect(h.x - 12, h.y + 10, 30, 1, C(0x5A3A20))   // platform
            for k in 0..<10 {                                                 // the cone roof
                let half = 1 + k * 7 / 10
                c.rect(h.x + 3 - half, h.y - 4 + k, half * 2 + 1, 1, k % 3 == 0 ? C(0x8A6A3A) : C(0xA8844A))
            }
            c.rect(h.x - 3, h.y + 5, 13, 4, C(0x9A7448)); c.rect(h.x + 2, h.y + 6, 3, 3, C(0x2A1A0E))   // walls and door
            c.px(h.x - 6, h.y + 6, C(0xFFB050)); c.circle(h.x - 6, h.y + 6, 3, C(0xFFB050, 0.15))       // lantern
            if i + 1 < huts.count {                                           // a rope bridge to the next tree
                let n = huts[i + 1]
                let x0 = h.x + 18, x1 = n.x - 12, y0 = h.y + 9, y1 = n.y + 9
                guard x1 > x0 else { continue }
                for x in x0...x1 {
                    let u = Double(x - x0) / Double(x1 - x0)
                    let y = y0 + Int(Double(y1 - y0) * u + sin(u * .pi) * 6)
                    c.px(x, y, C(0x7A5A32)); if x % 3 == 0 { c.px(x, y - 3, C(0x5A4228)); c.px(x, y - 2, C(0x5A4228)) }
                }
            }
        }

        if isTall(c) { endorLowerVillage(c, g) }
        // The Imperial bunker of the shield generator, built into a mossy mound (right).
        let bx = c.w - 54
        c.ellipse(bx, g, 40, 22, C(0x3E5A30)); c.ellipse(bx, g + 1, 36, 19, C(0x4E6E3A))
        c.rect(bx - 16, g - 18, 32, 18, C(0x6A6E72)); c.rect(bx - 16, g - 18, 32, 2, C(0x8A8E92))
        c.rect(bx - 12, g - 14, 24, 14, C(0x3A3E44))                       // blast door
        for k in 0..<3 { c.rect(bx - 12, g - 12 + k * 4, 24, 1, C(0x2A2E34)) }
        c.rect(bx + 13, g - 11, 2, 2, C(0xE0303A))                         // the door panel light
        for k in 0..<5 { c.rect(bx - 16 + k * 8, g - 20, 4, 2, C(0x5A7A40)) } // moss hanging over the top

        // Huge foreground trunks framing the scene, dark and close.
        redwood(-6, 22, C(0x4A2C1A), C(0x6A4028), C(0x2E1A0E))
        redwood(156, 16, C(0x52321E), C(0x74482C), C(0x341E10))

        // A scout trooper's speeder bike, crashed against the trunk.
        let sx = 52                                                        // against the left redwood, clear of the crew
        c.rect(sx, g - 8, 18, 4, C(0xC8CCD0)); c.rect(sx, g - 8, 18, 1, C(0xE4E8EC))
        c.rect(sx + 14, g - 11, 6, 3, C(0x8A8E92))                         // the steering vanes, crumpled
        c.rect(sx + 2, g - 4, 10, 2, C(0x6A6E72))
        c.px(sx + 5, g - 7, C(0x2A2E34)); c.px(sx + 19, g - 10, C(0xE0303A))
        c.rect(sx + 3, g - 12, 2, 3, C(0x5A5E62, 0.6))                     // a wisp of smoke

        // Forest floor: ferns, roots and a fallen log.
        c.ground(g, C(0x2E2416), edge: C(0x4A3A22), speck: C(0x3E301C), seed: 19)
        c.rect(98, g - 4, 34, 4, C(0x5A3A22)); c.rect(98, g - 4, 34, 1, C(0x7A5232)); c.circle(132, g - 2, 2, C(0x8A6A42))   // log
        for (i, x) in stride(from: 2, to: c.w, by: 7).enumerated() {         // ferns: arching fronds
            let fh = 4 + Int(noise(i * 3 + 40) * 6)
            let col = i % 3 == 0 ? C(0x3E7A30) : C(0x4E8E3A)
            for k in 0..<fh {
                c.px(x - k / 2, g - k, col); c.px(x + k / 2, g - k, col)
                if k % 2 == 0 { c.px(x - k / 2 - 1, g - k + 1, col); c.px(x + k / 2 + 1, g - k + 1, col) }
            }
        }
    }

    /// Dust floating in the sunbeams, leaves drifting down, and the Ewok lanterns flickering.
    static func endorForest(_ c: PixelCanvas, _ g: Int, t: Double) {
        for (i, sx) in [70, 170, 260].enumerated() {
            for k in 0..<5 {
                let p = (t * 0.04 + Double(k) / 5 + Double(i) * 0.13).truncatingRemainder(dividingBy: 1)
                let y = Int(p * Double(g)), x = sx + y / 2 + i * 3 + Int(sin(t + Double(k * 3)) * 3)
                c.px(x, y, C(0xFFF8D0, 0.45 * sin(p * .pi)))
            }
        }
        for i in 0..<6 {
            let p = (t * 0.07 + noise(i * 9)).truncatingRemainder(dividingBy: 1)
            let x = Int(noise(i * 9 + 1) * Double(c.w)) + Int(sin(t * 1.5 + Double(i)) * 5), y = Int(p * Double(g))
            c.px(x, y, i % 2 == 0 ? C(0x8AA040) : C(0xB8843A))
        }
        for (i, (x, y)) in [(40, 24), (104, 16), (222, 22), (300, 14)].enumerated() {
            let f = noise(Int(t * 8) + i * 5)
            c.circle(x, y, 3 + Int(f * 2), C(0xFFB050, 0.08 + f * 0.06))
        }
    }

    // AT-AT — the Battle of Hoth: snowfield, grey sky, the shield generator and the trench.
    static func hoth(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0xA8B4C4), C(0xDCE4EC), bands: 5)
        if isTall(c) { hothFar(c, g) }
        c.dunes(base: g - 14, amp: 6, freq: 0.03, phase: 0.8, bottom: g, C(0xC8D2DE), shade: C(0xE8EEF4))   // mountains
        if isTall(c) { hothMid(c, g) }
        c.dunes(base: g - 6, amp: 2, freq: 0.06, phase: 0.2, bottom: g, C(0xE4EAF0))
        // shield generator: a big dish on a tower
        let sx = c.w * 4 / 5
        c.rect(sx, g - 18, 4, 18, C(0x8A8F9C))
        c.ellipse(sx + 2, g - 20, 10, 3, C(0x9AA0A8)); c.ellipse(sx + 2, g - 21, 8, 2, C(0xC8CED6))
        c.px(sx + 2, g - 24, C(0xE0303A))
        // the Rebel trench with a turret
        let tx = c.w / 5
        c.rect(tx - 20, g - 2, 40, 2, C(0x8A939E))
        c.rect(tx - 3, g - 6, 7, 4, C(0x6E7480)); c.rect(tx + 3, g - 5, 6, 1, C(0x3A3D46))
        c.ground(g, C(0xEEF2F6), edge: C(0xFFFFFF), speck: C(0xD0D8E2), seed: 20)
    }

    /// A distant AT-AT, `k` pixels per unit (1 = smallest), walking left; `phase` drives its stride.
    static func distantATAT(_ c: PixelCanvas, x: Int, base: Int, k: Int, phase: Double, col: Px, dark: Px) {
        let bob = Int((sin(phase * 2) * 0.5 + 0.5) * Double(k)) / max(1, k)    // a slight rise and fall
        let bodyY = base - 13 * k - bob
        c.rect(x, bodyY, 16 * k, 6 * k, col)                                    // the body
        c.rect(x, bodyY, 16 * k, max(1, k), lerp(col, C(0xEEF2F6), 0.45))       // snow-lit back
        c.rect(x + 2 * k, bodyY + 6 * k, 12 * k, max(1, k), dark)
        c.rect(x - 2 * k, bodyY + 1 * k, 2 * k, 2 * k, dark)                    // neck
        c.rect(x - 7 * k, bodyY - 1 * k + bob, 6 * k, 4 * k, col)               // the head, facing left
        c.px(x - 7 * k, bodyY + 2 * k + bob, dark)
        // four legs, front and back pairs swinging out of step
        for (i, lx) in [x + 2 * k, x + 4 * k, x + 11 * k, x + 13 * k].enumerated() {
            let swing = sin(phase + (i % 2 == 0 ? 0 : .pi)) * Double(k) * 1.5
            let foot = lx + Int(swing)
            for y in (bodyY + 6 * k)..<base {
                let u = Double(y - (bodyY + 6 * k)) / Double(max(1, base - bodyY - 6 * k))
                c.rect(lx + Int(Double(foot - lx) * u), y, max(1, k), 1, i % 2 == 0 ? col : dark)
            }
            c.rect(foot - k / 2, base - max(1, k / 2), max(2, k + 1), max(1, k / 2), dark)   // foot pad
        }
    }

    /// An AT-AT passing close by, walking left, `k` pixels per unit: panel seams, the cockpit slit, chin guns and
    /// jointed legs, which the tiny far-off ones don't need. `base` is the row its feet stand on.
    static func nearATAT(_ c: PixelCanvas, x: Int, base: Int, k: Int, phase: Double) {
        let col = C(0x7A8492), lite = lerp(col, C(0xEEF2F6), 0.45), shade = C(0x5A6370), dark = C(0x353B44)
        let bob = sin(phase * 2) > 0 ? 0 : k / 2
        let top = base - 25 * k + bob                       // the body's top: legs are 16 units, the body 9
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ p: Px) { c.rect(x + u * k, top + v * k, w * k, h * k, p) }
        let line = max(1, k / 3)
        // A leg from the hip, through the knee, to the foot; the far-side pair is darker.
        func leg(_ u: Int, swing: Double, far: Bool) {
            let hipX = x + u * k, hipY = top + 9 * k
            let footX = hipX + Int(swing * Double(k)), kneeX = hipX + Int(swing * Double(k) * 0.4) - k / 2
            let kneeY = hipY + 7 * k
            let p = far ? shade : col
            func segment(_ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int) {
                for y in y0..<y1 {
                    let f = Double(y - y0) / Double(max(1, y1 - y0))
                    c.rect(x0 + Int(Double(x1 - x0) * f), y, 2 * k, 1, p)
                    c.rect(x0 + Int(Double(x1 - x0) * f) + 2 * k - line, y, line, 1, far ? dark : shade)
                }
            }
            segment(hipX, hipY, kneeX, kneeY)
            segment(kneeX, kneeY, footX, base - k)
            c.rect(kneeX - k / 2, kneeY - k, 3 * k, 2 * k, far ? dark : shade)          // the knee joint
            c.rect(footX - k, base - k - k / 2, 4 * k, k + k / 2, far ? dark : shade)   // the foot pad
        }
        // Far legs first, then the body over their hips, then the near legs.
        for (i, u) in [5, 20].enumerated() { leg(u, swing: sin(phase + (i == 0 ? .pi : 0)) * 3, far: true) }
        r(0, 0, 24, 9, col)                                                      // the body
        r(1, -1, 22, 1, lite)                                                    // snow-lit back
        r(1, 9, 22, 1, shade)
        for u in [8, 16] { c.rect(x + u * k, top + k, line, 8 * k, shade) }      // panel seams
        c.rect(x + k, top + 4 * k, 22 * k, line, shade)
        r(10, 5, 4, 2, shade)                                                    // a hatch
        r(-3, 3, 3, 3, shade)                                                    // the neck, ribbed
        for v in [3, 5] { c.rect(x - 3 * k, top + v * k, 3 * k, line, dark) }
        let hy = bob / 2 - bob                                                   // the head nods against the body
        c.rect(x - 12 * k, top + 2 * k + hy, 9 * k, 6 * k, col)                  // the head
        c.rect(x - 11 * k, top + k + hy, 7 * k, k, lite)
        c.rect(x - 13 * k, top + 4 * k + hy, k, 3 * k, col)
        c.rect(x - 11 * k, top + 3 * k + hy, 4 * k, max(1, k / 2), dark)        // the cockpit slit
        c.rect(x - 17 * k, top + 7 * k + hy, 6 * k, max(1, k / 2), dark)        // chin guns
        c.rect(x - 15 * k, top + 2 * k + hy, 3 * k, max(1, k / 2), dark)        // temple gun
        for (i, u) in [2, 17].enumerated() { leg(u, swing: sin(phase + (i == 0 ? 0 : .pi)) * 3, far: false) }
    }

    static func snowfall(_ c: PixelCanvas, _ g: Int, t: Double) {
        guard c.w > 0, g > 0 else { return }
        // AT-ATs marching on the horizon toward the trench. Depth is solid colour, not transparency: the far ones
        // small and pale (washed toward the snowy haze), the near ones bigger, darker and faster. Drawn far to near.
        let horizon = g - 9, tall = isTall(c)
        let haze = C(0xD6DEE8), body = C(0x8A94A2), shadow = C(0x6C7684)
        let walkers: [(k: Int, speed: Double, fade: Double, start: Double)] =
            [(1, 0.9, 0.62, 0.85), (1, 1.1, 0.5, 0.15), (tall ? 3 : 2, 1.7, 0.12, 0.55)]
        for (i, w) in walkers.enumerated() {
            let k = w.k
            let span = Double(c.w + 60 * k)
            let x = Int(span - ((t * w.speed + w.start * span).truncatingRemainder(dividingBy: span))) - 30 * k
            let base = horizon + (k - 1) * 4 + i % 2
            distantATAT(c, x: x, base: base, k: k, phase: t * 1.4 * w.speed + Double(i),
                        col: lerp(body, haze, w.fade), dark: lerp(shadow, haze, w.fade))
            // now and then a red bolt from the head
            let f = (t * 0.6 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            if f < 0.18 {
                let hx = x - 7 * k, hy = base - 12 * k
                let d = Int(f / 0.18 * 40)
                c.rect(hx - d - 4, hy + d / 8, 4, 1, lerp(C(0xFF6A4A), haze, w.fade * 0.6))
                c.px(hx - d, hy + d / 8, lerp(C(0xFFD0A0), haze, w.fade * 0.6))
            }
        }
        // Now and then one passes close by: big, full colour, slow strides, behind the crew on the snowfield.
        let pass = (t / 100).truncatingRemainder(dividingBy: 1) * 100, crossing = 42.0
        if pass < crossing {
            // Whole pixels per unit, so sizes go in steps; rounding up lets it spill past the top of short scenes.
            let k = max(3, Int((Double(g) * 0.68 / 26).rounded()))   // always bigger than the nearest marcher (2 or 3)
            let travel = Double(c.w + 45 * k)
            let x = c.w + 18 * k - Int(pass / crossing * travel)
            nearATAT(c, x: x, base: g + (c.h - g) / 3, k: k, phase: pass * 1.07)
        }
        // a pair of snowspeeders streaking past now and then
        let sp = (t * 0.08).truncatingRemainder(dividingBy: 1)
        if sp < 0.25 {
            let u = sp / 0.25
            for (j, dy) in [0, 5].enumerated() {
                let x = Int(u * Double(c.w + 40)) - 20 - j * 10, y = 14 + dy + Int(sin(u * 6) * 2)
                c.rect(x, y, 6, 2, C(0xE8E4DC)); c.px(x + 5, y, C(0xE87A2A)); c.px(x, y + 1, C(0xC86A2A))
                c.rect(x - 3, y + 1, 3, 1, C(0xC8D8F0, 0.4))   // exhaust trail
            }
        }

        for i in 0..<(c.w / 3) {
            let x = Int((noise(i * 5) * Double(c.w) + t * (6 + noise(i * 5 + 1) * 6)).truncatingRemainder(dividingBy: Double(c.w)))
            let y = Int((noise(i * 5 + 2) * Double(g) + t * (10 + noise(i * 5 + 3) * 10)).truncatingRemainder(dividingBy: Double(g)))
            c.px(x, y, white.alpha(0.8))
        }
    }

    // The Rancor — its pit under Jabba's palace (Return of the Jedi): a craggy cave with stalactites, the trapdoor
    // grate in the ceiling pouring light down (Jabba's court peering through it, in `grateLight`), the heavy portcullis
    // half raised in a stone arch, the keepers' barred window, damp puddles, and bone piles with skulls, ribcages and
    // the big femur Luke jammed in its jaws.
    static func rancorPit(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x150F0A), C(0x3E3022), bands: 6)
        // Craggy rock: big boulder shapes in two tones, then grain.
        for i in 0..<34 {   // jagged rock faces: each row's width jitters, a lit top edge and a dark crack below
            let x = Int(noise(i * 5 + 300) * Double(c.w)), y = Int(noise(i * 5 + 301) * Double(g))
            let rx = 8 + Int(noise(i * 5 + 302) * 16), ry = 5 + Int(noise(i * 5 + 303) * 9)
            let col = noise(i * 5 + 304) > 0.5 ? C(0x2E2318, 0.85) : C(0x46372A, 0.75)
            for dy in -ry...ry {
                let k = 1 - Double(dy * dy) / Double(ry * ry)
                let jitter = Int((noise(i * 97 + dy + 50) - 0.5) * 6)
                let half = max(0, Int(Double(rx) * k.squareRoot()) + jitter)
                let left = x - half + Int((noise(i * 61 + dy) - 0.5) * 3)
                c.rect(left, y + dy, half * 2, 1, col)
                if dy == -ry + 1 { c.rect(left + 1, y + dy, max(1, half * 2 - 2), 1, C(0x6A5640, 0.6)) }   // lit top edge
            }
            c.rect(x - rx + 2, y + ry, rx * 2 - 4, 1, C(0x120C08, 0.7))     // the crack under it
        }
        for i in 0..<(c.w * g / 12) {
            c.px(Int(noise(i * 5) * Double(c.w)), Int(noise(i * 5 + 1) * Double(g)), noise(i * 5 + 2) > 0.5 ? C(0x241A12) : C(0x5A4834))
        }
        // Stalactites along the top.
        for i in 0..<30 {
            let x = Int(noise(i * 3 + 500) * Double(c.w)), len = 3 + Int(noise(i * 3 + 501) * 9)
            for k in 0..<len { let w = max(1, (len - k) / 3); c.rect(x - w / 2, k, w, 1, C(0x241A12)) }
        }
        if isTall(c) { rancorHigh(c, g) }
        // Dark edges: the pit closes in at the sides.
        for x in 0..<28 { c.rect(x, 0, 1, g, C(0x0A0705, 0.5 * Double(28 - x) / 28)); c.rect(c.w - 1 - x, 0, 1, g, C(0x0A0705, 0.5 * Double(28 - x) / 28)) }

        // The trapdoor grate in the ceiling (left of centre), its rim.
        let tx = c.w / 3
        c.ellipse(tx, 2, 22, 4, C(0x0A0705)); c.ellipse(tx, 2, 20, 3, C(0xF2D8A0, 0.5))
        for x in stride(from: tx - 18, through: tx + 18, by: 4) { c.rect(x, 0, 1, 5, C(0x3A2E22)) }

        // The keepers' barred window, high on the right wall.
        let wx = c.w * 3 / 4 - 50, wy = g - 52
        c.rect(wx - 1, wy - 1, 20, 12, C(0x5A4A38)); c.rect(wx, wy, 18, 10, C(0x0E0A06))
        c.rect(wx + 2, wy + 6, 14, 4, C(0xFFB050, 0.12))                   // torchlight inside
        for x in stride(from: wx + 2, to: wx + 18, by: 4) { c.rect(x, wy, 1, 10, C(0x7A7266)) }

        // The heavy portcullis in a stone arch (right), half raised, with its chain.
        let gx = c.w * 3 / 4, gw = 40, top = g - 44
        for y in top..<g {                                                 // the arch of fitted stones
            let r = gw / 2 + 5, dy = y - top
            var half = r
            if dy < r { half = Int((Double(r * r) - Double((r - dy) * (r - dy))).squareRoot()) }
            c.rect(gx - half, y, half * 2, 1, (y / 4 + (y % 2)) % 2 == 0 ? C(0x6A5A46) : C(0x5A4A38))
        }
        for y in (top + 5)..<g {                                           // the dark passage beyond
            let r = gw / 2, dy = y - top - 5
            var half = r
            if dy < r { half = Int((Double(r * r) - Double((r - dy) * (r - dy))).squareRoot()) }
            c.rect(gx - half, y, half * 2, 1, C(0x0A0705))
        }
        let raised = g - 14                                                // bars stop here: the gate is half up
        for x in stride(from: gx - gw / 2 + 2, to: gx + gw / 2 - 1, by: 5) {
            c.rect(x, top + 8, 2, raised - top - 8, C(0x6E6A60)); c.rect(x, top + 8, 1, raised - top - 8, C(0x8E8A80))
            c.rect(x, raised - 1, 2, 3, C(0x8E8A80))                       // spiked ends
        }
        for y in stride(from: top + 14, to: raised, by: 9) { c.rect(gx - gw / 2 + 1, y, gw - 2, 2, C(0x5A564E)) }
        for k in 0..<12 { c.px(gx + gw / 2 + 4, top + 2 + k * 2, C(0x8A8274)); c.px(gx + gw / 2 + 5, top + 3 + k * 2, C(0x6A6458)) }   // chain

        // Floor: damp stone, puddles, rubble.
        c.ground(g, C(0x2E241A), edge: C(0x4A3A2C), speck: C(0x241A12), seed: 21)
        for (px, pw) in [(c.w / 3 - 10, 24), (c.w / 2 + 40, 16)] { c.ellipse(px, g + 3, pw / 2, 1, C(0x5A6A6A, 0.5)); c.rect(px - pw / 4, g + 3, pw / 2, 1, C(0xA8B8B0, 0.3)) }

        // Bone piles in the corners: skulls, ribcages, long bones — and the big femur.
        func skull(_ x: Int, _ y: Int, big: Bool = false) {
            let r = big ? 4 : 2
            c.ellipse(x, y, r + 1, r, C(0xE0D2B4)); c.rect(x - r / 2 - 1, y + r - 1, r + 2, 2, C(0xD0C2A4))
            c.px(x - r / 2, y, C(0x1A140F)); c.px(x + r / 2, y, C(0x1A140F))
            if big { c.px(x - r / 2 + 1, y, C(0x1A140F)); c.px(x + r / 2 - 1, y, C(0x1A140F)) }
        }
        func pile(_ cx: Int, _ rx: Int, _ ry: Int, seed: Int) {
            c.ellipse(cx, g, rx, ry, C(0x8A7C64)); c.ellipse(cx, g + 1, rx - 2, ry - 2, C(0xA89A7E))
            for i in 0..<(rx * ry / 6) {
                let u = noise(seed * 50 + i * 2) * 2 - 1
                let x = cx + Int(u * Double(rx - 2)), y = g - Int(Double(ry) * (1 - u * u).squareRoot() * noise(seed * 50 + i * 2 + 1)) - 1
                switch i % 5 {
                case 0: skull(x, y - 1)
                case 1: c.rect(x - 3, y, 7, 1, C(0xE8DCC0)); c.px(x - 4, y - 1, C(0xE8DCC0)); c.px(x + 4, y + 1, C(0xE8DCC0))
                case 2: for k in 0..<4 { c.rect(x - 3 + k * 2, y - 2, 1, 3, C(0xD8CAAC)) }   // ribs
                default: c.px(x, y, C(0xE8DCC0)); c.px(x + 1, y, C(0xC8BA9C))
                }
            }
        }
        pile(20, 30, 14, seed: 1)
        pile(c.w - 18, 26, 12, seed: 2)
        skull(c.w - 30, g - 13, big: true)                                  // something big didn't make it
        // the femur Luke jammed in the rancor's jaws, lying where it fell
        let fx = c.w / 2 - 70
        c.rect(fx, g + 1, 18, 2, C(0xE8DCC0)); c.ellipse(fx, g + 2, 2, 2, C(0xE8DCC0)); c.ellipse(fx + 18, g + 2, 2, 2, C(0xE8DCC0))
        // scattered bones on the floor
        for (i, x) in stride(from: 40, to: c.w - 40, by: 37).enumerated() {
            let y = g + 3 + Int(noise(i * 3) * 3)
            c.rect(x, y, 5, 1, C(0xD8CAAC)); c.px(x - 1, y - 1, C(0xD8CAAC))
        }
    }

    static func grateLight(_ c: PixelCanvas, _ g: Int, t: Double) {
        // A strong shaft of light falling through the ceiling grate, the bars' shadows in it, and dust drifting.
        let x0 = c.w / 3
        for y in 3..<g {
            let spread = 18 + y / 3
            c.rect(x0 - spread, y, spread * 2, 1, C(0xF2D8A0, 0.09))
            for x in stride(from: x0 - 16, through: x0 + 16, by: 4) { c.px(x + (x - x0) * y / 60, y, C(0x0A0705, 0.08)) }
        }
        c.ellipse(x0, g + 2, 34, 2, C(0xF2D8A0, 0.12))                     // the pool of light on the floor
        for i in 0..<16 {
            let y = Int((noise(i * 7) * Double(g) + t * (3 + noise(i * 7 + 1) * 3)).truncatingRemainder(dividingBy: Double(g)))
            c.px(x0 - 16 + Int(noise(i * 7 + 2) * 32) + y / 6, y, C(0xF2D8A0, 0.5))
        }
        // Jabba's court peering over the edge of the grate.
        for (i, dx) in [-14, -5, 6, 15].enumerated() {
            let bob = Int(sin(t * 1.3 + Double(i) * 1.7) * 1.5)
            let up = (t * 0.2 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1) < 0.75
            if up { c.ellipse(x0 + dx, 1 + bob, 3, 2, C(0x1A140F)); if i == 1 { c.px(x0 + dx - 1, 1 + bob, C(0xE0A040)) } }
        }
        // water dripping from the ceiling
        for (i, dxp) in [0.2, 0.62, 0.88].enumerated() {
            let p = (t * 0.6 + Double(i) * 0.41).truncatingRemainder(dividingBy: 1)
            let x = Int(dxp * Double(c.w)), y = Int(p * p * Double(g))
            c.px(x, y, C(0xA8C8D0, 0.7))
            if p > 0.95 { c.px(x - 1, g + 1, C(0xA8C8D0, 0.6)); c.px(x + 1, g + 1, C(0xA8C8D0, 0.6)) }
        }
    }

    /// The Max Rebo Band in Jabba's palace, as in the original Return of the Jedi: Max Rebo at his red ball jett
    /// organ, Sy Snootles singing into the mic, Droopy McCool (eyeless Kitonak) on his chindinkalu flute.
    static func maxReboBand(_ c: PixelCanvas, _ g: Int, t: Double, at x: Int? = nil) {
        let x0 = x ?? c.w - 64                           // Jabba's palace: the right side of the throne room
        guard x != nil || x0 > 60 else { return }
        func bob(_ k: Double) -> Int { (t * 2.2 + k).truncatingRemainder(dividingBy: 1) < 0.5 ? 0 : -1 }

        // Max Rebo: small blue Ortolan with floppy ears and a trunk, at the red ball organ
        c.oy = bob(0)
        let blue = C(0x5A8AD8), blueDark = C(0x3E6AB0)
        c.ellipse(x0 + 8, g - 7, 6, 5, blue)
        c.rect(x0 + 1, g - 12, 4, 5, blueDark); c.rect(x0 + 12, g - 12, 4, 5, blueDark)       // ears
        c.px(x0 + 6, g - 9, C(0x101010)); c.px(x0 + 10, g - 9, C(0x101010))                  // eyes
        c.rect(x0 + 8, g - 7, 1, 4, blueDark); c.px(x0 + 9, g - 3, blueDark)                  // trunk
        c.oy = 0
        c.ellipse(x0 + 8, g - 3, 7, 3, C(0xC8303A))                                           // the organ
        for k in 0..<5 { c.px(x0 + 3 + k * 2, g - 5, (Int(t * 5) + k) % 4 == 0 ? C(0xFFE27A) : white) }

        // Sy Snootles: thin yellow-green singer with a long-lipped snout, at a microphone stand
        let sx = x0 + 26
        c.oy = bob(0.33)
        let sy = C(0xB8C860), syDark = C(0x8A9A40)
        c.rect(sx + 1, g - 9, 1, 9, syDark); c.rect(sx + 4, g - 9, 1, 9, syDark)            // spindly legs
        c.ellipse(sx + 3, g - 11, 3, 3, sy)                                                    // body
        c.rect(sx + 2, g - 17, 3, 4, sy)                                                       // head
        c.px(sx + 2, g - 16, C(0x101010)); c.px(sx + 4, g - 16, C(0x101010))
        c.rect(sx + 5, g - 15, 4, 1, C(0xD86A7A))                                              // the long lips
        c.oy = 0
        c.rect(sx + 9, g - 15, 1, 15, C(0x9AA0A8)); c.rect(sx + 8, g - 16, 3, 2, C(0x3A3A42)) // mic stand

        // Droopy McCool: chubby, eyeless pale Kitonak playing his chindinkalu flute
        let dx = x0 + 44
        c.oy = bob(0.66)
        let pale = C(0xD8D4CC), paleDark = C(0xB0ACA4)
        c.ellipse(dx + 6, g - 7, 6, 7, pale)
        c.rect(dx + 2, g - 3, 9, 3, paleDark)
        c.rect(dx + 4, g - 11, 5, 1, paleDark)                                                 // folds where eyes would be
        c.rect(dx + 7, g - 9, 8, 1, C(0x8A6A48))                                               // the slim wooden flute
        c.px(dx + 9, g - 9, C(0x5A4636)); c.px(dx + 11, g - 9, C(0x5A4636)); c.px(dx + 13, g - 9, C(0x5A4636))
        c.oy = 0

        // notes
        let f = (t / 1.4).truncatingRemainder(dividingBy: 1)
        c.pattern(x0 + 20, g - 24 - Int(f * 8), ["..N", "..N", "NNN", "NN."], ["N": C(0xFFC86A, 1 - f)])
    }
}

// MARK: - Full-screen extras

// The screensaver draws each place full screen, several times taller than the window's strip, which would leave the
// upper part bare. These fill it with more of the same place, in the same palette. The window's strip is never
// `tallRows` rows tall, so it draws exactly what it always did.
extension Scenes {
    static let tallRows = 140
    static func isTall(_ c: PixelCanvas) -> Bool { c.h >= tallRows }
    /// Whole-pixel size of one unit of the extras: 1, growing on very tall canvases so they keep their size on screen.
    static func unit(_ g: Int) -> Int { max(1, (g + 60) / 300) }

    /// Draws in units of `s` pixels from an origin.
    struct Pen {
        let c: PixelCanvas, x: Int, y: Int, s: Int
        init(_ c: PixelCanvas, _ x: Int, _ y: Int, _ g: Int) { self.c = c; self.x = x; self.y = y; s = Scenes.unit(g) }
        func rect(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
        func ellipse(_ u: Int, _ v: Int, _ rx: Int, _ ry: Int, _ col: Px) { c.ellipse(x + u * s, y + v * s, rx * s, ry * s, col) }
        func circle(_ u: Int, _ v: Int, _ r: Int, _ col: Px) { c.circle(x + u * s, y + v * s, r * s, col) }
    }

    /// A soft fair-weather cloud: a shaded flat base under a few puffs.
    static func cloud(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, seed: Int, top: Px = C(0xF6F9FC), base: Px = C(0xDDE9F3)) {
        c.ellipse(x, y + r / 2, r * 3, max(1, r / 2), base)
        for k in 0..<4 {
            let dx = Int((noise(seed * 7 + k) - 0.5) * Double(r * 4)), rr = r * (2 + k % 2) / 3 + 1
            c.ellipse(x + dx, y - rr / 3, rr * 3 / 2, rr, top)
        }
    }

    /// A thin streak of high cloud, `len` pixels long.
    static func wisp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, _ col: Px, s: Int) {
        c.rect(x - len / 2, y, len, s, col)
        c.rect(x - len / 3, y - s, len / 2, s, col.alpha(0.7))
        c.rect(x - len / 6, y + s, len / 2, s, col.alpha(0.6))
    }

    /// A flat-topped mesa with sloping flanks, `h` rows tall, standing on row `base`.
    static func mesa(_ c: PixelCanvas, x: Int, width: Int, h: Int, base: Int, _ col: Px, seed: Int) {
        let flankW = max(1, width / 5)
        for k in 0..<width {
            let flank = max(0, max(flankW - k, k - (width - flankW))) * h / (flankW * 2)
            let top = base - h + flank + Int(noise(k + seed * 31) * 2)
            if top < base { c.rect(x + k, top, 1, base - top, col) }
        }
    }

    // Naboo: the moons by day, big clouds, hazy mountains, and Theed on its cliffs with the waterfalls pouring off.
    static func nabooFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.circle(c.w / 9, g / 6, 5 * s, C(0xEEF4F8, 0.5)); c.circle(c.w / 9 + 14 * s, g / 6 + 5 * s, 2 * s, C(0xEEF4F8, 0.4))
        for (i, (fx, fy, r)) in [(0.32, 0.13, 7), (0.66, 0.07, 9), (0.9, 0.22, 5), (0.06, 0.3, 4), (0.5, 0.3, 4)].enumerated() {
            cloud(c, Int(Double(c.w) * fx), Int(Double(g) * fy), r * s, seed: i)
        }
        c.dunes(base: g - g / 9, amp: Double(g) / 24, freq: 0.016, phase: 3, bottom: g, C(0xAECCE2), shade: C(0xC0D8EA))
        // Theed: the palace's great dome and towers on a plateau, falls dropping down the cliff face
        let mid = c.w * 4 / 5, half = 50 * s, top = g - g / 5
        for x in max(0, mid - half - 30 * s)..<min(c.w, mid + half + 30 * s) {
            let y = top + max(0, abs(x - mid) - half) * 2 / 3 + Int(noise(x * 3 + 7) * 2)
            c.rect(x, y, 1, g - y, (x / (3 * s)) % 4 == 0 ? C(0x98B6CC) : C(0xA2C0D6))
        }
        let p = Pen(c, mid, top, g)
        let stone = C(0xD8E0E4), shade = C(0xBCCAD4), dome = C(0x8CB4A8), domeLit = C(0xA8CCC0)
        p.rect(-46, -5, 16, 5, shade); p.ellipse(-38, -5, 5, 3, dome)
        p.rect(30, -4, 18, 4, shade); p.ellipse(39, -4, 4, 2, dome)
        p.rect(-28, -15, 6, 15, stone); p.ellipse(-25, -16, 3, 3, dome)
        p.rect(22, -12, 6, 12, stone); p.ellipse(25, -13, 3, 3, dome)
        p.ellipse(0, -11, 12, 9, dome); p.ellipse(-3, -14, 5, 4, domeLit)
        p.rect(-20, -9, 40, 9, stone); p.rect(-20, -9, 40, 1, C(0xEEF2F4))
        for k in stride(from: -18, to: 20, by: 4) { p.rect(k, -7, 1, 6, shade) }
        for k in [-50, -45, -36, 31, 38, 47] {                       // falls streaming off the cliff below the city
            let x = mid + k * s
            for y in (top + 1)..<(g - 14) { c.rect(x, y, s, 1, C(0xF2F8FC, (y / 2 + k) % 3 == 0 ? 0.35 : 0.7)) }
            c.ellipse(x, g - 15, 4 * s, 2 * s, C(0xFFFFFF, 0.3))
        }
    }

    /// The Gungan army's shield on the plains, with the army drawn up under it.
    static func gunganShield(_ c: PixelCanvas, _ g: Int) {
        let cx = c.w / 6, rx = max(40, c.w / 7), ry = g / 4, cy = g - 6
        c.ellipse(cx, cy, rx, ry, C(0xB8FFD8, 0.10))
        for x in (cx - rx)...(cx + rx) {
            let u = Double(x - cx) / Double(rx)
            let y = cy - Int(Double(ry) * max(0, 1 - u * u).squareRoot())
            c.px(x, y, C(0xE0FFEC, 0.5)); c.px(x, y + 1, C(0xC8FFE0, 0.2))
        }
        for i in 0..<18 {
            let x = cx - rx * 2 / 3 + i * rx * 4 / 3 / 18
            c.rect(x, g - 9 - i % 2, 1, 3, C(0x4E6A44)); if i % 3 == 0 { c.px(x, g - 11 - i % 2, C(0x8A6A3A)) }
        }
    }

    // The Great Pit of Carkoon: the twin suns high over the Dune Sea and far rocks on the horizon.
    static func carkoonSky(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), sx = c.w * 4 / 5, sy = g / 9
        for (dx, dy, r) in [(0, 0, 5), (18, 8, 4)] {
            c.circle(sx + dx * s, sy + dy * s, r * 3 * s, C(0xFFF6DC, 0.12)); c.circle(sx + dx * s, sy + dy * s, r * s, C(0xFFFBEA))
        }
        mesa(c, x: c.w / 30, width: 60 * s, h: g / 9, base: g - 8, C(0xDDC39A), seed: 1)
        mesa(c, x: c.w * 11 / 20, width: 36 * s, h: g / 14, base: g - 8, C(0xDDC39A), seed: 2)
        c.dunes(base: g - 15, amp: 4, freq: 0.02, phase: 2.4, bottom: g, C(0xE6CC9E), shade: C(0xEED8B0))
    }

    /// Jabba's sail barge, the Khetanna, full size: the hull with its rail and ports, the upper-deck cabin, two masts
    /// with their sails, and the court crowding the deck. (x, y) is the top of the hull at the prow end.
    static func sailBarge(_ c: PixelCanvas, _ x: Int, _ y: Int, _ g: Int) {
        let p = Pen(c, x, y, g)
        let hull = C(0x8A6A48), hullLit = C(0xA0805A), hullDark = C(0x6E5236), wood = C(0x5A4636), sail = C(0xE6D6B4), sailShade = C(0xCDBB98)
        p.rect(-5, 0, 5, 3, hull); p.rect(-2, 3, 2, 3, hullDark)                                   // the prow
        p.rect(0, 0, 104, 3, hullLit); p.rect(1, 3, 102, 6, hull); p.rect(8, 9, 90, 3, hullDark); p.rect(18, 12, 70, 2, wood)
        for k in stride(from: 8, to: 98, by: 6) { p.rect(k, 5, 2, 1, C(0x3A2A1E)) }               // ports
        p.rect(104, -3, 4, 11, hull)                                                               // the stern
        p.rect(0, -3, 104, 1, wood); for k in stride(from: 0, to: 104, by: 5) { p.rect(k, -2, 1, 2, wood) }   // the rail
        p.rect(54, -13, 40, 11, C(0x7A5C3E)); p.rect(52, -14, 44, 1, hullLit)                     // the cabin
        for k in stride(from: 57, to: 92, by: 5) { p.rect(k, -10, 2, 3, C(0x2A1C12)) }
        p.rect(8, -9, 34, 1, sailShade); for k in [9, 24, 40] { p.rect(k, -8, 1, 6, wood) }          // the deck awning
        for (k, col) in [(12, C(0x3A3028)), (16, C(0x6A5A44)), (20, C(0x3A3028)), (30, C(0x5A4A3A)), (35, C(0x3A3028))] {
            p.rect(k, -6, 2, 4, col); p.rect(k, -7, 2, 1, C(0xC8A888))                             // the court on deck
        }
        p.rect(30, -40, 1, 38, wood); p.rect(31, -38, 19, 24, sail); p.rect(48, -38, 2, 24, sailShade)
        for v in [-32, -26, -20] { p.rect(31, v, 19, 1, sailShade) }
        p.rect(70, -50, 1, 37, wood); p.rect(71, -48, 16, 28, sail); p.rect(85, -48, 2, 28, sailShade)
        for v in [-41, -34, -27] { p.rect(71, v, 16, 1, sailShade) }
        p.rect(70, -52, 6, 2, C(0xA83A2A))                                                        // a pennant
    }

    /// Two desert skiffs hovering by the pit, one with the plank run out over the sarlacc.
    static func skiffs(_ c: PixelCanvas, _ g: Int) {
        let pit = c.w * 3 / 4, s = unit(g)
        for (x, y, plank) in [(pit + 6 * s, g - g / 5, true), (pit - 110 * s, g - g / 4 - 8 * s, false)] {
            let p = Pen(c, x, y, g)
            p.rect(-2, 1, 2, 2, C(0xB4A27E)); p.rect(0, 0, 32, 3, C(0xB4A27E)); p.rect(0, 0, 32, 1, C(0xD0BE98))
            p.rect(3, 3, 26, 2, C(0x7E6E56))
            p.rect(0, -4, 32, 1, C(0x6E5E48)); for k in stride(from: 0, to: 33, by: 4) { p.rect(k, -3, 1, 3, C(0x6E5E48)) }
            p.rect(29, -7, 3, 7, C(0x8A7A60))
            for (k, col) in [(7, C(0x3A3028)), (13, C(0x6A5A44)), (19, C(0x3A3028))] { p.rect(k, -7, 2, 7, col); p.rect(k, -9, 2, 2, C(0xC8A888)) }
            if plank { p.rect(-14, 0, 14, 1, C(0x8A6A48)) }
            c.ellipse(x + 16 * s, g - 6, 17 * s, 1, C(0xB89868, 0.35))
        }
    }

    // Jabba's palace: an arcade along the upper wall, where the court watches from the dark.
    static func jabbaArcade(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), top = g / 7, bottom = top + g / 6, r = 12 * s
        var x = 18
        var i = 0
        while x + r * 2 < c.w {
            for y in top..<bottom {
                var half = r
                if y - top < r { let dy = Double(r - (y - top)); half = Int((Double(r * r) - dy * dy).squareRoot()) }
                c.rect(x + r - half - s, y, half * 2 + 2 * s, 1, C(0x7A5838, 0.45))
                c.rect(x + r - half, y, half * 2, 1, lerp(C(0x140D08), C(0x3A2416), Double(y - top) / Double(bottom - top)))
            }
            c.ellipse(x + r, bottom - 2, r - 2, 3 * s, C(0xFFB050, 0.08))
            if i % 3 == 1 {                                                          // someone watching
                c.ellipse(x + r, bottom - 6 * s, 3 * s, 3 * s, C(0x0E0905)); c.rect(x + r - 4 * s, bottom - 3 * s, 8 * s, 3 * s, C(0x0E0905))
                c.px(x + r - 1, bottom - 7 * s, C(0xE0A040, 0.8)); c.px(x + r + 1, bottom - 7 * s, C(0xE0A040, 0.8))
            }
            x += r * 2 + 20 * s; i += 1
        }
        c.rect(0, bottom, c.w, 3 * s, C(0x4E3624)); c.rect(0, bottom, c.w, 1, C(0x8A6444, 0.7))
        for bx in stride(from: 0, to: c.w, by: 4 * s) { c.rect(bx, bottom + 3 * s, 2 * s, 5 * s, C(0x3A2818, 0.8)) }
        c.rect(0, bottom + 8 * s, c.w, 1, C(0x2A1C12, 0.7))
    }

    // Snoke's throne room: the drapes vanishing into the dark overhead under a black rail, soft spotlights down them,
    // the throne's high back, and more Praetorian guards along the room.
    static func supremacyHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), fade = g * 2 / 5
        for fx in [0.17, 0.39, 0.61, 0.83] {
            let x = Int(Double(c.w) * fx)
            for y in (g / 14)..<g { let sp = 3 * s + y / 7; c.rect(x - sp, y, sp * 2, 1, C(0xFF6A58, 0.05)) }
        }
        for y in 0..<fade {
            let k = (Double(fade - y) / Double(fade) * 6).rounded(.up) / 6
            c.rect(0, y, c.w, 1, C(0x100204, 0.75 * k))
        }
        let rail = max(3, g / 30)
        c.rect(0, 0, c.w, rail, C(0x0C0B0D))
        for x in stride(from: 0, to: c.w, by: 14) {
            for k in 0..<14 { let y = rail + Int(sin(Double(k) / 14 * .pi) * 3); c.px(x + k, y, C(0x2A0408)); c.px(x + k, y - 1, C(0x1A0205)) }
            c.rect(x, rail - 1, 2, 2, C(0x3A3A40))
        }
        let tx = c.w / 2
        c.rect(tx - 9, g - 52, 18, 36, C(0x111114)); c.rect(tx - 9, g - 52, 18, 1, C(0x2E2E36)); c.rect(tx - 9, g - 52, 1, 36, C(0x24242A))
        for gx in [tx - 76, tx - 112, tx + 70, tx + 106] where gx > 4 && gx < c.w - 10 {
            c.rect(gx, g - 16, 6, 16, C(0xC8202A)); c.rect(gx + 1, g - 19, 4, 3, C(0xC8202A))
            c.rect(gx + 6, g - 22, 1, 20, C(0x8A8F9C))
        }
    }

    // The Theed generator: generator pods in the far wall and dimmer catwalks between the near ones.
    static func theedDepth(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for fx in [0.17, 0.47, 0.8] {
            let cx = Int(Double(c.w) * fx), r = 11 * s
            for dx in -r...r { c.rect(cx + dx, 0, 1, g, lerp(C(0x324058), C(0x1C2432), pow(abs(Double(dx)) / Double(r), 2))) }
            for y in stride(from: 6, to: g, by: 16 * s) { c.rect(cx - r, y, r * 2 + 1, s, C(0x18202C)) }
            c.rect(cx, 0, s, g, C(0x7AC8FF, 0.16))
        }
        for y in stride(from: g / 6, to: g - 12, by: max(8, g / 6)) where abs(y - g / 3) > 6 && abs(y - g * 2 / 3) > 6 {
            c.rect(0, y, c.w, 2 * s, C(0x3A465C)); c.rect(0, y - 4 * s, c.w, 1, C(0x323C50))
            for x in stride(from: 2, to: c.w, by: 7 * s) { c.rect(x, y - 4 * s, 1, 4 * s, C(0x323C50)) }
        }
    }

    /// A second run of laser gates up on the high catwalk.
    static func theedUpperGates(_ c: PixelCanvas, _ g: Int) {
        let lx = c.w * 3 / 5, y = g / 3
        for i in 0..<4 { c.rect(lx + i * 12, y - 26, 3, 26, C(0x4E5A72)) }
        c.rect(lx - 2, y - 28, 43, 2, C(0x4E5A72))
    }

    // The Death Star corridor: a ceiling with its light slots, a conduit along the wall and a blast door.
    static func deathStarHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), ceil = g / 14
        c.rect(0, 0, c.w, ceil, C(0x1E2025)); c.rect(0, ceil, c.w, 2, C(0x15171B))
        for x in stride(from: 8, to: c.w, by: 24) { c.rect(x, ceil - 5, 10, 2, C(0x9EA6B2)); c.rect(x + 1, ceil - 5, 8, 1, C(0xE8F0FF)) }
        let y = g * 3 / 10
        c.rect(0, y, c.w, 9 * s, C(0x24272D)); c.rect(0, y, c.w, 1, C(0x5A606C)); c.rect(0, y + 9 * s, c.w, 1, C(0x15171B))
        for k in 0..<3 { c.rect(0, y + (2 + k * 2) * s, c.w, 1, C(0x30343B)) }
        for x in stride(from: 20, to: c.w, by: 48) { c.rect(x, y - s, 4 * s, 11 * s, C(0x1E2025)) }
        let dw = 36 * s, dx = c.w / 6, top = g - g * 2 / 5, cham = 8 * s
        for yy in top..<g {
            let inset = max(0, cham - (yy - top))
            c.rect(dx - dw / 2 - 3 * s + inset, yy, dw + 6 * s - inset * 2, 1, C(0x15171B))
            if yy >= top + 3 * s {
                let i2 = max(0, cham - (yy - top - 3 * s))
                c.rect(dx - dw / 2 + i2, yy, dw - i2 * 2, 1, yy % (6 * s) == 0 ? C(0x34373F) : C(0x3A3E46))
            }
        }
        c.rect(dx, top + 3 * s, 1, g - top, C(0x15171B))
        c.rect(dx - 4 * s, top - 4 * s, 2 * s, s, C(0xE0303A)); c.rect(dx + 2 * s, top - 4 * s, 2 * s, s, C(0x3BD15A))
    }

    /// TIE fighters crossing the Death Star's viewport, or in a flight of three past the Executor's windows.
    static func tieFlyby(_ c: PixelCanvas, _ g: Int, t: Double, viewport: Bool) {
        let s = unit(g)
        let x0: Int, x1: Int, y0: Int, y1: Int, y: Int
        if viewport {
            let v = deathStarViewport(c, g); x0 = v.minX; x1 = v.minX + v.width; y0 = v.minY; y1 = v.minY + v.height; y = v.minY + v.height / 3
        } else { x0 = 0; x1 = c.w; y0 = 6; y1 = g - 14; y = 6 + (g - 20) / 10 }
        let p = (t / (viewport ? 11 : 17)).truncatingRemainder(dividingBy: 1) * 2.5   // crosses in the first 40% of the period
        guard p < 1 else { return }
        let tie = ["W.....W", "W.....W", "W.BBB.W", "WSBBBSW", "W.BBB.W", "W.....W", "W.....W"]
        let pal: [Character: Px] = ["W": C(0x5A606C), "B": C(0x9AA0AC), "S": C(0x6E7480)]
        for k in 0..<(viewport ? 1 : 3) {
            let x = x0 - 20 * s + Int(p * Double(x1 - x0 + 40 * s)) - k * 16 * s, yy = y + (k == 0 ? 0 : (k == 1 ? -6 : 6)) * s
            for (r, row) in tie.enumerated() {
                for (q, ch) in row.enumerated() {
                    guard let col = pal[ch] else { continue }
                    for a in 0..<s { for b in 0..<s {
                        let px = x + q * s + a, py = yy + r * s + b
                        guard px >= x0, px < x1, py >= y0, py < y1, viewport ? !deathStarBar(c, g, x: px) : px % 22 >= 2 else { continue }
                        c.px(px, py, col)
                    } }
                }
            }
        }
    }

    // The Death Star II throne room: panelled walls, and a ceiling band.
    static func emperorWalls(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in stride(from: 0, to: c.w, by: 18 * s) { c.rect(x, 0, 1, g, C(0x272A31)) }
        for y in stride(from: g / 14, to: g, by: 14 * s) { c.rect(0, y, c.w, 1, C(0x272A31)) }
        c.rect(0, 0, c.w, g / 14, C(0x15161A)); c.rect(0, g / 14, c.w, 1, C(0x3A3D46))
    }

    /// The two staircases climbing from the edges of the room toward the throne platform.
    static func emperorStairs(_ c: PixelCanvas, _ g: Int) {
        let cx = c.w / 2, r = max(12, min(g / 2 - 2, c.w / 5))
        let rise = g / 4, x0 = 6, x1 = cx - r - 8, step = 3
        guard x1 - x0 > 40 else { return }
        let run = x1 - x0
        for side in [-1, 1] {
            for i in 0...(run + 14) {
                let x = side < 0 ? x0 + i : c.w - 1 - x0 - i
                let lift = min(rise, i * rise / run)
                let top = g - lift / step * step - step
                c.rect(x, top, 1, g - top, C(0x18191E)); c.px(x, top, C(0x3A3D46))
                let rail = g - lift - step - 10
                c.px(x, rail, C(0x3A3D46))
                if i % 9 == 0 { c.rect(x, rail, 1, top - rail, C(0x2E3138)) }
            }
        }
    }

    // Geonosis: the planet's ring arching over the sky, droid core ships landed in the haze, and far spires.
    static func geonosisFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in 0..<c.w {
            let u = Double(x) / Double(c.w) * 2 - 1
            let y = Int(Double(g) * (0.06 + 0.13 * (u + 1) / 2 + 0.06 * u * u))
            c.rect(x, y, 1, 3 * s, C(0xFFF0D8, 0.22)); c.rect(x, y + s, 1, s, C(0xC8784A, 0.18))
            if noise(x * 7 + 300) > 0.9 { c.px(x, y - 2 * s + Int(noise(x * 7 + 301) * Double(7 * s)), C(0x8A4A30, 0.5)) }
        }
        for (fx, fr, dy) in [(0.3, 0.17, 4), (0.76, 0.11, 2)] {
            let cx = Int(Double(c.w) * fx), r = Int(Double(g) * fr), cy = g - dy
            c.circle(cx, cy, r, C(0xD48E68)); c.circle(cx - r / 6, cy - r / 6, r * 3 / 4, C(0xDC9C74))
            c.rect(cx - r, cy - r / 5, r * 2 + 1, max(1, r / 12), C(0xC28060))
            c.rect(cx - r / 2, cy - r - 2 * s, s, 3 * s, C(0xC28060))
        }
        for (i, x) in stride(from: 24, to: c.w, by: 51).enumerated() {
            let hgt = Int(Double(g) * (0.4 + noise(i * 3 + 200) * 0.3)), wid = 8 + Int(noise(i * 3 + 201) * 8)
            c.rect(x, g - hgt, wid, hgt, C(0xE2A27A)); c.rect(x - 3, g - hgt / 2, wid + 6, hgt / 2, C(0xE2A27A))
            c.rect(x, g - hgt, 2, hgt, C(0xEAB088))
        }
    }

    // The Executor's bridge: a planet low in the windows and a Star Destroyer close alongside.
    static func executorView(_ c: PixelCanvas, _ g: Int) {
        let top = 6, bottom = g - 14
        let pr = g * 2 / 5, pcx = c.w * 4 / 5, pcy = bottom + pr / 2
        for y in max(top, pcy - pr)..<bottom {
            let dy = Double(y - pcy), half = Int((Double(pr * pr) - dy * dy).squareRoot())
            for x in max(0, pcx - half)..<min(c.w, pcx + half + 1) {
                let lx = Double(x - pcx + pr / 3), ly = dy + Double(pr / 3)
                let lit = lx * lx + ly * ly < Double(pr * pr)
                let band = (y / 5 + x / 40) % 3 == 0
                c.px(x, y, lit ? (band ? C(0x8A9CB4) : C(0x7E90A8)) : C(0x1E2633))
            }
        }
        let len = c.w * 3 / 10, nx = c.w / 10, ny = top + (bottom - top) / 6
        for i in 0..<len {
            let t0 = ny - i * 6 / 100, mid = ny + i * 9 / 100, b0 = ny + i * 22 / 100
            c.rect(nx + i, t0, 1, mid - t0 + 1, C(0x7A808C)); c.rect(nx + i, mid, 1, b0 - mid + 1, C(0x5A5F6A))
            c.px(nx + i, t0, C(0xA8AEB8))
        }
        for (from, rise) in [(0.55, 4), (0.7, 8), (0.82, 12)] {
            let x0 = nx + Int(Double(len) * from)
            for x in x0..<(nx + len) { let tp = ny - (x - nx) * 6 / 100 - rise; c.rect(x, tp, 1, rise, C(0x868C98)); c.px(x, tp, C(0xA8AEB8)) }
        }
        let bx = nx + len - len / 10, by = ny - (bx - nx) * 6 / 100 - 12
        c.rect(bx - 2, by - 5, 4, 5, C(0x868C98)); c.rect(bx - 7, by - 7, 14, 2, C(0x9AA0AA))
        c.circle(bx - 6, by - 8, 1, C(0x9AA0AA)); c.circle(bx + 6, by - 8, 1, C(0x9AA0AA))
        let sternTop = ny - len * 6 / 100, sternBottom = ny + len * 22 / 100
        for k in 0..<3 { c.circle(nx + len, sternTop + (sternBottom - sternTop) * (k + 1) / 4, 2, C(0x8AC8FF, 0.8)) }
    }

    // The Lars homestead at dusk: first stars, a pale moon, thin lit clouds and far mesas.
    static func larsSky(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.stars(0, g / 5, density: 110, seed: 23)
        let mx = c.w / 7, my = g / 9
        c.circle(mx, my, 6 * s, C(0xF2E4EC, 0.85)); c.circle(mx + 3 * s, my - 2 * s, 6 * s, C(0x5A4A8A))
        for i in 0..<5 {
            let x = Int(noise(i * 3 + 400) * Double(c.w)), y = Int(Double(g) * (0.3 + Double(i) * 0.05))
            wisp(c, x, y, (60 + i * 20) * s, C(0xF8B890, 0.22), s: s)
        }
        for (i, (fx, wd, fh)) in [(0.02, 50, 0.08), (0.4, 30, 0.05), (0.84, 60, 0.1)].enumerated() {
            mesa(c, x: Int(Double(c.w) * fx), width: wd * s, h: Int(Double(g) * fh), base: g - 4, C(0xC88C66), seed: i + 5)
        }
    }

    /// Luke's X-34 landspeeder, parked by the dome.
    static func landspeeder(_ c: PixelCanvas, _ x: Int, _ g: Int) {
        let p = Pen(c, x, g - 4, g)
        p.rect(-3, -5, 3, 3, C(0xD8C08A)); p.rect(0, -6, 18, 4, C(0xD8C08A)); p.rect(0, -6, 18, 1, C(0xEAD6A6))
        p.rect(1, -3, 15, 1, C(0xB09868))
        p.rect(5, -8, 6, 2, C(0x6A4A3A)); p.rect(4, -9, 2, 2, C(0xCCE0F0, 0.8))
        p.rect(15, -10, 6, 3, C(0x8A8F9C)); p.rect(16, -7, 6, 3, C(0x9AA0A8))
        p.rect(1, 0, 18, 1, C(0x000000, 0.18))
    }

    // Obi-Wan's hut: a lamp hanging from the dome, niches with pots, cracks in the plaster.
    static func obiWanHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        func dome(_ x: Int) -> Int { let u = Double(x) / Double(c.w - 1) * 2 - 1; return Int(3 + (1 - (1 - u * u).squareRoot()) * Double(g - 14)) }
        let lx = c.w / 2 - 54, ly = g / 4
        c.rect(lx, dome(lx), 1, ly - dome(lx), C(0x4E3624))
        c.circle(lx, ly + 3 * s, 10 * s, C(0xFFD890, 0.08))
        c.rect(lx - 3 * s, ly, 7 * s, 2 * s, C(0x6A4A30)); c.rect(lx - 2 * s, ly + 2 * s, 5 * s, 2 * s, C(0xFFE0A0))
        for (fx, fy, seed) in [(0.2, 0.46, 1), (0.8, 0.36, 2)] {
            let x = Int(Double(c.w) * fx), y = Int(Double(g) * fy), w = 30 * s, h = 14 * s
            c.ellipse(x + w / 2, y, w / 2 + s, 4 * s, C(0xE0C8A0)); c.ellipse(x + w / 2, y + s, w / 2, 4 * s, C(0x8A6C4A))
            c.rect(x - s, y + s, w + 2 * s, h, C(0xE0C8A0)); c.rect(x, y + s, w, h, C(0x8A6C4A))
            c.rect(x, y + h - s, w, 2 * s, C(0x6A4A30))
            var px = x + 2 * s, k = 0
            while px < x + w - 4 * s {
                let ph = (4 + Int(noise(seed * 20 + k) * 6)) * s, pw = (3 + k % 2) * s
                c.rect(px, y + h - s - ph, pw, ph, [C(0xB06A44), C(0x7A8A6A), C(0xD8C8A8), C(0x9A5A3A)][(k + seed) % 4])
                c.rect(px + s / 2, y + h - s - ph - s, max(1, pw - s), s, C(0x5A4030))
                px += pw + s; k += 1
            }
        }
        for i in 0..<4 {
            var x = Int(noise(i * 5 + 50) * Double(c.w)), y = Int(Double(g) * (0.3 + noise(i * 5 + 51) * 0.3))
            for k in 0..<12 { c.px(x, y, C(0x8A6C4A, 0.6)); x += k % 3 == 0 ? 1 : 0; y += 1 }
        }
    }

    // The sandcrawler's hold: a catwalk with more junk on it, chains with hooks, and an intake fan.
    static func crawlerHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = g * 3 / 10
        for x in stride(from: 0, to: c.w, by: 46) { for k in 0..<(10 * s) { c.rect(x + 2 + k, y + 3 * s + k, 2, 1, C(0x2E1E12)) } }
        c.rect(0, y, c.w, 3 * s, C(0x3A2818)); c.rect(0, y, c.w, 1, C(0x8A6A42))
        c.rect(0, y - 7 * s, c.w, 1, C(0x6A4A2E)); for x in stride(from: 3, to: c.w, by: 9 * s) { c.rect(x, y - 7 * s, 1, 7 * s, C(0x4A3220)) }
        for i in 0..<(c.w / 24) where noise(i * 3 + 870) > 0.35 {
            drawJunkPart(c, i * 24 + Int(noise(i * 3 + 871) * 16), y, kind: Int(noise(i * 3 + 872) * 9), seed: i)
        }
        for fx in [0.37, 0.7] {
            let x = Int(Double(c.w) * fx), end = g / 5 + Int(fx * 20)
            for yy in stride(from: 5, to: end, by: 2) { c.px(x, yy, C(0x6A6A6A)); c.px(x, yy + 1, C(0x3A3A3A)) }
            c.rect(x - 2, end, 3, 1, C(0x8A8A8A)); c.px(x - 2, end - 1, C(0x8A8A8A))
        }
        let fx = c.w * 6 / 7, fy = g / 7, r = 12 * s
        c.circle(fx, fy, r + 2, C(0x2E1E12)); c.circle(fx, fy, r, C(0x120C07))
        for k in 0..<6 {
            let a = Double(k) * .pi / 3 + 0.3
            c.glowLine(Double(fx), Double(fy), Double(fx) + cos(a) * Double(r - 1), Double(fy) + sin(a) * Double(r - 1),
                       core: C(0x5A3C24), glow: C(0, 0), coreR: 0.9, glowR: 1.0)
        }
        c.circle(fx, fy, 2 * s, C(0x6E4A2E))
    }

    // Dagobah: the canopy closing in overhead, moss and vines trailing from it.
    static func dagobahCanopy(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<(c.w / 30 + 2) {
            let x = i * 30 + Int(noise(i * 3 + 700) * 20) - 10, y = Int(noise(i * 3 + 701) * Double(g / 18))
            c.ellipse(x, y, (18 + Int(noise(i * 3 + 702) * 14)) * s, (5 + i % 3 * 2) * s, C(0x16261A, 0.9))
        }
        for i in 0..<(c.w / 10) {
            let x = Int(noise(i * 5 + 720) * Double(c.w)), len = Int(Double(g) * (0.08 + noise(i * 5 + 721) * 0.2))
            for y in 0..<len {
                c.px(x + Int(sin(Double(y) * 0.12 + Double(i)) * 1.5), y, (i % 3 == 0 ? C(0x5A7A44) : C(0x3E5A34)).alpha(1 - Double(y) / Double(len) * 0.6))
            }
        }
    }

    // The Falcon's hold: a second row of fittings, and the ladder up to the gun turret.
    static func falconHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = g * 2 / 5
        for (i, x) in stride(from: 31, to: c.w - 100, by: 68).enumerated() {
            if i % 2 == 0 {
                c.rect(x, y, 14, 9, C(0x4A4840)); for k in 0..<4 { c.rect(x + 1, y + 1 + k * 2, 12, 1, C(0x2A2925)) }
            } else {
                c.rect(x, y, 12, 7, C(0x2E2D29)); c.rect(x + 1, y + 1, 10, 5, C(0x3E3D38))
                for k in 0..<3 { c.px(x + 2 + k * 3, y + 3, [C(0x6CFF7A), C(0xFFD24A), C(0x5AB4FF)][(i + k) % 3]) }
            }
        }
        let lx = 14 + 34 * max(0, (c.w * 9 / 20 - 14) / 34) + 18, top = g / 9
        c.ellipse(lx + 3, top, 10 * s, 3 * s, C(0x4A4840)); c.ellipse(lx + 3, top, 8 * s, 2 * s, C(0x16161A))
        for x in [lx, lx + 6] { c.rect(x, top, 1, g - top, C(0x9A968A)) }
        for yy in stride(from: top + 4, to: g - 1, by: 5) { c.rect(lx, yy, 7, 1, C(0x7A766A)) }
    }

    // Tantive IV: a ceiling with its light strip, a conduit, and doorways off the corridor.
    static func tantiveHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), ceil = g / 10
        c.rect(0, 6, c.w, ceil - 6, C(0xE4E8EE)); c.rect(0, ceil, c.w, 2, C(0xC8CED6))
        for x in stride(from: 10, to: c.w, by: 32) { c.rect(x, ceil - 4, 16, 2, C(0xFFFFFF)); c.rect(x - 1, ceil - 2, 18, 1, C(0xB8C0CA)) }
        let y = g / 4
        c.rect(0, y, c.w, 3 * s, C(0xD2D8E0)); c.rect(0, y, c.w, 1, C(0xFFFFFF)); c.rect(0, y + 3 * s, c.w, 1, C(0xA8B0BA))
        for fx in [0.18, 0.5] {
            let dx = Int(Double(c.w) * fx), dw = 28 * s, top = g - g * 2 / 5, cham = 6 * s
            for yy in top..<g {
                let inset = max(0, cham - (yy - top))
                c.rect(dx - dw / 2 - 3 * s + inset, yy, dw + 6 * s - inset * 2, 1, C(0xA8B0BA))
                if yy >= top + 3 * s {
                    let i2 = max(0, cham - (yy - top - 3 * s))
                    c.rect(dx - dw / 2 + i2, yy, dw - i2 * 2, 1, lerp(C(0xC4CBD4), C(0xDCE1E7), Double(yy - top) / Double(g - top)))
                }
            }
            c.rect(dx - dw / 2, g - 3 * s, dw, 3 * s, C(0xB8C0CA))
            c.rect(dx + dw / 2 + 6 * s, g - g / 4, 4 * s, 7 * s, C(0xC8CED6))
            c.px(dx + dw / 2 + 7 * s, g - g / 4 + 2 * s, C(0xE0303A)); c.px(dx + dw / 2 + 8 * s, g - g / 4 + 4 * s, C(0x3BD15A))
        }
    }

    // The Jundland Wastes: wisps of cloud and the far canyon wall.
    static func tuskenFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<5 {
            let x = Int(noise(i * 3 + 820) * Double(c.w)), y = Int(Double(g) * (0.08 + noise(i * 3 + 821) * 0.25))
            wisp(c, x, y, (60 + Int(noise(i * 3 + 822) * 80)) * s, C(0xFFFFFF, 0.3), s: s)
        }
        for x in 0..<c.w {
            let top = g - Int(Double(g) * (0.38 + 0.06 * sin(Double(x) * 0.013 + 1) + 0.03 * sin(Double(x) * 0.05))) + Int(noise(x / 3 + 800) * 3)
            c.rect(x, top, 1, g - top, C(0xD6B890)); c.px(x, top, C(0xE4C8A0))
            for k in 1...3 where (x / 7 + k) % 5 != 0 { c.px(x, top + (g - top) * k / 4, C(0xC8A47C, 0.6)) }
        }
    }

    // Jakku: thin cirrus, and another wreck far off past the buried nose.
    static func jakkuFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<6 {
            let x = Int(noise(i * 3 + 850) * Double(c.w)), y = Int(Double(g) * (0.06 + noise(i * 3 + 851) * 0.3))
            wisp(c, x, y, (60 + Int(noise(i * 3 + 852) * 80)) * s, C(0xFFFFFF, 0.3), s: s)
        }
        let x1 = c.w / 7, h = g / 5
        for x in 0..<x1 {
            let top = g - 8 - (x1 - x) * h / x1
            c.rect(x, top, 1, g - top, x % 9 == 0 ? C(0xCCD0D2) : C(0xD6D8D6)); c.px(x, top, C(0xE6E8E4))
        }
        for k in 0..<2 { c.circle(3 * s, g - 8 - h + (8 + k * 11) * s, 3 * s, C(0xC2C6CA)) }
    }

    // The Jedi Council chamber: the ceiling and a transom across the tall windows.
    static func councilHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in stride(from: 4, to: c.w - 14, by: 24) { c.rect(x, g / 4, 18, 2 * s, C(0x4A3624)) }
        c.rect(0, 0, c.w, g / 14, C(0x5A4228)); c.rect(0, g / 14, c.w, 1, C(0x8A6A48))
        for x in stride(from: 16, to: c.w, by: 48) { c.rect(x, g / 14 - 3, 6, 2, C(0xFFE2A0)) }
    }

    /// Coruscant's air traffic streaming past the Jedi Council's windows.
    static func councilTraffic(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g)
        for (i, (fy, speed)) in [(0.3, 9.0), (0.36, -6.0), (0.45, 13.0), (0.55, -8.0)].enumerated() {
            let y = Int(Double(g) * fy), gap = 23 + i * 7
            let off = ((t * speed).truncatingRemainder(dividingBy: Double(gap)) + Double(gap)).truncatingRemainder(dividingBy: Double(gap))
            for k in -1...(c.w / gap + 1) {
                let x = k * gap + Int(off) + Int(noise(k * 7 + i * 101) * 8)
                guard x >= 4, (x - 4) % 24 < 17 else { continue }
                c.rect(x, y + Int(noise(k * 5 + i) * 3), 2 * s, s, k % 3 == 0 ? C(0xFFE8B0, 0.8) : C(0x2A1E2A, 0.7))
            }
        }
    }

    // Endor: more trees in the mist, the canopy, and a lower tier of the Ewok village with a rope ladder.
    static func endorFar(_ c: PixelCanvas, _ g: Int) {
        for i in 0..<10 { c.rect(Int(noise(i * 7 + 950) * Double(c.w)), 0, 2 + i % 2, g, C(0x5A7A62, 0.45)) }
    }

    static func endorCanopy(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<(c.w / 26 + 2) {
            let x = i * 26 + Int(noise(i * 3 + 960) * 16) - 8
            c.ellipse(x, Int(noise(i * 3 + 961) * 4), (16 + Int(noise(i * 3 + 962) * 12)) * s, (4 + i % 3 * 2) * s, C(0x183424, 0.92))
        }
    }

    static func endorLowerVillage(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let spots = [(104, 14), (222, 10)]
        for (i, (x, tw)) in spots.enumerated() where x + tw + 14 < c.w {
            let y = g * 3 / 10 + i * 6
            c.rect(x - 14, y, tw + 28, 2, C(0x8A6238)); c.rect(x - 14, y + 2, tw + 28, 1, C(0x5A3A20))
            c.rect(x - 14, y - 4, tw + 28, 1, C(0x7A5A32)); for k in stride(from: x - 14, to: x + tw + 14, by: 4) { c.rect(k, y - 3, 1, 3, C(0x7A5A32)) }
            for k in 0..<8 { let half = 1 + k * 7 / 10; c.rect(x + tw + 8 - half, y - 12 + k, half * 2 + 1, 1, k % 3 == 0 ? C(0x8A6A3A) : C(0xA8844A)) }
            c.rect(x + tw + 3, y - 4, 11, 4, C(0x9A7448)); c.rect(x + tw + 7, y - 3, 3, 3, C(0x2A1A0E))
            let lad = x - 10, end = y + g / 5
            c.rect(lad, y + 3, 1, end - y - 3, C(0x7A5A32)); c.rect(lad + 4, y + 3, 1, end - y - 3, C(0x7A5A32))
            for yy in stride(from: y + 5, to: end, by: 3) { c.rect(lad, yy, 5, 1, C(0x5A4228)) }
            c.px(x - 6, y - 2, C(0xFFB050)); c.circle(x - 6, y - 2, 3 * s, C(0xFFB050, 0.15))
        }
        if spots.count == 2, spots[1].0 + 24 < c.w {
            let x0 = spots[0].0 + spots[0].1 + 14, x1 = spots[1].0 - 14, y0 = g * 3 / 10 + 1, y1 = g * 3 / 10 + 7
            for x in x0...x1 {
                let u = Double(x - x0) / Double(x1 - x0), y = y0 + Int(Double(y1 - y0) * u + sin(u * .pi) * 8)
                c.px(x, y, C(0x7A5A32)); if x % 3 == 0 { c.px(x, y - 3, C(0x5A4228)); c.px(x, y - 2, C(0x5A4228)) }
            }
        }
    }

    // Hoth: low cloud, the jagged ice ridge behind the hills.
    static func hothFar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<7 {
            let x = Int(noise(i * 5 + 600) * Double(c.w)), y = Int(Double(g) * (0.04 + noise(i * 5 + 601) * 0.3))
            wisp(c, x, y, (60 + Int(noise(i * 5 + 602) * 100)) * s, C(0xC2CAD6, 0.55), s: s)
        }
        var peaks: [(x: Int, h: Int)] = []
        var px = -20, i = 0
        while px < c.w + 40 {
            peaks.append((px, Int(Double(g) * (0.2 + noise(i * 3 + 610) * 0.2))))
            px += (50 + Int(noise(i * 3 + 611) * 50)) * s; i += 1
        }
        for x in 0..<c.w {
            var top = g, lit = true
            for p in peaks { let y = g - p.h + abs(x - p.x) * 3 / 4; if y < top { top = y; lit = x < p.x } }
            top += Int(noise(x * 5 + 620) * 2)
            guard top < g else { continue }
            c.rect(x, top, 1, g - top, lit ? C(0xCAD3DE) : C(0xB4BFCC)); c.px(x, top, C(0xE4EAF2))
        }
    }

    /// Echo Base's hangar in an ice cliff, the ion cannon, and power pylons, out on the snowfield.
    static func hothMid(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let ex = c.w / 12
        c.ellipse(ex, g - 4, c.w / 9, g / 5, C(0xD2DAE4)); c.ellipse(ex - 6, g - 6, c.w / 10, g / 5 - 4, C(0xDDE4EC))
        c.rect(ex - 12 * s, g - 8 - 10 * s, 24 * s, 10 * s, C(0x5A6676)); c.rect(ex - 10 * s, g - 8 - 4 * s, 20 * s, 4 * s, C(0xF2E2B0, 0.35))
        c.rect(ex - 13 * s, g - 9 - 10 * s, 26 * s, s, C(0x8A939E))
        let p = Pen(c, c.w * 14 / 25, g - 9, g)
        p.rect(-12, -3, 24, 3, C(0x9AA4B0)); p.rect(-9, -6, 18, 3, C(0x8E98A6))
        p.circle(0, -15, 10, C(0xA6B0BC)); p.circle(-2, -17, 7, C(0xB4BEC8)); p.circle(-4, -19, 2, C(0xCED6E0))
        p.rect(-10, -14, 20, 1, C(0x7E8898))
        c.glowLine(Double(p.x - 5 * s), Double(p.y - 22 * s), Double(p.x - 18 * s), Double(p.y - 34 * s),
                   core: C(0x8E98A6), glow: C(0, 0), coreR: 1.0 * Double(s), glowR: 1.1 * Double(s))
        for fx in [0.68, 0.92] {
            let x = Int(Double(c.w) * fx), top = g - 10 - 26 * s
            c.rect(x, top, 2 * s, 26 * s, C(0xA0AAB6)); c.ellipse(x + s, top, 6 * s, s, C(0xB4BEC8)); c.px(x, top - 2 * s, C(0xE0303A))
        }
    }

    /// Snowspeeders sweeping across the middle of the sky now and then.
    static func hothSpeeders(_ c: PixelCanvas, _ g: Int, t: Double) {
        let s = unit(g), q = (t * 0.05 + 0.5).truncatingRemainder(dividingBy: 1)
        guard q < 0.3 else { return }
        let u = q / 0.3
        for j in 0..<2 {
            let x = c.w + 30 - Int(u * Double(c.w + 90)) + j * 16 * s, y = g * 3 / 10 + j * 7 * s + Int(sin(u * 5) * 3)
            let p = Pen(c, x, y, g)
            p.rect(0, 0, 9, 2, C(0xE8E4DC)); p.rect(0, 0, 2, 1, C(0xE87A2A)); p.rect(6, -1, 3, 1, C(0xC8C4BC))
            p.rect(9, 1, 5, 1, C(0xC8D8F0, 0.4))
        }
    }

    // The rancor pit: longer stalactites, and chains hanging from the dark.
    static func rancorHigh(_ c: PixelCanvas, _ g: Int) {
        for i in 0..<14 {
            let x = Int(noise(i * 3 + 900) * Double(c.w)), len = Int(Double(g) * (0.06 + noise(i * 3 + 901) * 0.12)), w0 = 3 + i % 4
            for k in 0..<len {
                let w = max(1, w0 * (len - k) / len)
                c.rect(x - w / 2, k, w, 1, C(0x241A12)); c.px(x - w / 2, k, C(0x4A3A2A))
            }
        }
        for fx in [0.56, 0.9] {
            let x = Int(Double(c.w) * fx), end = g / 4 + Int(fx * 30)
            for y in stride(from: 0, to: end, by: 2) { c.px(x, y, C(0x6A6458)); c.px(x, y + 1, C(0x3A342C)) }
            c.circle(x, end + 2, 2, C(0x6A6458)); c.px(x, end + 2, C(0x1A140F))
        }
    }
}
