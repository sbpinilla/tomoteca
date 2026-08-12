//
//  TMButton.swift
//  tomoteca
//

import SwiftUI

/// The app's action button.
///
/// The primary variant labels itself in `background` rather than a fixed white: on the cream of
/// light mode that reads as white, and on the warm black of dark mode it flips to dark, which
/// is what keeps it legible on top of the coral fill in both.
struct TMButton: View {

    enum Style {
        case primary
        case secondary
        /// Outlined in the accent color: a secondary action that still carries weight, like
        /// ending a session in progress.
        case secondaryAccent
    }

    let title: LocalizedStringResource
    var style: Style = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TMText(title, style: .body, color: foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(fill)
                .clipShape(Capsule())
                .overlay(border)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return AppColor.background
        case .secondary: return AppColor.textPrimary
        case .secondaryAccent: return AppColor.brandAccent
        }
    }

    private var fill: Color {
        switch style {
        case .primary: return AppColor.brandAccent
        case .secondary, .secondaryAccent: return AppColor.surface
        }
    }

    @ViewBuilder
    private var border: some View {
        switch style {
        case .primary:
            EmptyView()
        case .secondary:
            Capsule().stroke(AppColor.borderSubtle, lineWidth: 1)
        case .secondaryAccent:
            Capsule().stroke(AppColor.brandAccent, lineWidth: 1)
        }
    }
}

#if DEBUG
struct TMButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.md) {
            TMButton(title: .statusChangeActionFinished) {}
            TMButton(title: .bookFormCancel, style: .secondary) {}
        }
        .padding(Spacing.md)
        .background(AppColor.background)
    }
}
#endif
