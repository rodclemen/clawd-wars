import AppKit

/// One accent colour per project, shared by a Claude and its agents so you can see who belongs to whom
/// even mid-fight. Handed out first-come-first-served without collisions among the projects on screen,
/// and remembered, so a project keeps its colour between launches.
enum Accents {
    static let palette: [NSColor] = ([0xFF8A3D, 0x3DD6FF, 0xFF4FD8, 0x9BE84A, 0xFFD23D, 0xA57BFF, 0x2EE6B0, 0xFF6B6B] as [Int])
        .map { NSColor(srgbRed: CGFloat(($0 >> 16) & 0xFF) / 255, green: CGFloat(($0 >> 8) & 0xFF) / 255,
                       blue: CGFloat($0 & 0xFF) / 255, alpha: 1) }

    private static var assigned: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: "accents") as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "accents") }
    }

    /// Assign colours for the projects currently on screen (call once per refresh), then look them up.
    static func update(visible all: [String]) {
        // Each project once: several sessions in the same project share its colour, and must not count as a clash
        // with themselves (that made a shared project's colour flip every refresh).
        var seen = Set<String>()
        let projects = all.filter { seen.insert($0).inserted }
        var map = assigned
        var used = Set(projects.compactMap { map[$0] })
        for p in projects where !p.isEmpty {
            // Keep a remembered colour unless another visible project already holds it.
            if let i = map[p], projects.filter({ map[$0] == i }).count == 1 { continue }
            let free = (0..<palette.count).first { !used.contains($0) } ?? (abs(p.hashValue) % palette.count)
            map[p] = free
            used.insert(free)
        }
        if map != assigned { assigned = map }
    }

    static func color(for project: String) -> NSColor? {
        guard !project.isEmpty, let i = assigned[project] else { return nil }
        return palette[i % palette.count]
    }
}

/// Each AI's look: the outline round its sprites (always light, never black, so it reads on any desktop) and
/// the order its group appears in lists. Claude keeps the classic white.
enum AIStyle {
    static let order = ["claude", "claude-desktop", "codex", "qwen", "gemini", "copilot"]

    static func outlineHex(_ assistant: String) -> UInt32 {
        switch assistant {
        case "codex": return 0x6FD3FF     // cyan
        case "qwen": return 0xC08CFF      // lavender
        case "gemini": return 0xFFD166    // gold
        case "copilot": return 0x7CF5A4   // mint
        case "claude-desktop": return 0xFF9E7A   // coral: Claude, but in the desktop app
        default: return 0xFFFFFF          // Claude: white
        }
    }

    static func outline(_ assistant: String) -> Px { C(outlineHex(assistant), 0.92) }

    static func color(_ assistant: String) -> NSColor {
        let h = outlineHex(assistant)
        return NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255,
                       blue: CGFloat(h & 0xFF) / 255, alpha: 1)
    }

    static func rank(_ assistant: String) -> Int { order.firstIndex(of: assistant) ?? order.count }
}
