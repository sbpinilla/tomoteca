//
//  OnboardingPersistenceUITests.swift
//  tomotecaUITests
//

import XCTest

/// That the welcome screens really do show only once: real persistence, real relaunch.
///
/// Runs **without** `-useInMemoryStore`, like `ThemePersistenceUITests` and
/// `SessionRecoveryUITests` — that flag marks onboarding seen on every launch precisely so every
/// other UI suite does not have to cross it first, which is the opposite of what this proves.
final class OnboardingPersistenceUITests: XCTestCase {

    private var app: XCUIApplication!

    private let launchArguments = [
        "-showOnboarding",
        "-disableNotifications",
        "-AppleLanguages", "(en)",
    ]

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()
    }

    override func tearDown() {
        // Leave the simulator with onboarding seen, which is the state every other suite here
        // expects to find it in already.
        app.launchArguments = launchArguments
        app.launch()
        let skip = app.buttons["onboardingSkip"]
        if skip.waitForExistence(timeout: 3) { skip.tap() }
    }

    func testDoesNotReturnAfterBeingSkippedAndTheAppRelaunched() {
        let skip = app.buttons["onboardingSkip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))

        // Relaunched without `-showOnboarding`: what a real second launch looks like, reading
        // whatever was actually written down rather than being forced back open.
        app.terminate()
        app.launchArguments = ["-disableNotifications", "-AppleLanguages", "(en)"]
        app.launch()

        XCTAssertFalse(
            app.buttons["onboardingSkip"].waitForExistence(timeout: 3),
            "Onboarding came back after already being seen"
        )
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
    }

    func testDoesNotReturnAfterFinishingTheLastPageAndTheAppRelaunched() {
        app.swipeLeft()
        app.swipeLeft()
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-disableNotifications", "-AppleLanguages", "(en)"]
        app.launch()

        XCTAssertFalse(app.buttons["onboardingSkip"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
    }
}
