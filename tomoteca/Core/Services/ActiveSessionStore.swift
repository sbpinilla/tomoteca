//
//  ActiveSessionStore.swift
//  tomoteca
//

import Foundation

/// Keeps the session in progress across launches.
protocol ActiveSessionStoring {
    func load() -> StoredSession?
    func save(_ session: StoredSession)
    func clear()
}

/// Stores it in `UserDefaults`.
///
/// Not Core Data on purpose: this is one short-lived record that disappears the moment the
/// session closes. Putting it in the store would mean telling real sessions apart from
/// half-finished ones on every read of the history.
struct ActiveSessionStore: ActiveSessionStoring {

    private static let key = "activeSession"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> StoredSession? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(StoredSession.self, from: data)
    }

    func save(_ session: StoredSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}

#if DEBUG
/// In-memory store, for tests and for UI runs that must start with no session pending.
final class InMemoryActiveSessionStore: ActiveSessionStoring {

    private var session: StoredSession?

    init(session: StoredSession? = nil) {
        self.session = session
    }

    func load() -> StoredSession? { session }
    func save(_ session: StoredSession) { self.session = session }
    func clear() { session = nil }
}
#endif
