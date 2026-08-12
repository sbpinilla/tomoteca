//
//  RootTabView.swift
//  tomoteca
//

import SwiftUI

/// The app's root navigation: three tabs, each owning its own navigation stack so that
/// moving around inside one never disturbs the others.
struct RootTabView: View {

    var body: some View {
        TabView {
            InProgressView()
                .tabItem {
                    Label {
                        Text(.tabInProgress)
                    } icon: {
                        Image(systemName: "book")
                    }
                }

            TrackingView()
                .tabItem {
                    Label {
                        Text(.tabTracking)
                    } icon: {
                        Image(systemName: "chart.bar")
                    }
                }

            TrunkView()
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
}

#if DEBUG
struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light")

        RootTabView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
    }
}
#endif
