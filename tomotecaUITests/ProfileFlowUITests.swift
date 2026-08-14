//
//  ProfileFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// Covers reaching the archive screen. The file picker and the share sheet belong to the system
/// and are not driven from here — what this checks is that the tab and the row lead to them.
final class ProfileFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-disableNotifications",
            "-startTab", "profile",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testProfileOpensTheArchiveScreen() {
        XCTAssertTrue(app.staticTexts["Books"].waitForExistence(timeout: 5))
        app.staticTexts["Books"].tap()

        XCTAssertTrue(app.buttons["Export books"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Import books"].exists)

        // The count comes from the seeded library, and the sentence warns what is left out.
        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS 'Covers and reading sessions are not included'")
            ).firstMatch.exists
        )

        attach(app.screenshot(), named: "archive")
    }

    func testSettingsOffersTheThemeWithAutomaticChosen() {
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 5))
        app.staticTexts["Settings"].tap()

        XCTAssertTrue(app.buttons["Automatic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Light"].exists)
        XCTAssertTrue(app.buttons["Dark"].exists)

        // Following the phone is what the app did before there was a choice, and stays the
        // starting point.
        XCTAssertTrue(app.buttons["Automatic"].isSelected)
        XCTAssertFalse(app.buttons["Dark"].isSelected)

        attach(app.screenshot(), named: "settings")
    }

    /// Whether the app actually turned dark is not something XCUITest can see — it reads the
    /// accessibility tree, not colours. What is asserted here is that the choice takes and holds;
    /// the screenshot is attached so the appearance itself can be checked by eye.
    func testChoosingADarkThemeTakesEffect() {
        app.staticTexts["Settings"].tap()

        let dark = app.buttons["Dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 5))
        dark.tap()

        XCTAssertTrue(dark.isSelected)
        XCTAssertFalse(app.buttons["Automatic"].isSelected)

        attach(app.screenshot(), named: "settings-dark")

        // Still on the settings screen, and the rest of the app still there behind it.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Books"].waitForExistence(timeout: 5))

        attach(app.screenshot(), named: "profile-dark")
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
