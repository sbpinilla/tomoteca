//
//  TMCard.swift
//  tomoteca
//

import SwiftUI

/// The raised, rounded container the whole app is built out of: list groups, form sections,
/// stat tiles. Holds the surface color, the radius and the hairline border in one place.
struct TMCard<Content: View>: View {

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .stroke(AppColor.borderSubtle, lineWidth: 1)
            )
    }
}

#if DEBUG
struct TMCard_Previews: PreviewProvider {
    static var previews: some View {
        TMCard {
            TMText(verbatim: "Sapiens", style: .headline)
                .padding(Spacing.md)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
