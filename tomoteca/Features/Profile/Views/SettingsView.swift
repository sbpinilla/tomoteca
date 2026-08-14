//
//  SettingsView.swift
//  tomoteca
//

import SwiftUI

/// How the app behaves, as opposed to what it holds.
///
/// One setting today. It is a screen of its own rather than a row in the profile because the
/// next one will land here too, and moving a setting after people have found it is worse.
struct SettingsView: View {

    @ObservedObject var themeController: ThemeController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                TMText(.settingsAppearance, style: .footnote, color: AppColor.textSecondary)

                TMSegmentedPicker(
                    options: AppTheme.allCases,
                    title: \.title,
                    selection: $themeController.theme
                )
                .accessibilityIdentifier("themePicker")

                TMText(.settingsAppearanceHint, style: .footnote, color: AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
        }
        .background(AppColor.background)
        .navigationTitle(Text(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(themeController: ThemeController.preview)
        }
    }
}
#endif
