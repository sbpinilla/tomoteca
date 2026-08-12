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

    /// SF Pro Rounded at the size the given text style resolves to, so Dynamic Type keeps
    /// working: `preferredFont` is already scaled, and size 0 preserves that scaling.
    private static func roundedFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: textStyle)
        let descriptor = (base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor)
            .addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])
        return UIFont(descriptor: descriptor, size: 0)
    }
}
