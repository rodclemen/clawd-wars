import AppKit

/// Settings → Status Symbols: what each thing over a character's head means, drawn with the same code as the crew
/// so the key always matches what's on screen.
enum Legend {
    struct Entry {
        let title: String
        let detail: String
        let icon: NSImage?
    }

    /// Every icon is drawn into the same box so the rows line up.
    static let box = NSSize(width: 36, height: 28)

    /// The crew's poses and bubbles, then the colours and banners around them.
    static var sections: [[Entry]] { [crew, around] }

    private static var crew: [Entry] {
        [
            Entry(title: "Working", detail: "Swinging a lightsaber (or firing): running tools",
                  icon: character(mode: .working, t: 0.35)),
            Entry(title: "Thinking", detail: "Three dots filling up",
                  icon: bubble(.thinking, t: 1.2)),
            Entry(title: "Needs you", detail: "A red “!”: waiting for your permission. It starts jumping after a minute",
                  icon: bubble(.waiting, t: 0.1)),
            Entry(title: "Idle", detail: "Sitting on the floor: done for 2+ minutes (the big ones stay standing)",
                  icon: character(mode: .idle, t: 0, sitting: true)),
            Entry(title: "Asleep", detail: "zZz: idle for 5+ minutes",
                  icon: bubble(.sleeping, t: 0)),
            Entry(title: "No live status", detail: "A “?”: the session started before the hooks were installed, or they stopped "
                  + "reporting. Restart it (/exit, then claude --continue). Codex: approve Clawd Wars in /hooks",
                  icon: bubble(.unknown, t: 0)),
            Entry(title: "You're here", detail: "A little yellow marker bobbing over its head: the session whose terminal you're looking at",
                  icon: caret()),
        ]
    }

    private static var around: [Entry] {
        [
            Entry(title: "Outline colour", detail: "Which AI runs it: Claude white, Claude desktop app coral, Codex cyan, "
                  + "Qwen Code lavender, Gemini CLI gold, Copilot CLI mint",
                  icon: outlines()),
            Entry(title: "Label colour", detail: "A Claude and its agents share their project's colour",
                  icon: swatches(Array(Accents.palette.prefix(3)))),
            Entry(title: "Banner and ⚠︎ menu item", detail: "An AI on your Mac isn't connected, or a session isn't reporting. "
                  + "The menu item fixes it",
                  icon: symbol("exclamationmark.triangle.fill", NSColor(srgbRed: 1, green: 0.72, blue: 0.2, alpha: 1))),
            Entry(title: "Red OFFLINE banner", detail: "The status file can't be read, so nothing shown is current",
                  icon: symbol("wifi.slash", NSColor(srgbRed: 0.88, green: 0.19, blue: 0.23, alpha: 1))),
        ]
    }

    /// A row of the submenu: the icon, the name in bold and what it means underneath in the secondary colour.
    static func menuItem(_ e: Entry) -> NSMenuItem {
        let item = NSMenuItem(title: e.title, action: nil, keyEquivalent: "")
        let text = NSMutableAttributedString(string: e.title + "\n", attributes: [
            .font: NSFont.menuFont(ofSize: 0).bold, .foregroundColor: NSColor.labelColor])
        let wrap = NSMutableParagraphStyle()
        wrap.lineBreakMode = .byWordWrapping
        text.append(NSAttributedString(string: wrapped(e.detail, width: 52), attributes: [
            .font: NSFont.menuFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: wrap]))
        item.attributedTitle = text
        item.image = e.icon
        return item
    }

    /// Menus don't wrap long titles, so break the explanation into lines of about `width` characters.
    private static func wrapped(_ s: String, width: Int) -> String {
        var lines: [String] = [], line = ""
        for word in s.split(separator: " ") {
            if !line.isEmpty, line.count + 1 + word.count > width { lines.append(line); line = "" }
            line += (line.isEmpty ? "" : " ") + word
        }
        if !line.isEmpty { lines.append(line) }
        return lines.joined(separator: "\n")
    }

    // MARK: Icons

    /// Darth Vader as a session draws him, cropped to what's drawn, with the white outline Claude's characters wear.
    private static func character(mode: VaderMode, t: Double, sitting: Bool = false) -> NSImage? {
        let c = PixelCanvas(Sprite.width, Sprite.height)
        drawLeader(c, .vader, t: t, mode: mode, walking: false, sitting: sitting)
        c.addOutline(AIStyle.outline("claude"))
        return image(c)
    }

    private static func bubble(_ kind: BubbleKind, t: Double) -> NSImage? {
        let c = PixelCanvas(Bubble.width, Bubble.height)
        drawBubble(c, kind: kind, t: t)
        return image(c, scale: 2)   // a bubble is small next to the sprite's whole canvas
    }

    private static func caret() -> NSImage? {
        let c = PixelCanvas(3, 3)
        drawFocusCaret(c)
        return image(c, scale: 4)
    }

    /// One square per AI in its outline colour.
    private static func outlines() -> NSImage? {
        swatches(["claude", "claude-desktop", "codex", "qwen", "gemini", "copilot"].map(AIStyle.color), size: 4, columns: 3)
    }

    private static func swatches(_ colors: [NSColor], size: CGFloat = 6, columns: Int? = nil) -> NSImage? {
        let cols = columns ?? colors.count, rows = (colors.count + cols - 1) / cols, gap: CGFloat = 2
        let w = CGFloat(cols) * size + CGFloat(cols - 1) * gap, h = CGFloat(rows) * size + CGFloat(rows - 1) * gap
        return NSImage(size: box, flipped: true) { _ in
            let x0 = ((box.width - w) / 2).rounded(), y0 = ((box.height - h) / 2).rounded()
            for (i, color) in colors.enumerated() {
                let r = NSRect(x: x0 + CGFloat(i % cols) * (size + gap), y: y0 + CGFloat(i / cols) * (size + gap),
                               width: size, height: size)
                color.setFill(); r.fill()
                NSColor.black.withAlphaComponent(0.35).setStroke(); NSBezierPath(rect: r.insetBy(dx: 0.25, dy: 0.25)).stroke()
            }
            return true
        }
    }

    private static func symbol(_ name: String, _ color: NSColor) -> NSImage? {
        guard let s = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 15, weight: .regular)) else { return nil }
        return NSImage(size: box, flipped: false) { _ in
            let r = NSRect(x: (box.width - s.size.width) / 2, y: (box.height - s.size.height) / 2,
                           width: s.size.width, height: s.size.height)
            s.draw(in: r)
            color.set()
            r.fill(using: .sourceAtop)
            return true
        }
    }

    /// The canvas cropped to what was drawn and centred in the box, `scale` points per art pixel (smaller if it
    /// doesn't fit), without smoothing, so the pixels stay crisp at any screen resolution.
    private static func image(_ c: PixelCanvas, scale: CGFloat = 1) -> NSImage? {
        guard let bounds = c.opaqueBounds(), let cg = c.makeImage()?.cropping(to: bounds) else { return nil }
        let fit = min(scale, box.width / bounds.width, box.height / bounds.height)
        let size = NSSize(width: bounds.width * fit, height: bounds.height * fit)
        return NSImage(size: box, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.interpolationQuality = .none
            ctx.draw(cg, in: CGRect(x: ((box.width - size.width) / 2).rounded(), y: ((box.height - size.height) / 2).rounded(),
                                    width: size.width, height: size.height))
            return true
        }
    }
}

private extension NSFont {
    var bold: NSFont { NSFontManager.shared.convert(self, toHaveTrait: .boldFontMask) }
}
