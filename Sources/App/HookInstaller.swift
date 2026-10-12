import Foundation

/// Adds/removes the clawd-wars-hook entries in ~/.claude/settings.json, leaving everything else untouched.
enum HookInstaller {
    static let events = [
        "SessionStart", "SessionEnd", "UserPromptSubmit", "PreToolUse", "PostToolUse", "PostToolUseFailure",
        "PermissionRequest", "Notification", "Stop", "StopFailure", "SubagentStart", "SubagentStop",
    ]
    static let toolEvents: Set<String> = ["PreToolUse", "PostToolUse", "PostToolUseFailure", "PermissionRequest"]
    /// The hook binary's name. Commands running the one before it (`vader-hook`) are ours too, so they get replaced.
    static let binaryName = "clawd-wars-hook"
    static func isOurs(command: String) -> Bool { command.contains(binaryName) || command.contains("vader-hook") }

    static var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
    }

    static var hookBinary: String {
        Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/" + binaryName).path
    }

    /// The hook command's executable, single-quoted for the shell (a `'` in the path becomes `'\''`).
    static var quotedBinary: String { "'" + hookBinary.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    private static func readSettings() throws -> [String: Any] { try readJSON(settingsURL) }

    private static func writeSettings(_ root: [String: Any]) throws { try writeJSON(root, to: settingsURL) }

    /// A settings file as a JSON object ([:] when it's missing or empty).
    private static func readJSON(_ url: URL) throws -> [String: Any] {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return [:] }
        let parsed: Any
        do { parsed = try JSONSerialization.jsonObject(with: data) } catch {
            // Comments are allowed by some of these AIs, but rewriting the file would drop them: leave it alone.
            let message = hasComments(String(decoding: data, as: UTF8.self))
                ? "\(url.path) has comments in it (JSONC), which Clawd Wars can't keep when it edits the file. "
                    + "Remove the comments, or add the hooks by hand."
                : "\(url.path) isn't valid JSON: \(error.localizedDescription)"
            throw NSError(domain: "ClawdWars", code: 3, userInfo: [NSLocalizedDescriptionKey: message])
        }
        guard let root = parsed as? [String: Any] else {
            throw NSError(domain: "ClawdWars", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "\(url.path) is not a JSON object"])
        }
        return root
    }

    /// `//` or `/* */` outside of strings.
    private static func hasComments(_ text: String) -> Bool {
        var inString = false, escaped = false, previous: Character = " "
        for c in text {
            if inString {
                if escaped { escaped = false } else if c == "\\" { escaped = true } else if c == "\"" { inString = false }
            } else if c == "\"" {
                inString = true
            } else if previous == "/" && (c == "/" || c == "*") {
                return true
            }
            previous = inString ? " " : c
        }
        return false
    }

    /// Writes through a symlink (dotfile managers link these files) and creates the folder if it's missing.
    private static func writeJSON(_ root: [String: Any], to url: URL) throws {
        let target = url.resolvingSymlinksInPath()
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys])
        try data.write(to: target, options: .atomic)
    }

    /// Keeps a copy of a file the first time we change it.
    private static func backUp(_ url: URL, as ext: String) {
        let source = url.resolvingSymlinksInPath()
        let backup = source.appendingPathExtension(ext)
        if FileManager.default.fileExists(atPath: source.path), !FileManager.default.fileExists(atPath: backup.path) {
            try? FileManager.default.copyItem(at: source, to: backup)
        }
    }

    private static func withoutOurs(_ groups: [[String: Any]]) -> [[String: Any]] {
        groups.compactMap { group in
            var g = group
            let hooks = (g["hooks"] as? [[String: Any]] ?? []).filter {
                !isOurs(command: ($0["command"] as? String) ?? "")
            }
            if hooks.isEmpty { return nil }
            g["hooks"] = hooks
            return g
        }
    }

    static var isInstalled: Bool {
        guard let root = try? readSettings(), let hooks = root["hooks"] as? [String: Any] else { return false }
        return events.allSatisfy { e in
            let groups = hooks[e] as? [[String: Any]] ?? []
            return groups.contains { g in
                (g["hooks"] as? [[String: Any]] ?? []).contains {
                    isOurs(command: ($0["command"] as? String) ?? "")
                }
            }
        }
    }

    static func install() throws {
        var root = try readSettings()
        backUp(settingsURL, as: "before-vader")
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        for e in events {
            var groups = withoutOurs(hooks[e] as? [[String: Any]] ?? [])
            var group: [String: Any] = ["hooks": [["type": "command", "command": quotedBinary, "timeout": 5]]]
            if toolEvents.contains(e) { group["matcher"] = "*" }
            groups.append(group)
            hooks[e] = groups
        }
        root["hooks"] = hooks
        try writeSettings(root)
    }

    static func uninstall() throws {
        var root = try readSettings()
        guard var hooks = root["hooks"] as? [String: Any] else { return }
        for e in events {
            let groups = withoutOurs(hooks[e] as? [[String: Any]] ?? [])
            hooks[e] = groups.isEmpty ? nil : groups
        }
        root["hooks"] = hooks.isEmpty ? nil : hooks
        try writeSettings(root)
    }

    // MARK: Other AIs (Codex, Qwen Code, Gemini CLI, Copilot CLI)
    //
    // All read Claude Code-style hook config: { "hooks": { Event: [ { matcher?, hooks: [ {type, command, timeout} ] } ] } }
    // (Copilot CLI uses flat entries: { "hooks": { Event: [ {type, bash, timeoutSec} ] } }). Our handler runs the same
    // hook binary with `--assistant <name>` so it knows which AI is calling, and `--event <name>` where the payload
    // doesn't say (or uses that AI's own event names, which the hook translates).

    struct OtherAI {
        let name: String            // "codex" / "qwen" / "gemini" / "copilot" — passed to the hook as --assistant
        let dir: URL                // ~/.codex, ~/.qwen, ~/.gemini, ~/.copilot
        let file: URL               // the file our hooks go in
        let events: [String]
        let toolEvents: Set<String> // events that take a matcher
        let matcherAll: String?     // how this AI spells "match every tool" (nil = omit the matcher)
        var shortTimeoutEvents: Set<String> = []
        var binaries: [String] = []  // if set, installed only when one of these commands exists (its dir alone isn't proof)
        var flat = false             // Copilot: entries are the handlers themselves, no nested "hooks" array
        var commandKey = "command"
        var timeoutKey = "timeout"
        var timeoutScale = 1         // Gemini wants milliseconds
        var passEvent = false        // add --event <Event> to each handler
        var name_: String? = nil     // handler "name" (lets the AI toggle it in /hooks)
        var eventAliases: [String: String] = [:]   // config key → event name to pass (Copilot's camelCase subagentStart)
        var ownFile = false          // the whole file is ours (deleted on uninstall when nothing else is left)
    }

    static let codex = OtherAI(
        name: "codex", dir: home(".codex"), file: home(".codex/hooks.json"),
        events: ["SessionStart", "SessionEnd", "UserPromptSubmit", "PreToolUse", "PostToolUse", "PermissionRequest",
                 "Stop", "Interrupt", "SubagentStart", "SubagentStop"],
        toolEvents: [], matcherAll: nil, shortTimeoutEvents: ["SessionEnd", "Interrupt"])   // these allow ≤ 3 s

    static let qwen = OtherAI(
        name: "qwen", dir: home(".qwen"), file: home(".qwen/settings.json"),
        events: ["SessionStart", "SessionEnd", "UserPromptSubmit", "PreToolUse", "PostToolUse", "PostToolUseFailure",
                 "PermissionRequest", "Notification", "Stop", "StopFailure", "SubagentStart", "SubagentStop"],
        toolEvents: ["PreToolUse", "PostToolUse", "PostToolUseFailure", "PermissionRequest"],
        matcherAll: ".*", name_: "clawd-wars")                                                // Qwen matchers are regexes

    /// Gemini CLI: its own event names (BeforeAgent, AfterTool…), translated by the hook. ~/.gemini is shared with
    /// Antigravity, so only a `gemini` command counts as installed.
    static let gemini = OtherAI(
        name: "gemini", dir: home(".gemini"), file: home(".gemini/settings.json"),
        events: ["SessionStart", "SessionEnd", "BeforeAgent", "AfterAgent", "BeforeTool", "AfterTool", "Notification"],
        toolEvents: ["BeforeTool", "AfterTool"], matcherAll: ".*",
        binaries: ["gemini"], timeoutScale: 1000, passEvent: true, name_: "clawd-wars")

    /// GitHub Copilot CLI: a file of our own in ~/.copilot/hooks. PascalCase event names select its Claude-compatible
    /// payloads (snake_case fields, Claude tool names); SubagentStart only exists as camelCase.
    static let copilot = OtherAI(
        name: "copilot", dir: home(".copilot"), file: home(".copilot/hooks/clawd-wars.json"),
        events: ["SessionStart", "SessionEnd", "UserPromptSubmit", "PreToolUse", "PostToolUse", "PostToolUseFailure",
                 "PermissionRequest", "Notification", "Stop", "subagentStart", "SubagentStop"],
        toolEvents: [], matcherAll: nil,
        binaries: ["copilot"], flat: true, commandKey: "bash", timeoutKey: "timeoutSec", passEvent: true,
        eventAliases: ["subagentStart": "SubagentStart"], ownFile: true)

    static let others = [codex, qwen, gemini, copilot]

    static func other(_ name: String) -> OtherAI? { others.first { $0.name == name } }

    /// Is Claude Code on this Mac? ~/.claude alone isn't proof: Clawd Wars keeps its own state in there.
    static var claudeAvailable: Bool {
        [".claude/projects", ".claude.json", ".claude/settings.json"].contains {
            FileManager.default.fileExists(atPath: home($0).path)
        }
    }

    /// Display name for an assistant id.
    static func displayName(_ assistant: String) -> String {
        switch assistant {
        case "codex": return "Codex"
        case "qwen": return "Qwen Code"
        case "gemini": return "Gemini CLI"
        case "copilot": return "Copilot CLI"
        case "claude-desktop": return "Claude Desktop"
        default: return "Claude Code"
        }
    }

    /// What to do when this AI's session runs but our hook never reports.
    static func silentFix(_ assistant: String) -> String {
        switch assistant {
        case "codex": return "type /hooks in Codex and approve Clawd Wars"
        case "qwen": return "type /hooks in Qwen Code and make sure clawd-wars is enabled"
        case "gemini": return "type /hooks panel in Gemini CLI and make sure clawd-wars is enabled"
        case "copilot": return "check hooks aren't turned off (disableAllHooks) and restart Copilot CLI"
        default: return "type /hooks in Claude Code and check the Clawd Wars hooks are listed"
        }
    }

    private static func home(_ path: String) -> URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(path) }

    /// Where command-line tools usually live. The app is launched by launchd with a bare PATH, so look ourselves.
    private static var binDirs: [String] {
        var dirs = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"]
            + [".local/bin", ".npm-global/bin", ".volta/bin", ".bun/bin", "Library/pnpm", ".yarn/bin", ".asdf/shims",
               ".local/share/mise/shims", ".npm/bin"].map { home($0).path }
        let nvm = home(".nvm/versions/node")
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvm.path) {
            dirs += versions.map { nvm.appendingPathComponent($0).appendingPathComponent("bin").path }
        }
        return dirs
    }

    static func available(_ ai: OtherAI) -> Bool {
        guard ai.binaries.isEmpty else {
            return binDirs.contains { d in ai.binaries.contains { FileManager.default.isExecutableFile(atPath: d + "/" + $0) } }
        }
        return FileManager.default.fileExists(atPath: ai.dir.path)
    }

    private static func read(_ ai: OtherAI) throws -> [String: Any] { try readJSON(ai.file) }

    /// An entry (group or flat handler) is ours if any command in it runs our hook.
    private static func isOurs(_ entry: [String: Any]) -> Bool {
        let handlers = (entry["hooks"] as? [[String: Any]] ?? []) + [entry]
        return handlers.contains { h in ["command", "bash"].contains { isOurs(command: (h[$0] as? String) ?? "") } }
    }

    private static func withoutOurs(_ ai: OtherAI, _ entries: [[String: Any]]) -> [[String: Any]] {
        ai.flat ? entries.filter { !isOurs($0) } : withoutOurs(entries)
    }

    static func installed(_ ai: OtherAI) -> Bool {
        guard let root = try? read(ai), let hooks = root["hooks"] as? [String: Any] else { return false }
        return ai.events.allSatisfy { e in (hooks[e] as? [[String: Any]] ?? []).contains(where: isOurs) }
    }

    /// Adds our hook to every event, keeping everything else in the file (a backup is kept the first time).
    static func install(_ ai: OtherAI) throws {
        guard available(ai) else { return }
        var root = try read(ai)
        if !ai.ownFile { backUp(ai.file, as: "before-clawd-wars") }
        if ai.flat { root["version"] = 1 }
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        for e in ai.events {
            var entries = withoutOurs(ai, hooks[e] as? [[String: Any]] ?? [])
            var command = "\(quotedBinary) --assistant \(ai.name)"
            if ai.passEvent { command += " --event \(ai.eventAliases[e] ?? e)" }
            var handler: [String: Any] = ["type": "command", ai.commandKey: command,
                                          ai.timeoutKey: (ai.shortTimeoutEvents.contains(e) ? 3 : 5) * ai.timeoutScale]
            if let n = ai.name_ { handler["name"] = n }
            if ai.flat {
                entries.append(handler)
            } else {
                var group: [String: Any] = ["hooks": [handler]]
                if ai.toolEvents.contains(e), let all = ai.matcherAll { group["matcher"] = all }
                entries.append(group)
            }
            hooks[e] = entries
        }
        root["hooks"] = hooks
        try writeJSON(root, to: ai.file)
    }

    static func uninstall(_ ai: OtherAI) throws {
        guard FileManager.default.fileExists(atPath: ai.file.path) else { return }
        var root = try read(ai)
        guard var hooks = root["hooks"] as? [String: Any] else { return }
        for e in ai.events {
            let entries = withoutOurs(ai, hooks[e] as? [[String: Any]] ?? [])
            hooks[e] = entries.isEmpty ? nil : entries
        }
        root["hooks"] = hooks.isEmpty ? nil : hooks
        // Nothing of anyone's left (our own file, or one that only ever held our hooks, like a hooks.json we
        // created): delete it rather than leave an empty file behind.
        if ai.ownFile && hooks.isEmpty || root.keys.allSatisfy({ $0 == "version" }) {
            try FileManager.default.removeItem(at: ai.file)
            return
        }
        try writeJSON(root, to: ai.file)
    }

    // MARK: Moved app
    //
    // Hooks remember the absolute path of the hook binary. If the app is moved (or reinstalled somewhere else) they
    // point at nothing and every event fails, yet `isInstalled` still sees our command. Only a missing binary counts
    // as stale, so a dev copy run from build/ never steals hooks that still work.

    /// The hook binaries our registered commands run, in any of the shapes above.
    private static func ourBinaries(in root: [String: Any]) -> [String] {
        guard let hooks = root["hooks"] as? [String: Any] else { return [] }
        let entries: [[String: Any]] = hooks.values.flatMap { $0 as? [[String: Any]] ?? [] }
        let handlers: [[String: Any]] = entries.flatMap { ($0["hooks"] as? [[String: Any]] ?? []) + [$0] }
        let commands: [String] = handlers.flatMap { h in ["command", "bash"].compactMap { h[$0] as? String } }
        return commands.filter { isOurs(command: $0) }.map(binary)
    }

    /// The executable a command runs: the quoted path we write ('…' now, "…" before), or the first word.
    private static func binary(_ command: String) -> String {
        if command.hasPrefix("\"") { return String(command.dropFirst().prefix { $0 != "\"" }) }
        guard command.hasPrefix("'") else { return String(command.prefix { $0 != " " }) }
        // Shell single quotes: everything literal up to the next ', where '\'' stands for a quote in the path.
        var path = "", rest = command.dropFirst()
        while let end = rest.firstIndex(of: "'") {
            path += rest[..<end]
            rest = rest[rest.index(after: end)...]
            guard rest.hasPrefix("\\''") else { return path }
            path += "'"
            rest = rest.dropFirst(3)
        }
        return path + rest
    }

    private static func isStale(_ root: [String: Any]) -> Bool {
        ourBinaries(in: root).contains { !FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Re-points hooks whose binary is gone at this copy of the app. Returns the assistants repaired.
    @discardableResult
    static func repairMoved() -> [String] {
        guard FileManager.default.isExecutableFile(atPath: hookBinary) else { return [] }
        var repaired: [String] = []
        if let root = try? readSettings(), isStale(root), (try? install()) != nil { repaired.append("claude") }
        for ai in others where available(ai) {
            if let root = try? read(ai), isStale(root), (try? install(ai)) != nil { repaired.append(ai.name) }
        }
        return repaired
    }

    // MARK: Everything at once (CLI, first launch)

    /// Connects every AI on this Mac (Claude Code only when it's installed). One failing doesn't stop the
    /// others; returns the ones connected and an error message per failure.
    static func installAll(_ names: [String]? = nil) -> (installed: [String], errors: [String]) {
        var done: [String] = [], errors: [String] = []
        if names?.contains("claude") ?? true, claudeAvailable {
            do { try install(); done.append("claude") } catch { errors.append("Claude Code: \(error.localizedDescription)") }
        }
        for ai in others where (names?.contains(ai.name) ?? true) && available(ai) {
            do { try install(ai); done.append(ai.name) } catch { errors.append("\(displayName(ai.name)): \(error.localizedDescription)") }
        }
        return (done, errors)
    }

    /// Disconnects every AI; returns the ones that had our hooks and an error message per failure.
    static func uninstallAll() -> (removed: [String], errors: [String]) {
        var done: [String] = [], errors: [String] = []
        let claudeHad = (try? readSettings()).map { !ourBinaries(in: $0).isEmpty } ?? false
        do { try uninstall(); if claudeHad { done.append("claude") } } catch { errors.append("Claude Code: \(error.localizedDescription)") }
        for ai in others {
            let had = (try? read(ai)).map { !ourBinaries(in: $0).isEmpty } ?? false
            do { try uninstall(ai); if had { done.append(ai.name) } } catch { errors.append("\(displayName(ai.name)): \(error.localizedDescription)") }
        }
        return (done, errors)
    }

    // MARK: Homebrew upgrade
    //
    // The cask's uninstall step runs `--uninstall-hooks`, and `brew upgrade` runs it too, which would quietly
    // disconnect everything. So `--uninstall-hooks` leaves a note of what it removed, and the next launch puts
    // exactly those back. Removing hooks from the Settings menu calls `uninstall` directly and leaves no note.

    static let removedMarker = StatusPaths.dir.appendingPathComponent("hooks-removed")

    static func rememberRemoved(_ names: [String]) {
        guard !names.isEmpty else { return }
        try? FileManager.default.createDirectory(at: StatusPaths.dir, withIntermediateDirectories: true)
        try? (names.joined(separator: "\n") + "\n").write(to: removedMarker, atomically: true, encoding: .utf8)
    }

    /// Reconnects the AIs a `--uninstall-hooks` removed (those still on this Mac), then forgets the note.
    @discardableResult
    /// The AIs that have any of our hooks: the ones you've connected. `--update-hooks` refreshes only these.
    static func connected() -> [String] {
        var names: [String] = []
        if let root = try? readSettings(), !ourBinaries(in: root).isEmpty { names.append("claude") }
        for ai in others {
            guard let hooks = (try? read(ai))?["hooks"] as? [String: Any] else { continue }
            if hooks.values.contains(where: { ($0 as? [[String: Any]] ?? []).contains(where: isOurs) }) { names.append(ai.name) }
        }
        return names
    }

    static func restoreRemoved() -> (installed: [String], errors: [String]) {
        guard let text = try? String(contentsOf: removedMarker, encoding: .utf8) else { return ([], []) }
        try? FileManager.default.removeItem(at: removedMarker)
        let names = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        return names.isEmpty ? ([], []) : installAll(names)
    }

    // Codex conveniences used by the app and CLI
    static var codexAvailable: Bool { available(codex) }
    static var codexInstalled: Bool { installed(codex) }
    static func installCodex() throws { try install(codex) }
    static func uninstallCodex() throws { try uninstall(codex) }
}
