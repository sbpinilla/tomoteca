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
    }

    let bookRepository: BookRepository

    @State private var selection: Tab = Self.initialTab

    var body: some View {
        TabView(selection: $selection) {
            InProgressView()
                .tag(Tab.inProgress)
                .tabItem {
                    Label {
                        Text(.tabInProgress)
                    } icon: {
                        Image(systemName: "book")
                    }
                }

            TrackingView()
                .tag(Tab.tracking)
                .tabItem {
                    Label {
                        Text(.tabTracking)
                    } icon: {
                        Image(systemName: "chart.bar")
                    }
                }

            TrunkView(repository: bookRepository)
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
        RootTabView(bookRepository: PreviewBookRepository.populated)
            .preferredColorScheme(.light)
            .previewDisplayName("Light")

        RootTabView(bookRepository: PreviewBookRepository.populated)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
    }
}
#endif
