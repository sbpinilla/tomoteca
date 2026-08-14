//
//  AppAppearance.swift
//  tomoteca
//

import SwiftUI
import UIKit

/// UIKit-level styling that SwiftUI cannot reach from a modifier.
///
/// Only the navigation bar for now: `navigationTitle` renders through UIKit, so the app's
/// rounded typeface has to be installed here rather than with `.font()`.
enum AppAppearance {

    static func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        appearance.largeTitleTextAttributes = [
            .font: roundedFont(for: .largeTitle, weight: .bold),
            .foregroundColor: UIColor(AppColor.textPrimary),
        ]
        appearance.titleTextAttributes = [
            .font: roundedFont(for: .headline, weight: .semibold),
            .foregroundColor: UIColor(AppColor.textPrimary),
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    /// Sets the window's interface style to match the chosen theme.
    ///
    /// This is Apple's own documented way to override light/dark app-wide at runtime — see
    /// "Overriding Dark Mode" (useyourloaf.com) — and it is what lets **system-presented** UI
    /// that `.preferredColorScheme` cannot reach (the photo picker, the share sheet) honor the
    /// chosen theme instead of following the phone.
    ///
    /// It does **not** fix the tab bar and back button lagging behind after a runtime change —
    /// see C12. That is a currently open SwiftUI/UIKit platform bug, reported against iOS 18
    /// through 26 with no fix from Apple as of this writing, and not something addressable from
    /// application code. Kept anyway for the benefit above.
    static func apply(_ colorScheme: ColorScheme?) {
        let style: UIUserInterfaceStyle
        switch colorScheme {
        case .light: style = .light
        case .dark: style = .dark
        default: style = .unspecified
        }

        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }

    /// SF Pro Rounded at the size the given text style resolves to, so Dynamic Type keeps
    /// working: `preferredFont` is already scaled, and size 0 preserves that scaling.
    private static func roundedFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: textStyle)
        let descriptor = (base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
