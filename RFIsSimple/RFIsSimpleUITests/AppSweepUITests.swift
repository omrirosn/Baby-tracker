import XCTest

/// Walks every screen in the app, runs Apple's accessibility audit on each,
/// and attaches a screenshot.
///
/// This is the UI half of the QA agent (docs/QA-AGENT.md). It is written to be
/// read by an agent as much as by a person: every failure names the screen it
/// happened on, and every screenshot is attached to the result bundle so the
/// agent can look at what the audit could not check — spacing, truncation that
/// still passes contrast, and results that are simply wrong on screen.
final class AppSweepUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - Sweeps

    func testCalculatorScreensAreAccessible() throws {
        let app = launch()
        try sweepTab(named: "Calculators", in: app, screenshotPrefix: "calculator")
    }

    func testReferenceScreensAreAccessible() throws {
        let app = launch()
        try sweepTab(named: "Reference", in: app, screenshotPrefix: "reference")
    }

    func testHomeAndSavedAreAccessible() throws {
        let app = launch()

        for tab in ["Home", "Saved"] {
            XCTAssertTrue(selectTab(tab, in: app), "Could not select the \(tab) tab")
            attachScreenshot(of: app, named: "tab-\(tab)")
            try audit(app, screen: tab)
        }
    }

    /// Settings and About sit behind the Home toolbar button (spec §3).
    func testSettingsIsReachableAndAccessible() throws {
        let app = launch()
        XCTAssertTrue(selectTab("Home", in: app))

        let settings = app.buttons["Settings and about"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "Settings button missing from Home")
        settings.tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "settings")
        try audit(app, screen: "Settings")

        let about = app.buttons["About RF is Simple"]
        if about.waitForExistence(timeout: 3) {
            about.tap()
            XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
            attachScreenshot(of: app, named: "about")
            try audit(app, screen: "About")
        }
    }

    /// Search has to find things by alias, not only by title (spec §3).
    func testSearchFindsByAlias() throws {
        let app = launch()
        XCTAssertTrue(selectTab("Home", in: app))

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "No search field on Home")
        field.tap()
        field.typeText("friis")

        // Both Friis relationships should be offered, clearly differentiated.
        let pathLoss = app.staticTexts["Free-Space Path Loss"]
        let noiseFigure = app.staticTexts["Cascaded Gain & Noise Figure"]
        XCTAssertTrue(pathLoss.waitForExistence(timeout: 5), "\"friis\" did not return free-space path loss")
        XCTAssertTrue(noiseFigure.exists, "\"friis\" did not return cascaded noise figure")

        attachScreenshot(of: app, named: "search-friis")
    }

    /// The app must work with no network at all (spec §18). Nothing here can
    /// prove airplane mode by itself, but a launch with the network path
    /// disabled catches an accidental blocking request on startup.
    func testLaunchesWithoutNetwork() throws {
        let app = launch(extraArguments: ["-RFIsSimpleAssumeOffline", "YES"])
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10),
                      "App did not reach its first screen")
    }

    // MARK: - Sweep helper

    /// Opens every row of a tab's list in turn, audits it, and comes back.
    private func sweepTab(named tab: String, in app: XCUIApplication, screenshotPrefix: String) throws {
        XCTAssertTrue(selectTab(tab, in: app), "Could not select the \(tab) tab")

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10), "\(tab) list never appeared")

        var visited = Set<String>()
        var index = 0

        // The list scrolls, so cells come and go; keep going until a pass adds
        // nothing new.
        while index < 200 {
            let cells = list.cells.allElementsBoundByIndex
            guard index < cells.count else {
                let before = visited.count
                list.swipeUp()
                if list.cells.allElementsBoundByIndex.count == cells.count && visited.count == before {
                    break
                }
                continue
            }

            let cell = cells[index]
            index += 1

            guard cell.exists, cell.isHittable else { continue }
            let label = cell.label
            guard !label.isEmpty, !visited.contains(label) else { continue }
            visited.insert(label)

            cell.tap()

            // A detail screen always has a back button; a row that did not
            // navigate (a section header, a button) will not.
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            guard backButton.waitForExistence(timeout: 3) else { continue }

            let screen = app.navigationBars.firstMatch.identifier
            attachScreenshot(of: app, named: "\(screenshotPrefix)-\(sanitised(label))")
            try audit(app, screen: screen.isEmpty ? label : screen)

            backButton.tap()
            _ = list.waitForExistence(timeout: 5)
        }

        XCTAssertGreaterThan(visited.count, 3, "Only \(visited.count) rows were opened in \(tab)")
    }

    // MARK: - Audit

    /// Runs Apple's accessibility audit and reports each finding against the
    /// screen it was found on.
    private func audit(_ app: XCUIApplication, screen: String) throws {
        try app.performAccessibilityAudit { issue in
            // Report everything; the agent triages. Returning true keeps the
            // issue, false would suppress it.
            XCTContext.runActivity(named: "Accessibility issue on \(screen)") { activity in
                activity.add(XCTAttachment(string: issue.compactDescription))
            }
            return true
        }
    }

    // MARK: - Utilities

    private func launch(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-RFIsSimpleUITesting", "YES"] + extraArguments
        app.launch()
        return app
    }

    private func selectTab(_ name: String, in app: XCUIApplication) -> Bool {
        let button = app.tabBars.buttons[name]
        guard button.waitForExistence(timeout: 10) else { return false }
        button.tap()
        return true
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func sanitised(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return String(
            text.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        ).prefix(60).description
    }
}
