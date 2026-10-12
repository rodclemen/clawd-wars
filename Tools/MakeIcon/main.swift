import AppKit

// Renders Resources/AppIcon.png (1024²): Vader Clawd and Luke crossing sabers on a starfield,
// drawn with the app's own sprite code. build.sh turns it into AppIcon.icns.
//   swiftc Sources/App/Pixel.swift Sources/App/Characters.swift Sources/App/Leaders.swift \
//          Sources/App/Locations.swift Sources/App/Cantina.swift Sources/App/Cast.swift Sources/App/Habits.swift \
//          Sources/Shared/*.swift Tools/MakeIcon/main.swift -o /tmp/makeicon && /tmp/makeicon Resources/AppIcon.png

let size: CGFloat = 1024
let p: CGFloat = 9                      // icon pixels per sprite pixel
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
ctx.interpolationQuality = .none

// macOS icon grid: 824² rounded square, centred.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(shape); ctx.clip()

// Deep-space gradient
let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray,
                       locations: [0, 1])!
ctx.drawLinearGradient(space, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Pixel stars (deterministic)
for i in 0..<70 {
    let x = 100 + noise(i * 3) * 824, y = 360 + noise(i * 3 + 1) * 564
    let big = noise(i * 3 + 2) > 0.85
    let s: CGFloat = big ? p : p / 2
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: big ? 0.95 : 0.55))
    ctx.fill(CGRect(x: (CGFloat(x) / s).rounded() * s, y: (CGFloat(y) / s).rounded() * s, width: s, height: s))
}

// Ground strip
ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: 318))
ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1))   // Claude-orange horizon
ctx.fill(CGRect(x: 0, y: 318, width: size, height: p))

// The duel, frozen on a clash
let t = 0.55
let dist = 170.0 / 3                     // duel distance in sprite pixels, as in the app
let centerL = 512 - CGFloat(dist) / 2 * p, centerR = 512 + CGFloat(dist) / 2 * p
let canvasBottom: CGFloat = 318 - 8 * p  // feet (row 44) on the horizon
func put(_ c: PixelCanvas, center: CGFloat, mirrored: Bool) {
    c.addOutline(C(0xFFFFFF, 0.92))
    let img = c.makeImage()!
    let w = CGFloat(c.w) * p, h = CGFloat(c.h) * p
    let x = center - (mirrored ? CGFloat(c.w) - 28 : 28) * p
    ctx.saveGState()
    if mirrored {
        ctx.translateBy(x: x + w, y: canvasBottom); ctx.scaleBy(x: -1, y: 1)
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    } else {
        ctx.draw(img, in: CGRect(x: x, y: canvasBottom, width: w, height: h))
    }
    ctx.restoreGState()
}
let vader = PixelCanvas(72, 52)
drawLeader(vader, .vader, t: t, mode: .working, walking: false, role: .duel)
let luke = PixelCanvas(72, 52)
drawCompanion(luke, .luke, t: t, walking: false, role: .duel)
put(vader, center: centerL, mirrored: false)
put(luke, center: centerR, mirrored: true)

let margin = 24.0
let fx = PixelCanvas(Int(dist + margin * 2), 52)
drawFightFX(fx, t: t,
            left: Fighter(weapon: .saber, x: margin, k: 1, top: 0, side: 1, muzzle: (52, 32)),
            right: Fighter(weapon: .saber, x: margin + dist, k: 1, top: 0, side: -1, muzzle: (52, 32)))
ctx.draw(fx.makeImage()!, in: CGRect(x: centerL - CGFloat(margin) * p, y: canvasBottom,
                                     width: CGFloat(fx.w) * p, height: CGFloat(fx.h) * p))
ctx.restoreGState()

// Subtle rim
ctx.addPath(shape)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12)); ctx.setLineWidth(4); ctx.strokePath()

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
