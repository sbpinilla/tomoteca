//
//  TMShelfChip.swift
//  tomoteca
//

import SwiftUI

/// A pill that picks one shelf out of several, with how many things are on it.
///
/// The selected one fills with its own color, faintly, and writes in it; the rest are quiet
/// text. No dot here — the whole chip is one status, so the color already says which, and the
/// dot in `TMStatusChip` exists to tell statuses apart *within* a row.
///
/// Takes a color rather than a status: the design system knows nothing about books.
struct TMShelfChip: View {

    let title: LocalizedStringResource
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                TMText(
                    title,
                    style: .footnote,
                    color: isSelected ? color : AppColor.textSecondary
                )

                TMText(
                    verbatim: count.formatted(),
                    style: .body,
                    color: isSelected ? color : AppColor.textPrimary
                )
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? color.opacity(Self.selectedFill) : AppColor.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isSelected ? color.opacity(Self.selectedBorder) : AppColor.borderSubtle,
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Faint enough that the label stays the loudest thing in the chip.
    private static let selectedFill = 0.15
    private static let selectedBorder = 0.4
}

#if DEBUG
struct TMShelfChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: Spacing.sm) {
            TMShelfChip(
                title: .statusShortWishlist,
                count: 3,
                color: AppColor.Status.wishlist,
                isSelected: false
            ) {}

            TMShelfChip(
                title: .statusShortOwned,
                count: 34,
                color: AppColor.Status.owned,
                isSelected: true
            ) {}

            TMShelfChip(
                title: .statusShortReading,
                count: 1,
                color: AppColor.Status.reading,
                isSelected: false
            ) {}
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
