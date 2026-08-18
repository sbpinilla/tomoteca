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

    /// `.compact` is an inline aside — a row's worth of space inside a list. `.hero` is the
    /// whole screen's moment, sized up to fill it: onboarding, not "nothing here yet".
    enum Style {
        case compact
        case hero
    }

    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    var style: Style = .compact

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(AppFont.largeTitle)
                .imageScale(style == .hero ? .large : .medium)
                .foregroundColor(AppColor.textSecondary)
                .padding(.bottom, Spacing.xs)

            TMText(title, style: style == .hero ? .largeTitle : .headline)
                .multilineTextAlignment(.center)

            TMText(
                message,
                style: style == .hero ? .body : .footnote,
                color: AppColor.textSecondary
            )
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
        .previewDisplayName("Compact")

        TMEmptyState(
            systemImage: "books.vertical",
            title: .trunkEmptyTitle,
            message: .trunkEmptyMessage,
            style: .hero
        )
        .background(AppColor.background)
        .previewDisplayName("Hero")
    }
}
#endif
