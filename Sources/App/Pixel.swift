import CoreGraphics
import Foundation

struct Px {
    var r: UInt8, g: UInt8, b: UInt8, a: UInt8
    func alpha(_ m: Double) -> Px { Px(r: r, g: g, b: b, a: UInt8(max(0, min(255, Double(a) * m)))) }
}

func C(_ hex: UInt32, _ a: Double = 1) -> Px {
    Px(r: UInt8((hex >> 16) & 0xFF), g: UInt8((hex >> 8) & 0xFF), b: UInt8(hex & 0xFF),
       a: UInt8(max(0, min(255, a * 255))))
}

/// Tiny RGBA framebuffer. Sprites are drawn here at 1 unit = 1 pixel, then scaled up
/// with nearest-neighbour so everything stays crisp pixel art.
final class PixelCanvas {
    let w: Int, h: Int
    private(set) var buf: [UInt8]   // premultiplied RGBA
    var ox = 0, oy = 0               // translation applied to every draw call
    var baseY = 0                    // extra vertical shift under `oy`: moves a whole sprite (a hop, sitting down)
                                     // whose drawing code sets `oy` itself

    init(_ w: Int, _ h: Int) {
        self.w = w; self.h = h
        buf = [UInt8](repeating: 0, count: w * h * 4)
    }

    func px(_ x: Int, _ y: Int, _ c: Px) {
        let x = x + ox, y = y + oy + baseY
        guard x >= 0, y >= 0, x < w, y < h, c.a > 0 else { return }
        let i = (y * w + x) * 4
        let sa = Double(c.a) / 255
        let inv = 1 - sa
        buf[i]     = UInt8(min(255, Double(c.r) * sa + Double(buf[i]) * inv))
        buf[i + 1] = UInt8(min(255, Double(c.g) * sa + Double(buf[i + 1]) * inv))
        buf[i + 2] = UInt8(min(255, Double(c.b) * sa + Double(buf[i + 2]) * inv))
        buf[i + 3] = UInt8(min(255, Double(c.a) + Double(buf[i + 3]) * inv))
    }

