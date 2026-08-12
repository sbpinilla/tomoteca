//
//  ReadingSessionFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// The whole session, end to end: pick a duration, watch the countdown, finish, record the page
/// and see the book's progress move. Unit tests cover the timing; this covers the wiring.
final class ReadingSessionFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-disableNotifications",
            "-startTab", "inProgress",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testInProgressListsOnlyBooksBeingRead() {
        XCTAssertTrue(app.staticTexts["Cien años de soledad"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Sapiens"].exists, "Bought books do not belong here")
        XCTAssertFalse(app.staticTexts["El nombre de la rosa"].exists)
    }

    func testRunningASessionRecordsTheFinalPage() {
        app.staticTexts["Cien años de soledad"].tap()

        let start = app.buttons["Start reading session"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["New session"].waitForExistence(timeout: 5))
        app.buttons["10 min"].tap()
        app.buttons["Start session"].tap()

        // The countdown is running. Asserted as a range rather than an exact value: by the time
        // the test reads it, a second or two of the session has genuinely gone by.
        let remaining = app.staticTexts["remainingTime"]
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))
        XCTAssertTrue(
            remaining.label.range(of: "^(10:00|09:[0-5][0-9])$", options: .regularExpression) != nil,
            "Expected a countdown just under ten minutes, got \(remaining.label)"
        )

        attach(app.screenshot(), named: "active-session")

        app.buttons["Finish"].tap()

        // The page is asked for, and cannot be skipped.
        XCTAssertTrue(app.staticTexts["What page are you on?"].waitForExistence(timeout: 5))
        attach(app.screenshot(), named: "final-page")

        let field = app.textFields["finalPageField"]
        field.tap()
        field.press(forDuration: 1.2)
        app.menuItems["Select All"].tap()
        field.typeText("250")

        app.buttons["Save progress"].tap()

        // Back on the detail, with the bookmark moved.
        XCTAssertTrue(app.staticTexts["Page 250 of 340"].waitForExistence(timeout: 5))
    }

    func testPausingKeepsTheSessionOnScreen() {
        app.staticTexts["Cien años de soledad"].tap()
        app.buttons["Start reading session"].tap()
        app.buttons["Start session"].tap()

        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()

        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
