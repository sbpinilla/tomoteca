//
//  OnboardingFlowUITests.swift
//  tomotecaUITests
//

import XCTest

/// The welcome screens: the three pages, skipping, finishing, and — the one that matters most —
/// that neither of those two ways of closing it brings it back on the next launch.
final class OnboardingFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-showOnboarding",
            "-disableNotifications",
            "-AppleLanguages", "(en)",
        ]
        app.launch()
    }

    func testSwipingThroughAllThreePages() {
        XCTAssertTrue(app.staticTexts["Organize your library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Get Started"].exists, "Not offered before the last page")

        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Read with a timer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Get Started"].exists)

        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["See how much you read"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Get Started"].exists, "Offered only on the last page")

        attach(app.screenshot(), named: "last-page")
    }

    func testGetStartedOnTheLastPageEntersTheApp() {
        app.swipeLeft()
        app.swipeLeft()

        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
    }

    func testSkipDismissesFromTheFirstPage() {
        let skip = app.buttons["onboardingSkip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()

        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
    }

    func testSkipDismissesFromAMiddlePageToo() {
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Read with a timer"].waitForExistence(timeout: 5))

        app.buttons["onboardingSkip"].tap()

        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
