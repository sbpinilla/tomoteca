//
//  TMEmptyState.swift
//  tomoteca
//

import SwiftUI

/// What a screen shows when it has nothing to show: an icon, a title and one line explaining
/// how to fix it.
///
/// Stands in for `ContentUnavailableView`, which needs iOS 17.
struct TMEmptyState: View {

    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(AppFont.largeTitle)
                .foregroundColor(AppColor.textSecondary)
                .padding(.bottom, Spacing.xs)

            TMText(title, style: .headline)

            TMText(message, style: .footnote, color: AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct TMEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        TMEmptyState(
            systemImage: "books.vertical",
            title: .trunkEmptyTitle,
            message: .trunkEmptyMessage
        )
        .background(AppColor.background)
    }
}
#endif
