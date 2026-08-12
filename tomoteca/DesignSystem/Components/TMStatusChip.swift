//
//  TMStatusChip.swift
//  tomoteca
//

import SwiftUI

/// A status marker: a colored dot followed by the label in the same color.
///
/// No fill and no border — that is what the approved design does, and it keeps the status from
/// shouting over the book title next to it.
///
/// Takes a color rather than a status: the design system knows nothing about books.
struct TMStatusChip: View {

    let title: LocalizedStringResource
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            TMText(title, style: .footnote, color: color)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct TMStatusChip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TMStatusChip(title: .statusWishlist, color: AppColor.Status.wishlist)
            TMStatusChip(title: .statusOwned, color: AppColor.Status.owned)
            TMStatusChip(title: .statusReading, color: AppColor.Status.reading)
            TMStatusChip(title: .statusFinished, color: AppColor.Status.finished)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
