import AppKit

// Renders the README's roster and locations images with the app's own sprite code.
//   swiftc -swift-version 5 Sources/App/Pixel.swift Sources/App/Characters.swift Sources/App/Recruits.swift Sources/App/Leaders.swift \
//          Sources/App/Cantina.swift Sources/App/Locations.swift Sources/App/Cast.swift Sources/App/Habits.swift Sources/Shared/*.swift \
//          Tools/RenderDocs/main.swift -o /tmp/renderdocs && /tmp/renderdocs docs

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
let bg = CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)

func canvas(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(bg); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

func label(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 13, color: NSColor = .white, width: CGFloat = 0) {
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold), .foregroundColor: color])
    let w = a.size().width
    a.draw(at: NSPoint(x: width > 0 ? x + (width - w) / 2 : x, y: y))
}

/// A character cropped to its outline, drawn at `scale` with its feet on `ground`, centred in a cell.
func put(_ c: PixelCanvas, in ctx: CGContext, cellX: CGFloat, cellW: CGFloat, ground: CGFloat, scale: CGFloat) {
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { return }
    let feet = CGFloat(Sprite.height - 44) // canvas rows under the feet
    let bottomGap = CGFloat(Sprite.height) - b.maxY
    ctx.draw(img, in: CGRect(x: cellX + (cellW - b.width * scale) / 2, y: ground + (bottomGap - feet) * scale,
                             width: b.width * scale, height: b.height * scale))
}

// MARK: Roster

let scale: CGFloat = 3, cellW: CGFloat = 190, rowH: CGFloat = 190, cols = 5
let villains = Leader.allCases, heroes = Companion.allCases
let vRows = (villains.count + cols - 1) / cols, hRows = (heroes.count + cols - 1) / cols
let titleH: CGFloat = 54
let rosterH = Int(titleH * 2 + CGFloat(vRows + hRows) * rowH + 20)
let roster = canvas(Int(cellW) * cols, rosterH) { ctx in
    var top = CGFloat(rosterH)
    func section(_ title: String, _ count: Int, rows: Int, _ draw: (Int, PixelCanvas) -> String) {
        top -= titleH
        label(title, 20, top + 16, size: 20, color: NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1))
        for i in 0..<count {
            let c = PixelCanvas(Sprite.width, Sprite.height)
            let name = draw(i, c)
            let x = CGFloat(i % cols) * cellW, rowTop = top - CGFloat(i / cols + 1) * rowH
            put(c, in: ctx, cellX: x, cellW: cellW, ground: rowTop + 34, scale: scale)
            label(name, x, rowTop + 10, width: cellW)
        }
        top -= CGFloat(rows) * rowH
    }
    section("THE DARK SIDE — one per Claude session", villains.count, rows: vRows) { i, c in
        drawLeader(c, villains[i], t: 0.62, mode: .working, walking: false); return villains[i].name
    }
    section("THE REBELS — your subagents", heroes.count, rows: hRows) { i, c in
        drawCompanion(c, heroes[i], t: 0.4, walking: false); return heroes[i].name
    }
}
save(roster, "roster.png")

// MARK: Locations

Cantina.maxReboTonight = false      // the sheet shows the Modal Nodes (the Max Rebo Band is in Jabba's palace)

let lw = 250, lh = 70, lscale: CGFloat = 2, lcols = 3
let locs = Location.allCases
let lRows = (locs.count + lcols - 1) / lcols
let cellLW = CGFloat(lw) * lscale, cellLH = CGFloat(lh) * lscale + 26
let locations = canvas(Int(cellLW) * lcols + (lcols - 1) * 8, Int(cellLH) * lRows) { ctx in
    for (i, l) in locs.enumerated() {
        let c = PixelCanvas(lw, lh); l.drawStatic(c, floorRows: 10)
        let a = PixelCanvas(lw, lh); l.drawAnimated(a, floorRows: 10, t: 1.3)
        let x = CGFloat(i % lcols) * (cellLW + 8), y = CGFloat(lRows - 1 - i / lcols) * cellLH
        ctx.draw(c.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
        ctx.draw(a.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
        label(l.name, x, y + 4, size: 12, color: NSColor(white: 0.85, alpha: 1), width: cellLW)
    }
}
save(locations, "locations.png")
print("wrote \(out)/roster.png and \(out)/locations.png")

// MARK: Social preview (1280×640, for GitHub → Settings → Social preview)

let social = canvas(1280, 640) { ctx in
    let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                    CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(space, start: CGPoint(x: 0, y: 640), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<160 {
        let big = noise(i * 3 + 2) > 0.85
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: big ? 0.9 : 0.45))
        let s: CGFloat = big ? 4 : 2
        ctx.fill(CGRect(x: CGFloat(noise(i * 3)) * 1280, y: 200 + CGFloat(noise(i * 3 + 1)) * 440, width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 1280, height: 150))
    ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)); ctx.fill(CGRect(x: 0, y: 147, width: 1280, height: 4))
    // title
    let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
    let titleFont = NSFont(name: "Futura-CondensedExtraBold", size: 92) ?? .systemFont(ofSize: 84, weight: .black)
    let title = NSAttributedString(string: "CLAWD WARS", attributes: [.font: titleFont, .foregroundColor: yellow, .kern: 8])
    title.draw(at: NSPoint(x: (1280 - title.size().width) / 2, y: 470))
    let sub = NSAttributedString(string: "Your Claude Code sessions as a pixel-art Star Wars battle on your desktop",
                                 attributes: [.font: NSFont.systemFont(ofSize: 26, weight: .semibold), .foregroundColor: NSColor(white: 0.9, alpha: 1)])
    sub.draw(at: NSPoint(x: (1280 - sub.size().width) / 2, y: 418))
    // the crew, standing on the horizon
    let crew: [(PixelCanvas) -> Void] = [
        { drawLeader($0, .boba, t: 0.3, mode: .working, walking: false, role: .shoot(offset: 0)) },
        { drawCompanion($0, .han, t: 0.2, walking: false) },
        { drawLeader($0, .vader, t: 0.62, mode: .working, walking: false, role: .duel) },
        { drawCompanion($0, .luke, t: 0.62, walking: false, role: .duel) },
        { drawCompanion($0, .yoda, t: 0.9, walking: false) },
        { drawLeader($0, .atat, t: 0.1, mode: .idle, walking: false) },
    ]
    let scales: [CGFloat] = [4, 3, 4, 3, 3, 4]
    var x: CGFloat = 40
    for (i, draw) in crew.enumerated() {
        let c = PixelCanvas(Sprite.width, Sprite.height); draw(c)
        c.addOutline(C(0xFFFFFF, 0.92))
        guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { continue }
        let s = scales[i], w = b.width * s
        let bottomGap = CGFloat(Sprite.height) - b.maxY
        ctx.draw(img, in: CGRect(x: x, y: 150 + (bottomGap - 8) * s, width: w, height: b.height * s))
        x += w + 26
    }
}
save(social, "social-preview.png")
print("wrote \(out)/social-preview.png")
