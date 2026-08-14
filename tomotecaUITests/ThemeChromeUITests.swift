//
//  ThemeChromeUITests.swift
//  tomotecaUITests
//

import XCTest

/// The tab bar and the back button used to keep the old appearance after switching the theme,
/// until something unrelated forced a layout pass. XCUITest cannot read colours — see
/// ProfileFlowUITests — so this captures the screen right after the switch, before anything else
/// is touched, for the screenshot to be checked by eye.
final class ThemeChromeUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-useInMemoryStore",
            "-seedSampleData",
            "-disableNotifications",
            "-startTab", "profile",
            "-AppleLanguages", "(es)",
        ]
        app.launch()
    }

    func testChromeRightAfterSwitchingTheme() {
        app.staticTexts["Configuración"].tap()

        let claro = app.buttons["Claro"]
        XCTAssertTrue(claro.waitForExistence(timeout: 5))
        claro.tap()
        XCTAssertTrue(claro.isSelected)

        // Deliberately nothing else is tapped: the tab bar and the back button behind this
        // screen are exactly what used to lag behind.
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "chrome-right-after-switch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
