//
//  BookDetailFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// Covers the navigation into the detail and the one-way status advance, which no unit test can
/// prove: that the row opens the right book and that both screens refresh after the change.
final class BookDetailFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-startTab", "trunk",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testOpeningABookShowsItsDetail() {
        app.staticTexts["Sapiens"].tap()

        XCTAssertTrue(app.staticTexts["Yuval Noah Harari · History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Page 0 of 512"].exists)

        attach(app.screenshot(), named: "detail")

        app.buttons["statusRow"].tap()
        XCTAssertTrue(app.staticTexts["Change status"].waitForExistence(timeout: 5))

        attach(app.screenshot(), named: "status-sheet")
    }

    /// Keeps the screenshot in the result bundle so the screen can be reviewed by eye, not just
    /// asserted on.
    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAdvancingStatusUpdatesDetailAndTrunk() {
        app.staticTexts["Sapiens"].tap()
        XCTAssertTrue(app.staticTexts["Page 0 of 512"].waitForExistence(timeout: 5))

        app.buttons["statusRow"].tap()
        XCTAssertTrue(app.staticTexts["Change status"].waitForExistence(timeout: 5))

        // A bought book can only become a book being read.
        app.buttons["Start reading"].tap()

        // The detail reflects it without being rebuilt.
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 5))

        // And so does the row behind it.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["Sapiens"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Reading"].exists)
    }

    func testFinishedBookOffersNoAdvance() {
        app.staticTexts["El nombre de la rosa"].tap()
        XCTAssertTrue(app.staticTexts["Page 624 of 624"].waitForExistence(timeout: 5))

        app.buttons["statusRow"].tap()
        XCTAssertTrue(app.staticTexts["Change status"].waitForExistence(timeout: 5))

        XCTAssertFalse(app.buttons["Mark as finished"].exists)
        XCTAssertFalse(app.buttons["Start reading"].exists)
        XCTAssertTrue(app.staticTexts["Statuses only move forward, they cannot be reverted."].exists)
    }
}
