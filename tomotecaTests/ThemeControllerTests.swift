//
//  ThemeControllerTests.swift
//  tomotecaTests
//

import Foundation
import SwiftUI
import Testing
@testable import tomoteca

@MainActor
struct ThemeControllerTests {

    /// A defaults suite of its own per test, so a chosen theme never leaks into the next.
    private func makeDefaults() -> UserDefaults {
        let name = "tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("With nothing chosen the app follows the phone")
    func defaultsToTheSystem() {
        let controller = ThemeController(defaults: makeDefaults())

        #expect(controller.theme == .system)
        #expect(controller.theme.colorScheme == nil, "Nothing forced")
    }

    @Test("Choosing a theme writes it down")
    func choosingWritesItDown() {
        let defaults = makeDefaults()
        let controller = ThemeController(defaults: defaults)

        controller.theme = .dark

        #expect(defaults.object(forKey: ThemeController.storageKey) as? Int == AppTheme.dark.rawValue)
    }

    @Test("The choice survives a relaunch")
    func choiceOutlivesTheApp() {
        let defaults = makeDefaults()
        ThemeController(defaults: defaults).theme = .light

        // A second controller over the same store is what the next launch does.
        #expect(ThemeController(defaults: defaults).theme == .light)
    }

    @Test("Going back to automatic is stored too, not just left blank")
    func returningToSystemIsStored() {
        let defaults = makeDefaults()
        let controller = ThemeController(defaults: defaults)

        controller.theme = .dark
        controller.theme = .system

        #expect(ThemeController(defaults: defaults).theme == .system)
    }

    @Test("A stored value that means nothing falls back to the phone")
    func rubbishFallsBackToTheSystem() {
        let defaults = makeDefaults()
        defaults.set(99, forKey: ThemeController.storageKey)

        #expect(ThemeController(defaults: defaults).theme == .system)
    }

    @Test("Reading the preference does not write it, so the default stays undecided")
    func readingDoesNotWrite() {
        let defaults = makeDefaults()
        _ = ThemeController(defaults: defaults)

        #expect(
            defaults.object(forKey: ThemeController.storageKey) == nil,
            "Never chosen and stored as system are the same thing, and must stay that way"
        )
    }

    @Test("Each theme forces what it says", arguments: [
        (AppTheme.system, ColorScheme?.none),
        (AppTheme.light, .light),
        (AppTheme.dark, .dark),
    ])
    func mapsToTheColorScheme(_ theme: AppTheme, _ expected: ColorScheme?) {
        #expect(theme.colorScheme == expected)
    }
}
