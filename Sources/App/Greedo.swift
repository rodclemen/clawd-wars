import CoreGraphics
import Foundation

/// Han shoots first. Han Solo and Greedo always face off when both are on stage, and now and then Greedo doesn't
/// duck in time: Han's bolt knocks him into a backward somersault and he lands on his back, legs in the air, for three
/// seconds (dizzy stars, a wisp of smoke) while Han apologises for the mess. Then he rolls back onto his feet, says his
/// piece and walks back to his spot. (A Clawd is wider than it is tall, so lying on its side would look like standing.)
/// The overlay runs the clock (`OverlayController.greedoShot`); this draws it. Times are seconds from Han's shot.
enum GreedoShot {
    static let hit = blasterPeriod * boltArrival   // the bolt lands
    static let landed = hit + 0.75                 // on his back, legs in the air
    static let getUp = landed + 3                  // lies there for three seconds
    static let standing = getUp + 0.55
    static let done = standing + 2.4               // says his piece and walks back
    static let hanLine = (from: landed + 0.3, to: getUp)

    static let hanSays = "Sorry about the mess."
    static let greedoSays = ["That hurt!", "Ow! Maclunkey…", "Han shot first!", "Not the vest!", "I'm OK!", "Every time…"]

    /// How long until Han tries it again: soon after they first face off, then every minute or so.
    static func delay(first: Bool) -> Double {
        if let debug = Double(ProcessInfo.processInfo.environment["CLAWD_GREEDO_EVERY"] ?? "") { return debug }
        return first ? .random(in: 8...25) : .random(in: 30...75)
    }

    private static let flip = -540.0   // one backward somersault, then half another: upside down
    private static let knockback = 4.0  // not far: whoever stands behind him has to stay clear

    /// Greedo at `e`: turned `angle` degrees (0 standing, -180 on his back), `lift` art pixels off the ground,
    /// knocked `back` art pixels away from Han, and walking (back to his spot, or his legs kicking in the air).
    static func pose(_ e: Double) -> (angle: Double, lift: Double, back: Double, walking: Bool) {
        switch e {
        case ..<hit:
            return (0, 0, 0, false)
        case ..<landed:
            let p = (e - hit) / (landed - hit)
            return (flip * (1 - pow(1 - p, 1.6)), 22 * 4 * p * (1 - p), knockback * p, false)
        case ..<getUp:
            let s = e - landed   // lands with a little bounce, legs kicking for a moment
            return (-180, s < 0.35 ? 3 * abs(sin(s / 0.35 * .pi)) * (1 - s / 0.35) : 0, knockback, s < 1.4)
        case ..<standing:
            let p = (e - getUp) / (standing - getUp)   // rolls the rest of the way over, onto his feet
            return (-180 - 180 * (1 - pow(1 - p, 2)), 6 * sin(p * .pi), knockback, false)
        default:
            let p = min(1, (e - standing) / 1.2)
            return (0, 0, knockback * (1 - p), p < 1)
        }
    }

    /// Size of Greedo's canvas while he's knocked about: room for him turned any way, his feet row 9 from the bottom
    /// like a standing sprite's, so it sits on the ground the same way.
    static let canvasSize = (w: 112, h: 72)
    static let pivotX = 56.0

