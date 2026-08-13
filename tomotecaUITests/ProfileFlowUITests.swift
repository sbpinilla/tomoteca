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

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "archive"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
