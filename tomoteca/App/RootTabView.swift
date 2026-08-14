//
//  RootTabView.swift
//  tomoteca
//

import SwiftUI

/// The app's root navigation: three tabs, each owning its own navigation stack so that
/// moving around inside one never disturbs the others.
struct RootTabView: View {

    enum Tab: String {
        case inProgress
        case tracking
        case trunk
        case profile
    }

    let bookRepository: BookRepository
    let sessionRepository: ReadingSessionRepository
    let notifications: any SessionNotificationScheduling

    @ObservedObject var sessionController: ActiveSessionController
    @ObservedObject var themeController: ThemeController

    @State private var selection: Tab = Self.initialTab

    var body: some View {
        TabView(selection: $selection) {
            InProgressView(
                bookRepository: bookRepository,
                notifications: notifications,
                sessionController: sessionController
            )
                .activeSessionBanner(sessionController)
                .tag(Tab.inProgress)
                .tabItem {
                    Label {
                        Text(.tabInProgress)
                    } icon: {
                        Image(systemName: "book")
                    }
                }

            TrackingView(repository: sessionRepository, bookRepository: bookRepository)
                .activeSessionBanner(sessionController)
                .tag(Tab.tracking)
                .tabItem {
                    Label {
                        Text(.tabTracking)
                    } icon: {
                        Image(systemName: "chart.bar")
                    }
                }

            TrunkView(
                repository: bookRepository,
                notifications: notifications,
                sessionController: sessionController
            )
                .activeSessionBanner(sessionController)
                .tag(Tab.trunk)
                .tabItem {
                    Label {
                        Text(.tabTrunk)
                    } icon: {
                        Image(systemName: "archivebox")
                    }
                }

            ProfileView(repository: bookRepository, themeController: themeController)
                .activeSessionBanner(sessionController)
                .tag(Tab.profile)
                .tabItem {
                    Label {
                        Text(.tabProfile)
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                }
        }
        .tint(AppColor.brandAccent)
        // Applied here, on the whole tab bar, so it reaches the sheets and the full-screen
        // session too: they are presented from inside and inherit this. Applied screen by screen
        // it would miss one, and the one it would miss is the session.
        .preferredColorScheme(themeController.theme.colorScheme)
        .fullScreenCover(isPresented: $sessionController.isPresenting) {
            if let viewModel = sessionController.sessionViewModel {
                ActiveSessionView(viewModel: viewModel) {
                    sessionController.finish()
                }
            }
        }
    }

    /// Always the first tab, except when a debug run asks for another one with
    /// `-startTab trunk`. Used to capture a given screen without tapping through the app.
    private static var initialTab: Tab {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "startTab"), let tab = Tab(rawValue: raw) {
            return tab
        }
        #endif
        return .inProgress
    }
}

#if DEBUG
struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView(
            bookRepository: PreviewBookRepository.populated,
            sessionRepository: PreviewReadingSessionRepository(),
            notifications: PreviewNotificationScheduler(),
            sessionController: ActiveSessionController(
                bookRepository: PreviewBookRepository.populated,
                sessionRepository: PreviewReadingSessionRepository(),
                notifications: PreviewNotificationScheduler(),
                store: InMemoryActiveSessionStore()
            ),
            themeController: ThemeController.preview
        )
        .previewDisplayName("Light")
    }
}
#endif
