import XCTest

/// Captures the "Word of the Day" widget on the Home Screen for the App Store slide. Drives
/// SpringBoard, so it's slower and more fragile than the in-app walkthrough and runs only
/// from `fastlane snapshot` (see Snapfile), never in CI.
@MainActor
final class HomeScreenCapture: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureHomeScreenWidget() throws {
        // The widget slide is iPhone-only (captions.json); the iPad Home Screen's edit
        // mode doesn't drive reliably from XCUITest.
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Widget slide is iPhone-only")
        // Launch once so the system registers the app's widget extension.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        XCTAssertTrue(app.navigationBars["Jargon"].waitForExistence(timeout: 15))

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 10))

        // Swipe to the page holding Jargon's icon, where the widget lands.
        let widget = springboard.icons
            .matching(NSPredicate(format: "identifier == %@ AND value == %@", "Jargon", "Widget")).firstMatch
        // The first page is the stock apps; Jargon's icon, and the widget, land on the second.
        if !widget.waitForExistence(timeout: 3) {
            springboard.swipeLeft()
        }
        if !widget.waitForExistence(timeout: 3) {
            addWidget(springboard)
        }
        XCTAssertTrue(widget.waitForExistence(timeout: 20))
        sleep(3) // let the timeline render
        snapshot("07_widget")
    }

    private func addWidget(_ springboard: XCUIApplication) {
        // Long-press an empty spot to enter jiggle mode, then open the widget gallery.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).press(forDuration: 1.5)
        let edit = springboard.buttons["Edit"]
        if edit.waitForExistence(timeout: 5) {
            edit.tap()
            let addWidget = springboard.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "Add Widget")).firstMatch
            XCTAssertTrue(addWidget.waitForExistence(timeout: 5))
            addWidget.tap()
        } else {
            let add = springboard.buttons["Add"]
            XCTAssertTrue(add.waitForExistence(timeout: 5))
            add.tap()
        }

        let search = springboard.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Jargon")
        let result = springboard.cells.matching(NSPredicate(format: "label CONTAINS[c] %@", "Jargon")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()

        // The gallery opens on the small size; swipe once to the medium one.
        let galleryAdd = springboard.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Add Widget")).firstMatch
        XCTAssertTrue(galleryAdd.waitForExistence(timeout: 10))
        springboard.swipeLeft()
        sleep(1)
        galleryAdd.tap()

        let done = springboard.buttons["Done"]
        if done.waitForExistence(timeout: 5) { done.tap() }
    }
}
