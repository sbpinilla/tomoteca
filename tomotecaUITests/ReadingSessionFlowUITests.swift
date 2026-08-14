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

    /// The countdown froze on screen while the session ran perfectly well underneath: the number
    /// was correct at every point, it just never got redrawn. Only a test that reads it **twice**
    /// catches that — asserting it exists, or that it starts near ten minutes, passed throughout.
    func testTheCountdownRunsDownOnScreen() {
        startSession()

        let remaining = app.staticTexts["remainingTime"]
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))

        let first = remaining.label
        let second = waitForCountdown(toChangeFrom: first)

        XCTAssertNotEqual(second, first, "The countdown is frozen at \(first)")
        // Zero-padded mm:ss, so plain string order is time order within a session.
        XCTAssertLessThan(second, first, "The countdown moved the wrong way")
    }

    func testPausingFreezesTheCountdownAndResumingMovesItAgain() {
        startSession()
        XCTAssertTrue(app.staticTexts["remainingTime"].waitForExistence(timeout: 5))

        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))

        // Read after the pause has settled, so what is compared is time spent paused.
        let frozen = app.staticTexts["remainingTime"].label
        let whilePaused = waitForCountdown(toChangeFrom: frozen, timeout: 3)
        XCTAssertEqual(whilePaused, frozen, "A paused session must not keep counting down")

        app.buttons["Resume"].tap()

        let afterResuming = waitForCountdown(toChangeFrom: frozen)
        XCTAssertNotEqual(afterResuming, frozen, "The countdown did not pick up again")
    }

    // MARK: Starting from the tab

    /// The seeded library has a single book being read, which is the case this shortcut is for.
    func testASingleBookStartsItsSessionFromTheTab() {
        let start = app.buttons["Start reading session"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))

        attach(app.screenshot(), named: "in-progress-single")

        start.tap()

        // The same duration sheet the detail opens, and the same session behind it.
        XCTAssertTrue(app.staticTexts["New session"].waitForExistence(timeout: 5))
        app.buttons["10 min"].tap()
        app.buttons["Start session"].tap()

        XCTAssertTrue(app.staticTexts["remainingTime"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cien años de soledad"].exists, "The session is on that book")
    }

    func testTheRowStillLeadsToTheBook() {
        app.staticTexts["Cien años de soledad"].tap()

        // The detail, not the session: the shortcut adds a way in, it does not replace one.
        XCTAssertTrue(app.staticTexts["Page 210 of 340"].waitForExistence(timeout: 5))
    }

    func testASecondBookBeingReadTakesTheShortcutAway() {
        XCTAssertTrue(app.buttons["Start reading session"].waitForExistence(timeout: 5))

        // Put a second book on this shelf, which is what makes the choice a real one.
        app.buttons["Trunk"].tap()
        app.staticTexts["Sapiens"].tap()
        app.buttons["statusRow"].tap()
        app.buttons["Start reading"].tap()
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 5))

        app.buttons["In progress"].tap()

        XCTAssertTrue(app.staticTexts["Sapiens"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cien años de soledad"].exists)
        XCTAssertFalse(
            app.buttons["Start reading session"].exists,
            "With two books, which one to read is a choice the tab cannot make"
        )
    }

    /// Opens the book being read and starts a ten-minute session on it.
    private func startSession() {
        app.staticTexts["Cien años de soledad"].tap()

        let start = app.buttons["Start reading session"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["New session"].waitForExistence(timeout: 5))
        app.buttons["10 min"].tap()
        app.buttons["Start session"].tap()
    }

    /// The countdown as soon as it differs from `label`, or as it stands once the wait is over.
    ///
    /// Polled rather than slept through, so a running countdown is confirmed in about a second
    /// and only a frozen one pays the whole timeout.
    private func waitForCountdown(
        toChangeFrom label: String,
        timeout: TimeInterval = 6
    ) -> String {
        let element = app.staticTexts["remainingTime"]
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let current = element.label
            if current != label { return current }
            Thread.sleep(forTimeInterval: 0.25)
        }

        return element.label
    }

    private func attach(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
