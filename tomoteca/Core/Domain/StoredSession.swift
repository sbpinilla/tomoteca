//
//  StoredSession.swift
//  tomoteca
//

import Foundation

/// A reading session that has not finished yet, in a form that outlives the app being killed.
///
/// Everything here is a fact, not a countdown: when it started, how much time is banked, and
/// since when the current stretch has been running. The remaining time is derived from those,
/// which is why a session survives being closed — nothing had to keep ticking.
struct StoredSession: Codable, Equatable, Sendable {

    /// How long after its planned end a session is still worth asking about.
    ///
    /// Past that, the answer to "what page did you reach?" is a guess, and the banner would
    /// otherwise sit there for good.
    static let staleAfter: TimeInterval = 24 * 60 * 60

    let bookID: UUID
    let plannedMinutes: Int
    let startedAt: Date
    /// Seconds banked from stretches already finished.
    var accumulated: TimeInterval
    /// When the current stretch began, or `nil` while paused.
    var segmentStartedAt: Date?

    var plannedDuration: TimeInterval { TimeInterval(plannedMinutes * 60) }

    var isPaused: Bool { segmentStartedAt == nil }

    func elapsed(at now: Date) -> TimeInterval {
        guard let segmentStartedAt else { return accumulated }
        return accumulated + now.timeIntervalSince(segmentStartedAt)
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, plannedDuration - elapsed(at: now))
    }

    /// The planned time ran out — while the app was closed, most likely.
    func isExpired(at now: Date) -> Bool {
        remaining(at: now) == 0
    }

    /// Ran out so long ago that closing it properly no longer makes sense.
    func isStale(at now: Date) -> Bool {
        guard !isPaused else { return false }
        return elapsed(at: now) > plannedDuration + Self.staleAfter
    }
}
