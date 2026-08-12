//
//  TrackingView.swift
//  tomoteca
//

import SwiftUI

/// Reading time per day over a date range. Placeholder until Hito 7.
struct TrackingView: View {

    var body: some View {
        NavigationStack {
            AppColor.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabTracking))
        }
    }
}

#if DEBUG
struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
#endif
