import SwiftUI
import UIKit

enum RandomEntryShortcut {
    /// Matches `UIApplicationShortcutItemType` in the Info.plist (project.yml).
    static let type = "com.hackerapps.jargon.random-entry"
}

/// Bridges Home Screen quick actions (UIKit) into SwiftUI. `JargonApp` observes
/// `pendingRandomEntry` and, once the dictionary has loaded, navigates to a
/// random entry and clears the flag. Mirrors the Android app's "Random entry"
/// launcher shortcut.
final class QuickActions: ObservableObject {
    static let shared = QuickActions()
    private init() {}

    @Published var pendingRandomEntry = false
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Cold launch from a quick action: the item arrives here, not in performActionFor.
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            handle(item)
        }
        #if DEBUG
        // Home Screen quick actions can't be driven from XCUITest, so the UI test
        // for the navigation path simulates the pending flag with a launch argument.
        if ProcessInfo.processInfo.arguments.contains("--simulate-random-entry-shortcut") {
            QuickActions.shared.pendingRandomEntry = true
        }
        #endif
        return true
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(handle(shortcutItem))
    }

    @discardableResult
    private func handle(_ item: UIApplicationShortcutItem) -> Bool {
        guard item.type == RandomEntryShortcut.type else { return false }
        QuickActions.shared.pendingRandomEntry = true
        return true
    }
}
