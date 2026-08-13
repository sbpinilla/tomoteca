//
//  RootTabView.swift
//  tomoteca
//

import Combine
import SwiftUI

/// The app's root navigation: three tabs, each owning its own navigation stack so that
/// moving around inside one never disturbs the others.
struct RootTabView: View {

    enum Tab: String {
        case inProgress
        case tracking
        case trunk
    }

    let bookRepository: BookRepository
    let sessionRepository: ReadingSessionRepository
    let notifications: any SessionNotificationScheduling

    @ObservedObject var sessionController: ActiveSessionController

    @State private var selection: Tab = Self.initialTab
    /// Only drives the banner's countdown; the time itself comes from the clock.
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

            TrackingView(repository: sessionRepository)
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
        }
        .tint(AppColor.brandAccent)
        .onReceive(tick) { _ in
            // Nudges the banner's remaining time, and notices when it runs out.
            sessionController.objectWillChange.send()
        }
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
            )
        )
        .previewDisplayName("Light")
    }
}
#endif
