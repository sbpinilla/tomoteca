//
//  TrackingFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// The history under the chart: that it lists sessions, that "show more" reaches the rest, and
/// that none of it disturbs the chart above — which is the one thing unit tests cannot see.
final class TrackingFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-disableNotifications",
            "-startTab", "tracking",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testHistoryStartsAtFiveAndGrowsByFive() {
        // The seeded week holds six sessions: enough for one page and a bit.
        XCTAssertTrue(app.staticTexts["Recent sessions"].waitForExistence(timeout: 5))
        app.swipeUp()

        let showMore = app.buttons["showMoreSessions"]
        XCTAssertTrue(showMore.waitForExistence(timeout: 5))
        XCTAssertEqual(rowCount, 5)

        attach(app.screenshot(), named: "history")

        // What the chart says must not depend on how much of the list is unfolded.
        let totalBefore = totalMinutes

        showMore.tap()

        XCTAssertEqual(rowCount, 6)
        XCTAssertEqual(totalMinutes, totalBefore, "Showing more rows is not reading more")
        XCTAssertFalse(showMore.exists, "Nothing left to show")
    }

    func testARowNamesItsBookAndWhatWasRead() {
        app.swipeUp()

        let row = app.descendants(matching: .any).matching(identifier: "sessionRow").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))

        // Combined into one announcement, so everything the row shows is in its label.
        XCTAssertTrue(row.label.contains("Cien años de soledad"), "Got: \(row.label)")
        XCTAssertTrue(row.label.contains("Gabriel García Márquez"), "Got: \(row.label)")
        XCTAssertTrue(row.label.contains("Today"), "Got: \(row.label)")
        XCTAssertTrue(
            row.label.range(of: "[0-9]+ pages", options: .regularExpression) != nil,
            "Got: \(row.label)"
        )
    }

    func testChangingTheRangeFoldsTheHistoryBack() {
        app.swipeUp()

        let showMore = app.buttons["showMoreSessions"]
        XCTAssertTrue(showMore.waitForExistence(timeout: 5))
        showMore.tap()
        XCTAssertEqual(rowCount, 6)

        app.buttons["30 days"].tap()

        XCTAssertEqual(rowCount, 5, "A different range starts the list over")
        XCTAssertTrue(app.buttons["showMoreSessions"].exists)
    }

    private var rowCount: Int {
        app.descendants(matching: .any).matching(identifier: "sessionRow").count
    }

    /// The total from the stat tile, which is the topmost thing on screen ending in "min".
    private var totalMinutes: String {
        app.staticTexts
            .matching(NSPredicate(format: "label ENDSWITH ' min'"))
            .firstMatch
            .label
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
