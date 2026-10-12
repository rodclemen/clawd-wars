import Foundation

extension SaverFeed {
    /// With Clawd Wars closed: the crew straight from what the hooks keep writing (`~/.claude/vader-status/state.json`),
    /// so the saver still shows the sessions that are running. Rougher than the app's feed: the saver's sandbox can't
    /// scan processes, so sessions without hooks don't show, and one that died without saying goodbye stays until its
    /// state times out. No events either (the app makes those). Nil when no session is running.
    /// `last` is the app's last feed, for the place and the projects' colours.
    static func fromHooks(now: Double, last: SaverFeed?) -> SaverFeed? {
        guard let file = StatusStore.load() else { return nil }
        let accents = Dictionary((last?.sessions ?? []).compactMap { s in s.accent.map { (s.project, $0) } },
                                 uniquingKeysWith: { a, _ in a })
        let sessions: [Session] = StatusStore.snapshot(file, now: now).filter { $0.id != "home" }.map { s in
            // How long it's held this mood, and what that makes it, as the app judges it.
            let since = s.record.flatMap { $0.state == s.mood.rawValue ? $0.since : nil } ?? s.record?.updated ?? now
            let held = now - since
            let resting = s.mood == .idle && s.record != nil
            return Session(
                id: s.id, cast: s.leader, assistant: s.group, project: s.project, remote: nil, accent: accents[s.project],
                mood: s.mood.rawValue, urgent: s.mood == .waiting && held > 60, asleep: resting && held > 300,
                sitting: resting && held > 120, unknown: false, focused: nil, since: since,
                activity: s.mood == .idle ? nil : s.record?.activity, prompt: s.record?.prompt,
                agents: s.agents.map { Agent(id: $0.id, cast: Cast.of($0).id, task: $0.label.isEmpty ? "Agent" : $0.label) })
        }
        guard !sessions.isEmpty else { return nil }
        return SaverFeed(at: now, location: last?.location ?? Location.cantina.rawValue, sessions: sessions, events: [])
    }
}
