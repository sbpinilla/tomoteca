//
//  OnboardingControllerTests.swift
//  tomotecaTests
//

import Foundation
import Testing
@testable import tomoteca

@MainActor
struct OnboardingControllerTests {

    /// A defaults suite of its own per test, so one test finishing onboarding never leaks into
    /// the next.
    private func makeDefaults() -> UserDefaults {
        let name = "tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("With nothing stored, onboarding has not been seen")
    func startsUnseen() {
        let controller = OnboardingController(defaults: makeDefaults())
        #expect(controller.hasCompletedOnboarding == false)
    }

    @Test("Completing it writes it down")
    func completingWritesItDown() {
        let defaults = makeDefaults()
        let controller = OnboardingController(defaults: defaults)

        controller.complete()

        #expect(controller.hasCompletedOnboarding)
        #expect(defaults.bool(forKey: OnboardingController.storageKey))
    }

    @Test("Completed is what survives a relaunch")
    func completionOutlivesTheApp() {
        let defaults = makeDefaults()
        OnboardingController(defaults: defaults).complete()

        // A second controller over the same store is what the next launch does.
        #expect(OnboardingController(defaults: defaults).hasCompletedOnboarding)
    }
}
