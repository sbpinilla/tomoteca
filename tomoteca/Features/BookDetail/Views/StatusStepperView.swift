//
//  StatusStepperView.swift
//  tomoteca
//

import SwiftUI

/// Where the book sits in the life cycle: one segment per status, filled up to the current one.
///
/// Informative only — nothing here is tappable. The single way forward is the button below it,
/// because offering all four would invite trying to step back, which the cycle forbids.
struct StatusStepperView: View {

    let current: BookStatus

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            ForEach(BookStatus.allCases) { status in
                VStack(spacing: Spacing.xs) {
                    Capsule()
                        .fill(color(for: status))
                        .frame(height: Spacing.sm)

                    TMText(
                        status.shortTitle,
                        style: .footnote,
                        color: status == current ? AppColor.textPrimary : AppColor.textSecondary
                    )
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func color(for status: BookStatus) -> Color {
        if status == current {
            return AppColor.brandAccent
        }
        return status.rawValue < current.rawValue ? AppColor.brandPrimary : AppColor.track
    }
}

#if DEBUG
struct StatusStepperView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            StatusStepperView(current: .wishlist)
            StatusStepperView(current: .reading)
            StatusStepperView(current: .finished)
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
