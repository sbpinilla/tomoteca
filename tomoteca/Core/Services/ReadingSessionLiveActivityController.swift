//
//  ReadingSessionLiveActivityController.swift
//  tomoteca
//

import ActivityKit
import Foundation

/// Requests, updates and ends the reading session's Live Activity.
///
/// Marked `@available` as a whole, so `ActiveSessionController` — which the app's iOS 16.0 floor
/// still has to compile and run without ActivityKit — only ever touches this behind its own
/// `#available` checks, holding it as `Any?` rather than this concrete type.
@available(iOS 16.2, *)
@MainActor
final class ReadingSessionLiveActivityController {

    private var activity: Activity<ReadingSessionActivityAttributes>?

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

    private func contentState(for stored: StoredSession) -> ReadingSessionActivityAttributes.ContentState {
        let moment = Date()

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
