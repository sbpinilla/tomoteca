//
//  AppThemeStyle.swift
//  tomoteca
//

import SwiftUI

/// Turns an `AppTheme` into what the screen needs to apply it.
///
/// Same split as `BookStatusStyle`: the domain does not import SwiftUI, and the design system
/// does not know what a theme preference is.
extension AppTheme {

    var title: LocalizedStringResource {
        switch self {
        case .system: return .themeSystem
        case .light: return .themeLight
        case .dark: return .themeDark
        }
    }

    /// The scheme to force, or `nil` to leave the phone in charge.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
