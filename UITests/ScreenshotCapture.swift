import XCTest

/// App Store screenshot walkthrough, driven by `fastlane snapshot`
/// (`bundle exec fastlane screenshots`). Launches with `--screenshot-seed` so
/// "hacker" and "geek" start favorited (see JargonApp.makeViewModel), then
/// captures one shot per key screen. Screen names match the keys in
/// `fastlane/screenshot_captions.yml`.
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

        // Seeded as a favorite, so the star is already filled. Fall back to
        // tapping it if the seed somehow didn't land.
        if app.navigationBars["hacker"].buttons["Add to favorites"].exists {
            app.navigationBars["hacker"].buttons["Add to favorites"].tap()
        }
        XCTAssertTrue(app.navigationBars["hacker"].buttons["Remove from favorites"].waitForExistence(timeout: 5))
        snapshot("04_favorite")

        app.navigationBars["hacker"].buttons.firstMatch.tap() // back
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 5))
        app.buttons["Clear search"].tap()
        XCTAssertTrue(app.staticTexts["0"].waitForExistence(timeout: 5))

        let showFavoritesOnly = app.navigationBars["Jargon"].buttons["Show favorites only"]
        XCTAssertTrue(showFavoritesOnly.waitForExistence(timeout: 5))
        showFavoritesOnly.tap()
        XCTAssertTrue(app.staticTexts["hacker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["geek"].waitForExistence(timeout: 5))
        snapshot("05_favorites")

        app.navigationBars["Jargon"].buttons["Show all entries"].tap()
        app.navigationBars["Jargon"].buttons["About"].tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 5))
        snapshot("06_about")
    }
}
