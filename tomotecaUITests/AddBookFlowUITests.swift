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

    /// The point of C03: the row takes the tap, not only the line of text inside it.
    func testTappingTheLabelFocusesTheField() {
        app.buttons["Add book"].tap()
        XCTAssertTrue(app.navigationBars["New book"].waitForExistence(timeout: 5))

        // The label, not the field: before the change this touch did nothing at all.
        app.staticTexts["Title"].tap()
        app.typeText("Dune")

        XCTAssertEqual(app.textFields["Title"].value as? String, "Dune")
    }

    /// The empty space beside the label is part of the row too.
    func testTappingBesideTheLabelFocusesTheField() {
        app.buttons["Add book"].tap()
        XCTAssertTrue(app.navigationBars["New book"].waitForExistence(timeout: 5))

        let label = app.staticTexts["Number of pages"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))

        // Off to the right of the label, in the gap that used to swallow touches. Anchored to
        // the label rather than to the text field, which already spanned the row before C03 and
        // would prove nothing.
        label.coordinate(withNormalizedOffset: CGVector(dx: 2.5, dy: 0.5)).tap()
        app.typeText("412")

        XCTAssertEqual(app.textFields["Number of pages"].value as? String, "412")
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
