//
//  ActiveSessionView.swift
//  tomoteca
//

import Combine
import SwiftUI

/// The running session: countdown, pause and finish.
struct ActiveSessionView: View {

    @ObservedObject var viewModel: ReadingSessionViewModel
    @Environment(\.scenePhase) private var scenePhase

    let onFinished: () -> Void

    /// Only drives the redraw. The time itself always comes from the clock, so a tick that
    /// never arrives — the app was in the background — costs nothing.
    ///
    /// Held in `@State` so it is created once. Built as a plain property it would be a different
    /// publisher on every update of this view, `onReceive` would resubscribe to it every time,
    /// and a one-second timer that restarts before it fires never fires at all.
    @State private var tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            TMText(.sessionActiveTitle, style: .title)

            VStack(spacing: Spacing.md) {
                TMProgressRing(value: viewModel.progress) {
                    VStack(spacing: Spacing.xs) {
                        TMText(verbatim: formattedRemaining, style: .largeTitle)
                            .accessibilityIdentifier("remainingTime")
                        TMText(.sessionRemaining, style: .footnote, color: AppColor.textSecondary)
                    }
                }
                .frame(width: 240, height: 240)

                TMText(verbatim: viewModel.book.title, style: .body, color: AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: Spacing.md) {
                TMButton(
                    title: viewModel.phase == .paused ? .sessionResume : .sessionPause,
                    style: .secondary
                ) {
                    viewModel.phase == .paused ? viewModel.resume() : viewModel.pause()
                }

                TMButton(title: .sessionFinish, style: .secondaryAccent) {
                    viewModel.finishEarly()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(AppColor.background)
        .onReceive(tick) { _ in viewModel.refresh() }
        .onChange(of: scenePhase) { phase in
            // Coming back from the background: re-read the clock, which is where the real
            // elapsed time has been all along.
            if phase == .active { viewModel.refresh() }
        }
        .sheet(isPresented: .constant(viewModel.phase == .askingPage)) {
            FinalPageSheet(viewModel: viewModel, onSaved: onFinished)
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }

    /// Remaining time as mm:ss.
    private var formattedRemaining: String {
        let total = Int(viewModel.remaining.rounded(.up))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#if DEBUG
struct ActiveSessionView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveSessionView(
            viewModel: ReadingSessionViewModel(
                book: .previewReading,
                stored: StoredSession(
                    bookID: Book.previewReading.id,
                    plannedMinutes: 15,
                    startedAt: Date(),
                    accumulated: 0,
                    segmentStartedAt: Date()
                ),
                repository: PreviewBookRepository.populated,
                sessionRepository: PreviewReadingSessionRepository(),
                notifications: PreviewNotificationScheduler(),
                store: InMemoryActiveSessionStore()
            ),
            onFinished: {}
        )
    }
}

/// Does nothing, so a preview never asks for notification permission.
struct PreviewNotificationScheduler: SessionNotificationScheduling {
    func requestAuthorization() async {}
    func scheduleSessionEnd(in seconds: TimeInterval, bookTitle: String) {}
    func cancelScheduledSessionEnd() {}
}
#endif
