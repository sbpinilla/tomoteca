//
//  TrunkView.swift
//  tomoteca
//

import SwiftUI

/// The full book registry: list, search, filter and entry point to adding a book.
/// Placeholder until Hito 1.
struct TrunkView: View {

    var body: some View {
        NavigationStack {
            AppColor.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabTrunk))
        }
    }
}

#if DEBUG
struct TrunkView_Previews: PreviewProvider {
    static var previews: some View {
        TrunkView()
    }
}
#endif
