import XCTest

/// App Store screenshot walkthrough, driven by `fastlane snapshot`
/// (`bundle exec fastlane screenshots`). Launches with `--screenshot-seed` for a
/// fixed set of favorites (see JargonApp.makeViewModel), then captures one shot
/// per key screen. On iPad the list and entry share the screen (RootView's split
/// layout), and 01_browse shows the word of the day beside the list. Screen names
/// match the "main"/"back" keys in `Tools/StoreScreenshots/captions.json`.
@MainActor
final class ScreenshotCapture: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["--screenshot-seed"]
        app.launch()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        let search = app.textFields["Search"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5)) // first bundled entry
        snapshot("01_browse")

        search.tap()
        search.typeText("hacker\n") // trailing return dismisses the keyboard for a clean shot
        let cell = app.staticTexts["hacker"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        snapshot("02_search")

        cell.tap()
        XCTAssertTrue(app.navigationBars["hacker"].waitForExistence(timeout: 5))
        snapshot("03_detail")

        // Not seeded as a favorite (see JargonApp.makeViewModel), so this is a
        // real tap — 03/04 show an actual before/after, not the same frame twice.
        app.navigationBars["hacker"].buttons["Add to favorites"].tap()
        XCTAssertTrue(app.navigationBars["hacker"].buttons["Remove from favorites"].waitForExistence(timeout: 5))
        snapshot("04_favorite")

        // On iPad the list stays in the sidebar beside the entry, so there's no back.
        if !isPad {
            app.navigationBars["hacker"].buttons.firstMatch.tap() // back
        }
        let jargonBar = app.navigationBars["Jargon"]
        XCTAssertTrue(jargonBar.waitForExistence(timeout: 5))
        app.buttons["Clear search"].tap()
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5))

        // hacker (just favorited above) plus the seeded set — six entries, so the
        // favorites list reads as a real collection rather than a few rows adrift on
        // a mostly empty screen (especially on the tall iPad canvas).
        jargonBar.buttons["Show favorites only"].tap()
        XCTAssertTrue(app.staticTexts["hacker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["geek"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["wizard"].waitForExistence(timeout: 5))
        snapshot("05_favorites")

        jargonBar.buttons["Show all entries"].tap()
        jargonBar.buttons["About"].tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        snapshot("06_about")
    }
}