    func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Px) {
        guard w > 0, h > 0 else { return }
        for yy in y..<(y + h) { for xx in x..<(x + w) { px(xx, yy, c) } }
    }

    /// Draw string art. Each character maps to a colour in `palette`; anything else is transparent.
    func pattern(_ x: Int, _ y: Int, _ rows: [String], _ palette: [Character: Px]) {
        for (r, row) in rows.enumerated() {
            for (c, ch) in row.enumerated() {
                guard let col = palette[ch] else { continue }
                px(x + c, y + r, col)
            }
        }
    }

    /// Anti-aliased-but-pixelated glowing segment (lightsaber blades, blaster bolts).
    func glowLine(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double,
                  core: Px, glow: Px, coreR: Double = 0.75, glowR: Double = 2.4, strength: Double = 1) {
        let minX = Int(floor(min(x0, x1) - glowR)), maxX = Int(ceil(max(x0, x1) + glowR))
        let minY = Int(floor(min(y0, y1) - glowR)), maxY = Int(ceil(max(y0, y1) + glowR))
        let dx = x1 - x0, dy = y1 - y0
        let len2 = max(dx * dx + dy * dy, 0.0001)
        for y in minY...maxY {
            for x in minX...maxX {
                let cx = Double(x) + 0.5, cy = Double(y) + 0.5
                let t = max(0, min(1, ((cx - x0) * dx + (cy - y0) * dy) / len2))
                let ex = x0 + t * dx - cx, ey = y0 + t * dy - cy
                let d = sqrt(ex * ex + ey * ey)
                if d <= coreR {
                    px(x, y, core.alpha(strength))
                } else if d <= glowR {
                    let f = 1 - (d - coreR) / (glowR - coreR)
                    // Quantise the falloff so the glow stays chunky rather than smooth.
                    let q = (f * 3).rounded(.up) / 3
                    px(x, y, glow.alpha(q * 0.85 * strength))
                }
            }
        }
    }

    /// The smallest rectangle containing every visible pixel (canvas coordinates, y down).
    func opaqueBounds() -> CGRect? {
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            for x in 0..<w where buf[(y * w + x) * 4 + 3] > 24 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        return maxX < 0 ? nil : CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    /// A copy turned by `degrees` about `pivot` (negative turns anticlockwise on screen: a right-facing sprite falls on
    /// its back), with `pivot` landing on `at` in a new `w` × `h` canvas. Nearest-neighbour, so it stays pixel art.
    func rotated(_ degrees: Double, about pivot: (x: Double, y: Double), into w: Int, _ h: Int,
                 at: (x: Double, y: Double)) -> PixelCanvas {
        let out = PixelCanvas(w, h)
        let r = degrees * .pi / 180, cs = cos(r), sn = sin(r)
        for y in 0..<h {
            for x in 0..<w {
                let dx = Double(x) + 0.5 - at.x, dy = Double(y) + 0.5 - at.y
                let sx = Int(floor(pivot.x + dx * cs + dy * sn)), sy = Int(floor(pivot.y - dx * sn + dy * cs))
                guard sx >= 0, sy >= 0, sx < self.w, sy < self.h else { continue }
                let si = (sy * self.w + sx) * 4, di = (y * w + x) * 4
                for k in 0..<4 { out.buf[di + k] = buf[si + k] }
            }
        }
        return out
    }

    /// Mirror everything drawn so far, left to right.
    func flipHorizontally() {
        var out = buf
        for y in 0..<h {
            for x in 0..<w {
                let src = (y * w + x) * 4, dst = (y * w + (w - 1 - x)) * 4
                for k in 0..<4 { out[dst + k] = buf[src + k] }
            }
        }
        buf = out
    }

    /// Mirror everything drawn so far about the vertical line `x` (canvas units), unless something drawn would end up
    /// off the canvas. Returns whether it mirrored.
    @discardableResult
    func mirror(aboutX x: Double) -> Bool {
        let axis = Int((2 * x).rounded()) - 1          // column k lands on axis - k
        for y in 0..<h {
            for k in 0..<w where buf[(y * w + k) * 4 + 3] > 0 && (axis - k < 0 || axis - k >= w) { return false }
        }
        var out = [UInt8](repeating: 0, count: buf.count)
        for y in 0..<h {
            for k in 0..<w where buf[(y * w + k) * 4 + 3] > 0 {
                let src = (y * w + k) * 4, dst = (y * w + axis - k) * 4
                for n in 0..<4 { out[dst + n] = buf[src + n] }
            }
        }
        buf = out
        return true
    }

    /// Move everything drawn so far by whole pixels; what slides off the edge is lost.
    func shift(dx: Int, dy: Int) {
        guard dx != 0 || dy != 0 else { return }
        var out = [UInt8](repeating: 0, count: buf.count)
        for y in 0..<h {
            let ty = y + dy
            guard ty >= 0, ty < h else { continue }
            for x in 0..<w {
                let tx = x + dx
                guard tx >= 0, tx < w else { continue }
                let src = (y * w + x) * 4, dst = (ty * w + tx) * 4
                for n in 0..<4 { out[dst + n] = buf[src + n] }
            }
        }
        buf = out
    }

    /// 1px outline around every solid pixel, so dark sprites still read on a dark desktop.
    /// Only fully opaque pixels count as solid, so saber glows and bolts don't get outlined.
    func addOutline(_ c: Px) {
        guard w > 0, h > 0 else { return }
        let a = Double(c.a) / 255
        let cr = Double(c.r) * a, cg = Double(c.g) * a, cb = Double(c.b) * a, ca = Double(c.a), keep = 1 - a
        let (w, h) = (w, h)
        buf.withUnsafeMutableBufferPointer { b in
            // Which pixels are solid, taken before any outline is written (only the alpha matters, not a full copy).
            var solid = [Bool](repeating: false, count: w * h)
            for p in 0..<(w * h) { solid[p] = b[p * 4 + 3] >= 250 }
            for y in 0..<h {
                for x in 0..<w {
                    let p = y * w + x, i = p * 4
                    guard b[i + 3] <= 60 else { continue }
                    let edge = (x + 1 < w && solid[p + 1]) || (x > 0 && solid[p - 1])
                        || (y + 1 < h && solid[p + w]) || (y > 0 && solid[p - w])
                    guard edge else { continue }
                    b[i] = UInt8(min(255, cr + Double(b[i]) * keep))
                    b[i + 1] = UInt8(min(255, cg + Double(b[i + 1]) * keep))
                    b[i + 2] = UInt8(min(255, cb + Double(b[i + 2]) * keep))
                    b[i + 3] = UInt8(min(255, ca + Double(b[i + 3]) * keep))
                }
            }
        }
    }

    /// The most common solid colour, ignoring `excluding` (and anything within a small distance of them). Colours
    /// are bucketed coarsely so shading of one material counts together; the bucket's average is returned.
    func dominantColor(excluding: [Px]) -> (r: Double, g: Double, b: Double)? {
        var buckets: [Int: (n: Int, r: Int, g: Int, b: Int)] = [:]
        for i in stride(from: 0, to: buf.count, by: 4) where buf[i + 3] >= 250 {
            let r = Int(buf[i]), g = Int(buf[i + 1]), b = Int(buf[i + 2])
            if excluding.contains(where: { abs(Int($0.r) - r) + abs(Int($0.g) - g) + abs(Int($0.b) - b) < 40 }) { continue }
            let key = (r >> 5) << 6 | (g >> 5) << 3 | (b >> 5)
            let e = buckets[key] ?? (0, 0, 0, 0)
            buckets[key] = (e.n + 1, e.r + r, e.g + g, e.b + b)
        }
        guard let best = buckets.values.max(by: { $0.n < $1.n }) else { return nil }
        return (Double(best.r) / Double(best.n) / 255, Double(best.g) / Double(best.n) / 255, Double(best.b) / Double(best.n) / 255)
    }

    /// Average brightness (0…1) of one row, transparent pixels counting as black.
    func rowLuminance(_ y: Int) -> Double {
        guard y >= 0, y < h, w > 0 else { return 0 }
        var sum = 0.0
        for x in 0..<w {
            let i = (y * w + x) * 4
            sum += 0.2126 * Double(buf[i]) + 0.7152 * Double(buf[i + 1]) + 0.0722 * Double(buf[i + 2])
        }
        return sum / Double(w) / 255
    }

    /// Wipe to transparent (and drop any translation), so one canvas can be reused frame after frame.
    func clear() {
        buf.withUnsafeMutableBytes { _ = $0.initializeMemory(as: UInt8.self, repeating: 0) }
        ox = 0; oy = 0; baseY = 0
    }

    func makeImage() -> CGImage? {
        let data = Data(buf) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}
