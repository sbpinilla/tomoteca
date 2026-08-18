//
//  ReadingSessionActivityAttributes.swift
//  tomoteca
//

import ActivityKit
import Foundation

/// What a reading session's Live Activity shows on the Dynamic Island and the Lock Screen.
///
/// Shared as-is between the app and the widget extension — the same file compiled into both
/// targets, not a framework. Requires iOS 16.2, two points above the app's own floor of 16.0, so
/// every call site that touches this type is behind an `if #available(iOS 16.2, *)` rather than
/// the app raising its floor for one feature.
@available(iOS 16.2, *)
struct ReadingSessionActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// When the planned time runs out, for a session with a plan. `Text(timerInterval:)`
        /// animates the countdown from this on its own — nothing has to keep pushing updates
        /// for a session that is simply running.
        ///
        /// `nil` for a free session, which has no plan to count down to, and `nil` while paused,
        /// since a paused session is not counting down to anything either at that moment.
        var endDate: Date?

        /// What to show instead of a live countdown: while paused (any session), or at all times
        /// for a free session, whose number only ever moves because the app said so.
        var frozenDisplay: String

        var isPaused: Bool
        var isFree: Bool
    }

    /// Fixed for the life of the activity — the book being read, and the plan it started with.
    let bookTitle: String
    let plannedMinutes: Int
}

/// The one link a Stop button on the activity can mean: open the app straight to "what page are
/// you on?" — exactly what tapping "Finish" already does from inside the session screen.
///
/// Shared between the app, which listens for it, and the widget extension, which is the only
/// place that ever constructs it.
enum SessionActivityLink {
    static let stop = URL(string: "tomoteca://sesion/terminar")!
}
