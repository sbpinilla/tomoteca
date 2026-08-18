//
//  OnboardingController.swift
//  tomoteca
//

import Combine
import Foundation

/// Whether the welcome screens have already been shown.
///
/// Same shape as `ThemeController`: a minimal, injectable wrapper over one `UserDefaults` key.
/// Skipping the welcome screens and finishing them do the same thing — both are "seen", and
/// neither is offered again.
@MainActor
final class OnboardingController: ObservableObject {

    static let storageKey = "hasCompletedOnboarding"

    @Published private(set) var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Self.storageKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: Self.storageKey)
    }

    func complete() {
        hasCompletedOnboarding = true
    }
}

#if DEBUG
extension OnboardingController {

    /// For previews, on a throwaway suite: a preview must not mark onboarding as seen for
    /// whoever is looking at it.
    static var preview: OnboardingController {
        OnboardingController(defaults: UserDefaults(suiteName: "preview.onboarding") ?? .standard)
    }
}
#endif
