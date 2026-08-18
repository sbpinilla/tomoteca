//
//  RootView.swift
//  tomoteca
//

import SwiftUI

/// What the window shows: the welcome screens until they are seen once, the app after that.
///
/// A view of its own rather than inline in `tomotecaApp.body`, so the switch reacts to
/// `OnboardingController` through the ordinary `@ObservedObject` mechanism — an `App` conformer
/// has no `body` re-evaluation tied to a plain `let`.
struct RootView: View {

    let bookRepository: BookRepository
    let sessionRepository: ReadingSessionRepository
    let notifications: any SessionNotificationScheduling
    let sessionController: ActiveSessionController
    let themeController: ThemeController

    @ObservedObject var onboardingController: OnboardingController

    var body: some View {
        if onboardingController.hasCompletedOnboarding {
            RootTabView(
                bookRepository: bookRepository,
                sessionRepository: sessionRepository,
                notifications: notifications,
                sessionController: sessionController,
                themeController: themeController
            )
        } else {
            OnboardingView { onboardingController.complete() }
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(
            bookRepository: PreviewBookRepository.populated,
            sessionRepository: PreviewReadingSessionRepository(),
            notifications: PreviewNotificationScheduler(),
            sessionController: ActiveSessionController(
                bookRepository: PreviewBookRepository.populated,
                sessionRepository: PreviewReadingSessionRepository(),
                notifications: PreviewNotificationScheduler(),
                store: InMemoryActiveSessionStore()
            ),
            themeController: ThemeController.preview,
            onboardingController: OnboardingController.preview
        )
        .previewDisplayName("Welcome")
    }
}
#endif