    /// Greedo (drawn standing by `draw`) posed for `e`, with dizzy stars and smoke while he's down. Also returns his
    /// top row, for his name tag.
    static func sprite(e: Double, t: Double, draw: (PixelCanvas) -> Void) -> (canvas: PixelCanvas, top: Int) {
        let src = PixelCanvas(Sprite.width, Sprite.height)
        draw(src)
        let angle = pose(e).angle
        let pivot = (x: Sprite.bodyCenterX, y: 31.0)
        let r = angle * .pi / 180, cs = cos(r), sn = sin(r)
        func turn(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
            let dx = x - pivot.x, dy = y - pivot.y
            return (dx * cs - dy * sn, dx * sn + dy * cs)
        }
        // Rest the lowest corner of what's drawn on the ground row, whichever way he's turned.
        let b = src.opaqueBounds() ?? CGRect(x: 18, y: 20, width: 20, height: 24)
        let corners: [(Double, Double)] = [(b.minX, b.minY), (b.maxX, b.minY), (b.minX, b.maxY), (b.maxX, b.maxY)].map { (Double($0.0), Double($0.1)) }
        let low = corners.map { turn($0.0, $0.1).y }.max() ?? 0
        let at = (x: pivotX, y: Double(canvasSize.h - 9) - low)
        let out = src.rotated(angle, about: pivot, into: canvasSize.w, canvasSize.h, at: at)
        func place(_ x: Double, _ y: Double) -> (x: Double, y: Double) { let p = turn(x, y); return (p.x + at.x, p.y + at.y) }

        if e >= landed - 0.1 && e < getUp + 0.2 {
            // Dizzy stars circling over him.
            let top = out.opaqueBounds() ?? CGRect(x: at.x, y: at.y, width: 1, height: 1)
            for k in 0..<3 {
                let a = t * 5 + Double(k) * 2 * .pi / 3
                let sx = Int((Double(top.midX) + cos(a) * 8).rounded()), sy = Int((Double(top.minY) - 4 + sin(a) * 2).rounded())
                let star = C(k == 1 ? 0xFFFFFF : 0xFFE14A, sin(a) > 0 ? 1 : 0.65)   // the far side of the circle dimmer
                out.px(sx, sy, star); out.px(sx - 1, sy, star); out.px(sx + 1, sy, star); out.px(sx, sy - 1, star); out.px(sx, sy + 1, star)
            }
        }
        if e >= hit && e < getUp {
            // A wisp of smoke from the scorch on his vest, rising and fading.
            let chest = place(Sprite.bodyCenterX + 4, 31)
            for k in 0..<3 {
                let g = ((e - hit) * 0.8 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                let x = Int((chest.x + sin(g * 9 + Double(k)) * 2).rounded()), y = Int((chest.y - 3 - g * 14).rounded())
                let puff = C(0xB8B8C0, 0.75 * (1 - g))
                out.rect(x, y, g > 0.5 ? 3 : 2, g > 0.5 ? 2 : 2, puff)
            }
            let scorch = place(Sprite.bodyCenterX + 4, 31)
            out.rect(Int(scorch.x) - 1, Int(scorch.y), 2, 2, C(0x2A1A10, 0.85))
        }
        return (out, Int(out.opaqueBounds()?.minY ?? 0))
    }

    /// Han's bolt, the hit, and Greedo's own shot going off into the sky as he's knocked over.
    static func drawFX(_ c: PixelCanvas, e: Double, t: Double, han: Fighter, greedo: Fighter) {
        func bolt(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ g: Double, alpha: Double = 1) {
            let x = a.x + (b.x - a.x) * g, y = a.y + (b.y - a.y) * g
            let len = hypot(b.x - a.x, b.y - a.y)
            let ux = (b.x - a.x) / max(len, 0.01), uy = (b.y - a.y) / max(len, 0.01)
            c.glowLine(x - ux * 5, y - uy * 5, x, y, core: C(0xFFE0E0).alpha(alpha), glow: C(0xFF2A2A).alpha(alpha),
                       coreR: 0.6, glowR: 1.8)
        }
        let muzzle = han.point(han.muzzle.x + 2, han.muzzle.y + 0.5)
        if e < hit { bolt(muzzle, greedo.body, e / hit) }
        if e >= hit && e < hit + 0.15 { drawSparks(c, x: greedo.body.x, y: greedo.body.y, t: t, size: 3.5) }
        // His finger tightens as he goes over: a wild shot straight up.
        let wild = e - hit - 0.08
        if wild >= 0 && wild < 0.45 {
            let m = greedo.point(greedo.muzzle.x, greedo.muzzle.y - 2)
            bolt(m, (m.x + greedo.side * 8, m.y - 60), wild / 0.45, alpha: wild > 0.35 ? (0.45 - wild) / 0.1 : 1)
        }
        // A curl of smoke from Han's blaster.
        if e >= 0.1 && e < hit + 1.4 {
            let g = (e - 0.1) / (hit + 1.3)
            for k in 0..<2 {
                let gk = min(1, g + Double(k) * 0.15)
                let x = muzzle.x + sin(gk * 7 + Double(k)) * 1.5, y = muzzle.y - 2 - gk * 12
                c.glowLine(x, y, x, y, core: C(0xD8D8DE, 0.7 * (1 - gk)), glow: C(0x9A9AA6, 0.35 * (1 - gk)), coreR: 0.7, glowR: 1.6)
            }
        }
    }
}
