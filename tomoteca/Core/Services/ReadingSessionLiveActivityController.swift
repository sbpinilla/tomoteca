//
//  ReadingSessionLiveActivityController.swift
//  tomoteca
//

import ActivityKit
import Foundation

/// What `ActiveSessionController` needs from whatever manages the reading session's Live
/// Activity.
///
/// A protocol, so tests can substitute a fake instead of touching real ActivityKit — which
/// needs a capable device and is not something a unit test can drive or observe. Carries no
/// ActivityKit types, so unlike the concrete controller it needs no `@available` of its own.
@MainActor
protocol ReadingSessionLiveActivityUpdating {
    func start(book: Book, stored: StoredSession)
    func attach(stored: StoredSession)
    func update(stored: StoredSession)
    func end()
}

/// Requests, updates and ends the reading session's Live Activity.
///
/// Marked `@available` as a whole, so `ActiveSessionController` — which the app's iOS 16.0 floor
/// still has to compile and run without ActivityKit — only ever touches this behind its own
/// `#available` checks, holding it as `any ReadingSessionLiveActivityUpdating` rather than this
/// concrete type.
@available(iOS 16.2, *)
@MainActor
final class ReadingSessionLiveActivityController: ReadingSessionLiveActivityUpdating {

    private var activity: Activity<ReadingSessionActivityAttributes>?
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    /// Starts the activity, or does nothing if one could not be requested — Live Activities can
    /// be turned off in Settings, and a session works perfectly well without one; it is a nice
    /// extra, not something worth failing the session over.
    func start(book: Book, stored: StoredSession) {
        end()

        let attributes = ReadingSessionActivityAttributes(
            bookTitle: book.title,
            plannedMinutes: stored.plannedMinutes
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState(for: stored), staleDate: nil)
            )
        } catch {
            activity = nil
        }
    }

    /// Reconnects to whatever Live Activity is already running for this session, without
    /// starting a new one. Needed after the app is killed and relaunched: the activity survives
    /// on the system side regardless, but this process's own reference to it does not — and
    /// without one, a later pause or resume would have nothing to push its update through.
    func attach(stored: StoredSession) {
        activity = Activity<ReadingSessionActivityAttributes>.activities.first
    }

    /// Pushed on a phase change — pausing, resuming — not on every tick: a running session with
    /// a plan counts itself down on the Island without any help from here.
    func update(stored: StoredSession) {
        guard let activity else { return }
        let content = ActivityContent(state: contentState(for: stored), staleDate: nil)
        Task { await activity.update(content) }
    }

    func end() {
        guard let activity else { return }
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
        self.activity = nil
    }

    /// What the activity should show for `stored`, right now.
    ///
    /// Not private: it is the one piece of this type that is pure — a `StoredSession` in, a
    /// `ContentState` out — and worth a test on its own, without needing a real `Activity` to
    /// exist for a unit test to drive.
    func contentState(for stored: StoredSession) -> ReadingSessionActivityAttributes.ContentState {
        let moment = now()

        guard !stored.isFree, !stored.isPaused else {
            let shown = stored.isFree ? stored.elapsed(at: moment) : stored.remaining(at: moment)
            return ReadingSessionActivityAttributes.ContentState(
                endDate: nil,
                frozenDisplay: Self.format(shown),
                isPaused: stored.isPaused,
                isFree: stored.isFree
            )
        }

        // Running, with a plan: handed an end date instead of a number, so `Text(timerInterval:)`
        // can animate the countdown on the system's own clock, without this process staying awake.
        let endDate = moment.addingTimeInterval(stored.remaining(at: moment))
        return ReadingSessionActivityAttributes.ContentState(
            endDate: endDate,
            frozenDisplay: Self.format(stored.remaining(at: moment)),
            isPaused: false,
            isFree: false
        )
    }

    private static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
