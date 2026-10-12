import Darwin
import Foundation

/// Finds running Claude Code sessions directly from the process table, so sessions show up even
/// before (or without) their hooks firing, and vanish the moment their process exits.
enum ClaudeProcesses {
    struct Info { let pid: Int32; let project: String; var assistant = "claude"; var started: Double = 0; var client: String? = nil }

    private static let shells: Set<String> = ["sh", "bash", "zsh", "dash", "fish", "env"]

    static func name(_ pid: Int32) -> String {
        var buf = [CChar](repeating: 0, count: 1024)
        proc_name(pid, &buf, UInt32(buf.count))
        return String(cString: buf)
    }

    private static func kinfo(_ pid: Int32) -> kinfo_proc? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info
    }

    static func parent(_ pid: Int32) -> Int32? {
        guard let p = kinfo(pid)?.kp_eproc.e_ppid else { return nil }
        return p > 1 ? p : nil
    }

    /// When a process started (seconds since 1970), so a recycled pid can be told from the process that had it.
    static func startTime(_ pid: Int32) -> Double? {
        guard let st = kinfo(pid)?.kp_proc.p_starttime, st.tv_sec > 0 else { return nil }
        return Double(st.tv_sec) + Double(st.tv_usec) / 1e6
    }

    /// The Claude Code process that ran this hook: the first ancestor that isn't a shell.
    static func hookOwner() -> Int32? {
        var pid = getppid()
        for _ in 0..<6 {
            if !shells.contains(name(pid)) { return pid }
            guard let p = parent(pid) else { return nil }
            pid = p
        }
        return nil
    }

    static func arguments(_ pid: Int32) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 4 else { return [] }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buf, &size, nil, 0) == 0 else { return [] }
        let argc = buf.withUnsafeBytes { $0.load(as: Int32.self) }
        var i = 4
        while i < size && buf[i] != 0 { i += 1 }   // exec path
        while i < size && buf[i] == 0 { i += 1 }   // padding
        var args: [String] = []
        while args.count < argc && i < size {
            let start = i
            while i < size && buf[i] != 0 { i += 1 }
            args.append(String(decoding: buf[start..<i], as: UTF8.self))
            i += 1
        }
        return args
    }

    /// Total CPU time used by a process, in seconds.
    static func cpuSeconds(_ pid: Int32) -> Double? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }
        var tb = mach_timebase_info_data_t()
        mach_timebase_info(&tb)
        let ticks = Double(info.pti_total_user + info.pti_total_system)
        return ticks * Double(tb.numer) / Double(tb.denom) / 1e9
    }

    static func cwd(_ pid: Int32) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        return withUnsafePointer(to: &info.pvi_cdir.vip_path) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) { String(cString: $0) }
        }
    }

    /// What a process turned out to be, remembered so its arguments are only read once. Keyed by pid and
    /// checked against start time and name, so a reused pid or an `exec` is looked at again.
    private struct Kind { let started: Double; let comm: String; let assistant: String?; let client: String? }
    private static var kinds: [Int32: Kind] = [:]

    /// Codex's terminal UI runs its turns in a shared background server (`codex app-server --managed-daemon`) that
    /// outlives it, and the hooks run under that server. A session recorded on the server's pid would never end, so
    /// the hook records the Codex session in the same folder instead (the newest, if there are several).
    static func codexSession(server pid: Int32, cwd: String?) -> Int32? {
        guard let cwd, arguments(pid).contains("--managed-daemon") else { return nil }
        let folder = URL(fileURLWithPath: cwd).standardizedFileURL.path
        return running().filter { p in
            p.assistant == "codex" && self.cwd(p.pid).map { URL(fileURLWithPath: $0).standardizedFileURL.path } == folder
        }.max { $0.started < $1.started }?.pid
    }

    /// Interactive `claude` sessions (not `claude -p` one-shots, MCP servers or the Chrome bridge).
    /// Empty if the process table can't be read; see `runningOrNil`.
    static func running() -> [Info] { runningOrNil() ?? [] }

    /// Like `running`, but nil when the process table can't be read, so callers can keep the last list
    /// instead of dropping every session.
    static func runningOrNil() -> [Info]? {
        // All of this user's processes in one call, instead of one call per process on the Mac.
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_UID, Int32(bitPattern: getuid())]
        let stride = MemoryLayout<kinfo_proc>.stride
        var procs: [kinfo_proc] = []
        var size = 0
        var ok = false
        for _ in 0..<2 {   // ENOMEM: more processes appeared than the extra room allows; measure again once
            size = 0
            guard sysctl(&mib, 4, nil, &size, nil, 0) == 0 else { return nil }
            size += 64 * stride   // room for processes started in between
            procs = [kinfo_proc](repeating: kinfo_proc(), count: size / stride)
            if sysctl(&mib, 4, &procs, &size, nil, 0) == 0 { ok = true; break }
            if errno != ENOMEM { return nil }
        }
        guard ok else { return nil }
        var found: [Info] = []
        var seen: [Int32: Kind] = [:]
        for info in procs.prefix(size / stride) {
            let pid = info.kp_proc.p_pid
            guard pid > 0 else { continue }
            let st = info.kp_proc.p_starttime
            let started = Double(st.tv_sec) + Double(st.tv_usec) / 1e6
            let comm = withUnsafeBytes(of: info.kp_proc.p_comm) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            var kind = kinds[pid]
            if kind?.started != started || kind?.comm != comm {
                let (assistant, client) = classify(pid)
                kind = Kind(started: started, comm: comm, assistant: assistant, client: client)
            }
            seen[pid] = kind
            guard let kind, let assistant = kind.assistant else { continue }
            // The cwd is read every time: it follows a folder rename.
            let project = cwd(pid).map { ($0 as NSString).lastPathComponent } ?? ""
            found.append(Info(pid: pid, project: project, assistant: assistant, started: started, client: kind.client))
        }
        kinds = seen
        // A claude launched by another claude (e.g. a nested tool) isn't a separate session. The other AIs are
        // often an npm wrapper (or Gemini/Qwen relaunching itself) starting the real process: keep that child,
        // since it's the one that runs the hooks.
        let byPid = Dictionary(found.map { ($0.pid, $0) }, uniquingKeysWith: { a, _ in a })
        var drop = Set<Int32>()
        for info in found {
            guard let p = parent(info.pid), let up = byPid[p], up.assistant == info.assistant else { continue }
            drop.insert(info.assistant == "claude" ? info.pid : up.pid)
        }
        return found.filter { !drop.contains($0.pid) }.sorted { $0.pid < $1.pid }
    }

    private static let names: Set<String> = ["claude", "codex", "qwen", "gemini", "copilot"]
    /// Per AI, since they don't agree: Codex's `-p` is `--profile`, an interactive session.
    private static let oneShotFlags: [String: Set<String>] = [
        "claude": ["-p", "--print", "--chrome-native-host", "--version", "-v"],
        "codex": ["--version", "-V"],
        "qwen": ["-p", "--prompt", "--version", "-v"],
        "gemini": ["-p", "--prompt", "--version", "-v"],
        "copilot": ["-p", "--prompt", "--version", "-v"],
    ]
    private static let subcommands: [String: Set<String>] = [
        "claude": ["mcp", "update", "doctor", "install", "config", "setup-token", "migrate-installer", "plugin"],
        "codex": ["exec", "e", "login", "logout", "mcp", "mcp-server", "app-server", "completion", "proto", "apply", "sandbox", "debug"],
        "qwen": ["mcp", "extensions"],
        "gemini": ["mcp", "extensions"],
        "copilot": ["update", "help", "version"],
    ]

    /// Background servers editors start (the VS Code ChatGPT extension runs `codex -c … app-server`): never a prompt
    /// word, so they count anywhere on the command line.
    private static let helpers: Set<String> = ["app-server", "mcp-server", "proto"]
    /// Flags that take the next argument as their value, so that value isn't mistaken for the subcommand.
    private static let valueFlags: Set<String> = ["-c", "--config", "-m", "--model", "-p", "--profile", "-C", "--cd",
                                                  "-s", "--sandbox", "-a", "--ask-for-approval", "-i", "--image",
                                                  "--enable", "--disable", "--add-dir", "--settings", "--permission-mode"]

    /// The first argument that isn't a flag or a flag's value: where a subcommand would be.
    private static func firstWord(_ args: ArraySlice<String>) -> String? {
        var skipNext = false
        for a in args {
            if skipNext { skipNext = false; continue }
            if a.hasPrefix("-") { skipNext = valueFlags.contains(a); continue }
            return a
        }
        return nil
    }

    /// Which AI an interactive session process belongs to (nil if it isn't one), and Claude Code's client.
    private static func classify(_ pid: Int32) -> (assistant: String?, client: String?) {
        let args = arguments(pid)
        guard let first = args.first else { return (nil, nil) }
        let exe = (first as NSString).lastPathComponent
        let isClaude = exe == "claude" || args.contains { $0.hasSuffix("@anthropic-ai/claude-code/cli.js") }
        let isCodex = exe == "codex" || args.contains { $0.contains("@openai/codex") && $0.hasSuffix(".js") }
        let isQwen = exe == "qwen" || args.contains { $0.contains("@qwen-code/qwen-code") && $0.hasSuffix(".js") }
        let isGemini = exe == "gemini" || args.contains { $0.contains("@google/gemini-cli/") && $0.hasSuffix(".js") }
        // "@github/copilot/" with the slash: not VS Code's copilot-language-server
        let isCopilot = exe == "copilot" || args.contains { $0.contains("@github/copilot/") && $0.hasSuffix(".js") }
        guard isClaude || isCodex || isQwen || isGemini || isCopilot else { return (nil, nil) }
        let assistant = isCodex ? "codex" : isQwen ? "qwen" : isGemini ? "gemini" : isCopilot ? "copilot" : "claude"
        // The AI's own arguments: after the executable, or after the script when node runs it.
        let script = names.contains(exe) ? 0 : args.firstIndex { $0.hasSuffix(".js") } ?? 0
        let own = args.dropFirst(script + 1)
        // One-shots and helpers aren't sessions. Flags count anywhere; subcommands only as the first word
        // (`claude "update the docs"` is a session, `claude update` isn't).
        if own.contains(where: { (oneShotFlags[assistant] ?? []).contains($0) }) { return (nil, nil) }
        if own.contains(where: helpers.contains) { return (nil, nil) }
        if let sub = firstWord(own), (subcommands[assistant] ?? []).contains(sub) { return (nil, nil) }
        // Claude Code bundled with the desktop app or the VS Code extension, told apart by where it lives.
        let client: String? = !isClaude ? nil
            : first.contains("/Application Support/Claude/claude-code/") ? "claude-desktop"
            : first.contains("/extensions/anthropic.claude-code") ? "claude-vscode" : nil
        return (assistant, client)
    }
}
