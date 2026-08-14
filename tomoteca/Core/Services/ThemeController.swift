//
//  ThemeController.swift
//  tomoteca
//

import Combine
import Foundation

/// Holds the chosen appearance for the whole app.
///
/// In `Core/` rather than in the profile feature: the settings screen changes it, but the root
/// applies it, and something two parts share cannot belong to either of them.
@MainActor
final class ThemeController: ObservableObject {

    static let storageKey = "appTheme"

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Self.storageKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Absent means never chosen, which is the default rather than a stored `system`. Both
        // land in the same place, so nothing has to distinguish them afterwards.
        let stored = defaults.object(forKey: Self.storageKey) as? Int
        theme = stored.flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}

#if DEBUG
extension ThemeController {

    /// For previews, on a throwaway suite: a preview must not overwrite the preference of
    /// whoever is looking at it.
    static var preview: ThemeController {
        ThemeController(defaults: UserDefaults(suiteName: "preview.theme") ?? .standard)
    }
}
#endif
