//
//  SessionRecoveryUITests.swift
//  tomotecaUITests
//

import XCTest

/// Kills the app mid-session and comes back, which is the whole point of C02 and the one thing
/// a unit test cannot prove: that the session really does outlive the process.
///
/// Uses the **real** store rather than the throwaway one — an in-memory store dies with the
/// process, which is precisely what is being tested against.
final class SessionRecoveryUITests: XCTestCase {

    private var app: XCUIApplication!

    private let launchArguments = [
        "-seedSampleData",
        "-disableNotifications",
        "-startTab", "inProgress",
        "-AppleLanguages", "(en)",
    ]

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()
    }

    override func tearDown() {
        // Leave no session behind for the next run to trip over.
        app.launchArguments = launchArguments
        app.launch()
        if app.buttons["activeSessionBanner"].waitForExistence(timeout: 3) {
            app.buttons["activeSessionBanner"].tap()
            app.buttons["Finish"].tap()
            app.buttons["Save progress"].tap()
        }
    }

    func testASessionSurvivesTheAppBeingKilled() {
        startTenMinuteSession()

        // Gone for good: not backgrounded, killed.
        app.terminate()
        app.launch()

        // The banner is the trace that used to be missing entirely.
        let banner = app.buttons["activeSessionBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Resume session"].exists)

        attach(app.screenshot(), named: "banner")

        banner.tap()

        // Back in the session, with the countdown carried over rather than restarted.
        let remaining = app.staticTexts["remainingTime"]
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))
        XCTAssertTrue(
            remaining.label.range(of: "^(10:00|09:[0-5][0-9])$", options: .regularExpression) != nil,
            "Expected the countdown to carry on, got \(remaining.label)"
        )

        // Resuming a live session must not ask for the page: that only happens at the end.
        XCTAssertFalse(app.staticTexts["What page are you on?"].exists)
    }

    func testASecondSessionCannotBeStartedWhileOneIsRunning() {
        startTenMinuteSession()

        app.terminate()
        app.launch()

        // Open another book entirely and try to start reading it.
        app.buttons["Trunk"].tap()
        // Scoped to the list: the banner also carries the book's title, so an unscoped query
        // matches twice.
        app.cells.containing(.staticText, identifier: "Cien años de soledad").firstMatch.tap()

        // The button offers to go back to what is already running instead of starting again.
        let resume = app.buttons["Resume session"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Start reading session"].exists)

        resume.tap()
        XCTAssertTrue(app.staticTexts["remainingTime"].waitForExistence(timeout: 5))
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func startTenMinuteSession() {
        app.cells.containing(.staticText, identifier: "Cien años de soledad").firstMatch.tap()
        app.buttons["Start reading session"].tap()
        app.buttons["10 min"].tap()
        app.buttons["Start session"].tap()

        XCTAssertTrue(app.staticTexts["remainingTime"].waitForExistence(timeout: 5))

        // Leave the session on its own, as if the app had been swiped away.
        app.swipeDown()
    }
}
