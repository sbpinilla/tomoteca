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
    /// What was asked for: 10, 15 or 30 minutes. `0` means a free session — no plan, counting up
    /// instead of down until the reader says stop.
    let plannedMinutes: Int
    let startedAt: Date
    /// Seconds banked from stretches already finished.
    var accumulated: TimeInterval
    /// When the current stretch began, or `nil` while paused.
    var segmentStartedAt: Date?
    /// When the app last left the foreground while this session kept running, or `nil` when it
    /// is in the foreground (or paused). Only ever set for a free session: a planned one already
    /// limits itself at `isExpired`, so it needs no marker to know something was left running.
    var backgroundedAt: Date? = nil

    var plannedDuration: TimeInterval { TimeInterval(plannedMinutes * 60) }

    /// No plan to run out, only a reader who decides when to stop.
    var isFree: Bool { plannedMinutes == 0 }

    var isPaused: Bool { segmentStartedAt == nil }

    func elapsed(at now: Date) -> TimeInterval {
        guard let segmentStartedAt else { return accumulated }
        return accumulated + now.timeIntervalSince(segmentStartedAt)
    }

    /// Time left before the planned duration runs out. Always `0` for a free session — there is
    /// nothing to run out of, so nothing here is meant to be shown; read `elapsed` instead.
    func remaining(at now: Date) -> TimeInterval {
        guard !isFree else { return 0 }
        return max(0, plannedDuration - elapsed(at: now))
    }

    /// The planned time ran out — while the app was closed, most likely. A free session never
    /// expires on its own: it has no planned time to run out of, and it ends only when the
    /// reader says so.
    func isExpired(at now: Date) -> Bool {
        guard !isFree else { return false }
        return remaining(at: now) == 0
    }

    /// Ran out so long ago that closing it properly no longer makes sense.
    func isStale(at now: Date) -> Bool {
        guard !isPaused else { return false }
        return elapsed(at: now) > plannedDuration + Self.staleAfter
    }
}
