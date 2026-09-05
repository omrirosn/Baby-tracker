import XCTest

/// The three presentation conditions spec §18 requires to stay usable: Light
/// Mode, Dark Mode and large Dynamic Type.
///
/// Each run screenshots the same set of screens, so the agent can compare them
/// side by side and see clipping or contrast loss that the audit alone will
/// not always catch.
final class AppearanceAndTypeUITests: XCTestCase {

    /// The screens worth photographing in every condition: the densest layouts
    /// in the app, where clipping shows up first.
    private let screensToCapture = [
        ("Calculators", "Reflection Converter"),
        ("Calculators", "Cascaded Gain & Noise Figure"),
        ("Calculators", "Link Budget"),
        ("Reference", "Thermal Noise")
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testDefaultTypeSize() throws {
        try capture(contentSize: nil, label: "default")
    }

    /// The largest non-accessibility size — where most layouts start to break.
    func testExtraExtraExtraLargeType() throws {
        try capture(contentSize: "UICTContentSizeCategoryXXXL", label: "xxxl")
    }

    /// An accessibility size, where the input rows are meant to switch to a
    /// two-line layout rather than clip.
    func testAccessibilityExtraExtraExtraLargeType() throws {
        try capture(contentSize: "UICTContentSizeCategoryAccessibilityXXXL", label: "a11y-xxxl")
    }

    /// Dark Mode, driven through the app's own appearance setting so the
    /// setting itself is exercised at the same time.
    func testDarkMode() throws {
        let app = launch(contentSize: nil)
        try setAppearance("Dark", in: app)

        for (tab, screen) in screensToCapture {
            try open(screen, inTab: tab, of: app, screenshotName: "dark-\(slug(screen))")
        }

        // Put it back, so a failed run does not leave the simulator dark.
        try setAppearance("System", in: app)
    }

    // MARK: - Helpers

    private func capture(contentSize: String?, label: String) throws {
        let app = launch(contentSize: contentSize)

        for (tab, screen) in screensToCapture {
            try open(screen, inTab: tab, of: app, screenshotName: "\(label)-\(slug(screen))")

            // Anything clipped or overlapping at this size is an audit finding.
            try app.performAccessibilityAudit(for: [.dynamicType, .textClipped, .elementDetection])
        }
    }

    private func launch(contentSize: String?) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-RFIsSimpleUITesting", "YES"]
        if let contentSize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize]
        }
        app.launch()
        return app
    }

    private func open(
        _ screen: String,
        inTab tab: String,
        of app: XCUIApplication,
        screenshotName: String
    ) throws {
        let tabButton = app.tabBars.buttons[tab]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 10), "No \(tab) tab")
        tabButton.tap()

        let row = app.cells.containing(.staticText, identifier: screen).firstMatch
        guard row.waitForExistence(timeout: 5) else {
            XCTFail("Could not find \(screen) in \(tab)")
            return
        }
        row.tap()

        XCTAssertTrue(
            app.navigationBars.firstMatch.waitForExistence(timeout: 5),
            "\(screen) did not open"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = screenshotName
        attachment.lifetime = .keepAlways
        add(attachment)

        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    private func setAppearance(_ option: String, in app: XCUIApplication) throws {
        app.tabBars.buttons["Home"].tap()
        let settings = app.buttons["Settings and about"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        let choice = app.buttons[option]
        if choice.waitForExistence(timeout: 5) {
            choice.tap()
        } else {
            XCTFail("Appearance option \(option) not found in Settings")
        }

        app.buttons["Done"].tap()
    }

    private func slug(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "/", with: "-")
    }
}
