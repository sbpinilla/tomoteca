//
//  SessionStartButton.swift
//  tomoteca
//

import SwiftUI

/// The way into a reading session, wherever it is offered from.
///
/// Written once because starting a session is more than a button: it opens the duration sheet,
/// asks for the notification permission the first time, and starts the session only once the
/// sheet is fully gone. Two copies of that would be two chances to get the sequencing wrong.
///
/// With a session already running — this book's or another's — it reopens that one instead of
/// starting a second.
struct SessionStartButton: View {

    let book: Book

    @ObservedObject var sessionController: ActiveSessionController

    let notifications: any SessionNotificationScheduling

    @State private var isChoosingDuration = false
    /// Held between choosing a duration and the sheet finishing its dismissal.
    @State private var pendingMinutes: Int?

    var body: some View {
        TMButton(
            title: sessionController.hasActiveSession ? .sessionBannerResume : .sessionStart
        ) {
            if sessionController.hasActiveSession {
                sessionController.prepareViewModelIfNeeded()
                sessionController.isPresenting = true
            } else {
                isChoosingDuration = true
            }
        }
        // The session is started once the sheet is fully gone. Starting it from inside the
        // sheet's callback races the dismissal, and SwiftUI drops the second presentation: the
        // sheet closed and nothing came up behind it.
        .sheet(isPresented: $isChoosingDuration, onDismiss: startPendingSession) {
            SessionDurationSheet(book: book) { minutes in
                pendingMinutes = minutes
                isChoosingDuration = false
            }
            .presentationDetents([.height(320)])
        }
        .task(id: isChoosingDuration) {
            // Asked next to the feature that needs it, not at launch.
            if isChoosingDuration { await notifications.requestAuthorization() }
        }
    }

    /// The controller owns the session from here: it is presented at the root, so it outlives
    /// this screen and cannot be started twice.
    private func startPendingSession() {
        guard let minutes = pendingMinutes else { return }
        pendingMinutes = nil
        sessionController.start(book: book, minutes: minutes)
    }
}

#if DEBUG
struct SessionStartButton_Previews: PreviewProvider {
    static var previews: some View {
        SessionStartButton(
            book: .previewReading,
            sessionController: .preview,
            notifications: PreviewNotificationScheduler()
        )
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
