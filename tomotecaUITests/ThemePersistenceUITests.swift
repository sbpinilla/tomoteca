//
//  ThemePersistenceUITests.swift
//  tomotecaUITests
//

import XCTest

/// That the chosen theme is still chosen after the app is killed and opened again.
///
/// Runs **without** `-useInMemoryStore`, unlike every other UI suite: that flag wipes the stored
/// theme at launch precisely so tests do not inherit each other's, which is the opposite of what
/// is being proven here.
final class ThemePersistenceUITests: XCTestCase {

    private var app: XCUIApplication!

    private let launchArguments = [
        "-seedSampleData",
        "-disableNotifications",
        "-startTab", "profile",
        "-AppleLanguages", "(en)",
    ]

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()
    }

    override func tearDown() {
        // Leave the simulator following the phone again, for the next run and for whoever is
        // using it by hand.
        app.launchArguments = launchArguments
        app.launch()
        openSettings()
        if app.buttons["Automatic"].waitForExistence(timeout: 5) {
            app.buttons["Automatic"].tap()
        }
    }

    func testTheChosenThemeSurvivesTheAppBeingKilled() {
        openSettings()

        let dark = app.buttons["Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5))
        dark.tap()
        XCTAssertTrue(dark.isSelected)

        app.terminate()
        app.launch()

        openSettings()

        XCTAssertTrue(app.buttons["Dark"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Dark"].isSelected, "The app opened having forgotten the theme")
        XCTAssertFalse(app.buttons["Automatic"].isSelected)
    }

    private func openSettings() {
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        app.staticTexts["Settings"].tap()
    }
}
