import Foundation

/// Anyone in the cast: a dark-side villain or a light-side hero. Any of them can be a session (drawn large)
/// or an agent (drawn small). Ids match `StatusStore`: villains < 100, heroes 100 + Companion.
enum Cast: Hashable {
    case villain(Leader)
    case hero(Companion)

    init(id: Int) {
        if id >= StatusStore.heroBase {
            self = .hero(Companion(rawValue: (id - StatusStore.heroBase) % Companion.allCases.count) ?? .luke)
        } else {
            self = .villain(Leader(index: id))
        }
    }

    /// An agent's character (records from before the shared cast only have a hero index).
    static func of(_ a: AgentRecord) -> Cast { Cast(id: a.cast ?? StatusStore.heroBase + a.character) }

    var id: Int {
        switch self {
        case .villain(let l): return l.rawValue
        case .hero(let h): return StatusStore.heroBase + h.rawValue
        }
    }

    var name: String {
        switch self { case .villain(let l): return l.name; case .hero(let h): return h.name }
    }

    var weapon: Weapon {
        switch self { case .villain(let l): return l.weapon; case .hero(let h): return h.weapon }
    }

    var isDark: Bool { if case .villain = self { return true } else { return false } }

    var home: Location {
        switch self { case .villain(let l): return Location.home(of: l); case .hero(let h): return Location.home(of: h) }
    }

    /// Top row of the head on the 72×52 canvas (for labels).
    var headTop: Int {
        switch self { case .villain(let l): return l.headTop; case .hero(let h): return h.headTop }
    }

    /// Where blaster bolts leave from (canvas pixels).
    var muzzle: (x: Double, y: Double) {
        switch self {
        case .villain(let l): return (Double(l.muzzle.x), Double(l.muzzle.y))
        case .hero(let h): return h.muzzle
        }
    }

    /// Where its weapon swings from (canvas pixels): the hand, or the Rancor's shoulder.
    var weaponPivot: (x: Double, y: Double) {
        if case .villain(let l) = self { return l.weaponPivot } else { return Sprite.hand }
    }

    /// Bolts ricochet off it (armour or a metal shell).
    var armoured: Bool { if case .villain(let l) = self { return l.armoured } else { return false } }

    var isHan: Bool { if case .hero(.han) = self { return true } else { return false } }
    var isGreedo: Bool { if case .villain(.greedo) = self { return true } else { return false } }

    /// Draw this character. `asSession` = it's a whole Claude/Codex session (it has moods: idle, thinking,
    /// waiting…); agents are always at work.
    func draw(_ c: PixelCanvas, t: Double, mode: VaderMode, walking: Bool, role: FightRole,
              urgent: Bool = false, sitting: Bool = false, asSession: Bool) {
        switch self {
        case .villain(let l):
            drawLeader(c, l, t: t, mode: asSession ? mode : .working, walking: walking, role: role,
                       urgent: asSession && urgent, sitting: asSession && sitting)
        case .hero(let h):
            drawCompanion(c, h, t: t, walking: walking, role: role, mode: asSession ? mode : .working,
                          urgent: asSession && urgent, sitting: asSession && sitting)
        }
    }
}

extension Cast {
    private static var measuredTops: [String: Int] = [:]

    /// The top row of this character as drawn at rest, standing or sitting, within 14 px of its body's centre: the
    /// hand-measured `headTop` misses some (the tauntaun's horns) and doesn't know a seated character sits lower, and
    /// the band leaves out what floats above (R2's notes, the Ewok's spear). Standing, never lower than `headTop`
    /// says; sitting, as much lower as the sprite really drops (nothing, for those that don't sit). Measured once per
    /// character and pose; name tags sit just above it.
    /// Its outline from above, standing at rest: for each column within 14 px of the body's centre, the top row drawn
    /// there (`Sprite.height` where nothing is, and outside that band). What a name tag must clear.
    func drawnProfile() -> [Int] {
        if let hit = Self.profiles[id] { return hit }
        let c = PixelCanvas(Sprite.width, Sprite.height)
        draw(c, t: 0, mode: .idle, walking: false, role: .none, asSession: true)
        let mid = Int(Sprite.bodyCenterX)
        let profile = (0..<Sprite.width).map { x -> Int in
            guard abs(x - mid) <= 14 else { return Sprite.height }
            return (0..<c.h).first { c.buf[($0 * c.w + x) * 4 + 3] > 0 } ?? Sprite.height
        }
        Self.profiles[id] = profile
        return profile
    }
    private static var profiles: [Int: [Int]] = [:]

    func drawnTop(sitting: Bool = false) -> Int {
        let key = "\(id)/\(sitting)"
        if let hit = Self.measuredTops[key] { return hit }
        func measure(_ seated: Bool) -> Int {
            let c = PixelCanvas(Sprite.width, Sprite.height)
            draw(c, t: 0, mode: .idle, walking: false, role: .none, sitting: seated, asSession: true)
            let mid = Int(Sprite.bodyCenterX)
            for y in 0..<c.h { for x in (mid - 14)...(mid + 14) where c.buf[(y * c.w + x) * 4 + 3] > 0 { return y } }
            return c.h
        }
        let standing = measure(false)
        let result = min(standing, headTop) + (sitting ? max(0, measure(true) - standing) : 0)
        Self.measuredTops[key] = result
        return result
    }
}
