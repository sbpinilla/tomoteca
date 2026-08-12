//
//  SessionNotificationScheduler.swift
//  tomoteca
//

import Foundation
import UserNotifications

/// Schedules the alert that fires when a reading session runs out.
///
/// Behind a protocol so the session logic can be tested without a real notification centre,
/// which cannot be driven from a unit test.
protocol SessionNotificationScheduling {

    /// Asks for permission. Called the first time a session starts, not at launch: permission
    /// requests make sense next to the feature that needs them.
    func requestAuthorization() async

    /// Schedules the end-of-session alert. Replaces any previously scheduled one.
    func scheduleSessionEnd(in seconds: TimeInterval, bookTitle: String)

    /// Drops the pending alert — the session was paused or finished early, so it would fire
    /// at a moment that no longer means anything.
    func cancelScheduledSessionEnd()
}

/// The real scheduler, on top of `UNUserNotificationCenter`.
struct SessionNotificationScheduler: SessionNotificationScheduling {

    private static let identifier = "session-ended"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func scheduleSessionEnd(in seconds: TimeInterval, bookTitle: String) {
        cancelScheduledSessionEnd()

        // A non-positive interval is not schedulable, and would mean the session is already
        // over — in which case the app is on screen and shows it directly.
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: .notificationSessionEndedTitle)
        content.body = String(localized: .notificationSessionEndedBody(bookTitle))
        content.sound = .default

        center.add(
            UNNotificationRequest(
                identifier: Self.identifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            )
        )
    }

    func cancelScheduledSessionEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }
}

#if DEBUG
/// Schedules nothing. Used by UI tests, and by previews, to keep the permission alert away.
struct NoOpNotificationScheduler: SessionNotificationScheduling {
    func requestAuthorization() async {}
    func scheduleSessionEnd(in seconds: TimeInterval, bookTitle: String) {}
    func cancelScheduledSessionEnd() {}
}
#endif
