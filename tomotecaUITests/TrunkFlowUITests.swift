//
//  TrunkFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// Covers searching, filtering, deleting and editing from the trunk — the interactions that
/// only exist as gestures and cannot be proven by a unit test.
final class TrunkFlowUITests: XCTestCase {

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

    func testSearchNarrowsTheList() {
        XCTAssertTrue(app.staticTexts["Sapiens"].waitForExistence(timeout: 5))

        app.searchFields.firstMatch.tap()
        app.typeText("sapiens")

        XCTAssertTrue(app.staticTexts["Sapiens"].exists)
        XCTAssertFalse(app.staticTexts["Project Hail Mary"].exists)
    }

    func testSearchIgnoresAccents() {
        app.searchFields.firstMatch.tap()
        app.typeText("garcia")

        XCTAssertTrue(app.staticTexts["Cien años de soledad"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Sapiens"].exists)
    }

    func testSearchWithoutMatchesSaysSo() {
        app.searchFields.firstMatch.tap()
        app.typeText("zzzzz")

        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 5))
    }

    func testFilterNarrowsByStatus() {
        app.buttons["statusFilter"].tap()
        app.buttons["Reading"].tap()

        XCTAssertTrue(app.staticTexts["Cien años de soledad"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Sapiens"].exists)
    }

    func testSwipingDeletesABook() {
        let row = app.cells.containing(.staticText, identifier: "Sapiens").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        row.swipeLeft()
        app.buttons["Delete"].tap()

        XCTAssertFalse(app.staticTexts["Sapiens"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Project Hail Mary"].exists, "Only the swiped book goes")
    }

    func testEditingABookKeepsItsStatus() {
        app.staticTexts["Sapiens"].tap()
        XCTAssertTrue(app.staticTexts["Bought"].waitForExistence(timeout: 5))

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit book"].waitForExistence(timeout: 5))

        // The status belongs to the status sheet alone; the edit form must not offer it.
        XCTAssertFalse(app.staticTexts["Initial status"].exists)

        let title = app.textFields["Title"]
        title.tap()
        title.typeText(" revisado")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Sapiens revisado"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bought"].exists, "Editing must not disturb the status")
    }
}
