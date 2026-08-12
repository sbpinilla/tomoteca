//
//  AddBookFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// End-to-end cover for the one flow that proves the whole stack is wired: typing a book in the
/// form and seeing it appear in the trunk. Unit tests cover each layer, but only this catches a
/// broken binding, a sheet that never dismisses or a list that does not refresh.
final class AddBookFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        // A throwaway store per launch: otherwise the book added by one test is still there
        // when the next one expects an empty trunk.
        app.launchArguments = [
            "-useInMemoryStore",
            "-startTab", "trunk",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testAddingABookShowsItInTheTrunk() {
        XCTAssertTrue(app.staticTexts["No books yet"].waitForExistence(timeout: 5))

        app.buttons["Add book"].tap()
        XCTAssertTrue(app.navigationBars["New book"].waitForExistence(timeout: 5))

        let save = app.buttons["Save"]
        XCTAssertFalse(save.isEnabled, "Save must stay disabled until the form is valid")

        app.textFields["Title"].tap()
        app.typeText("Dune")

        app.buttons["Choose"].tap()
        app.buttons["Science fiction"].tap()

        app.textFields["Number of pages"].tap()
        app.typeText("412")

        XCTAssertTrue(save.isEnabled, "Save must enable once title, genre and pages are filled")
        save.tap()

        // Back on the trunk, with the book listed and the sheet gone.
        XCTAssertTrue(app.staticTexts["Dune"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No books yet"].exists)
    }

    func testCancellingDiscardsTheBook() {
        app.buttons["Add book"].tap()

        app.textFields["Title"].tap()
        app.typeText("Discarded")

        app.buttons["Cancel"].tap()

        XCTAssertTrue(app.staticTexts["No books yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Discarded"].exists)
    }
}
