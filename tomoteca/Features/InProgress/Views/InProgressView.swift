//
//  InProgressView.swift
//  tomoteca
//

import SwiftUI

/// Books currently being read, and the entry point to a reading session.
/// Placeholder until Hito 6.
struct InProgressView: View {

    var body: some View {
        NavigationStack {
            AppColor.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabInProgress))
        }
    }
}

#if DEBUG
struct InProgressView_Previews: PreviewProvider {
    static var previews: some View {
        InProgressView()
    }
}
#endif
