import SwiftUI
import UIKit

enum RandomEntryShortcut {
    /// Matches `UIApplicationShortcutItemType` in the Info.plist (project.yml).
    static let type = "com.hackerapps.jargon.random-entry"
}

/// Where the app should go next because something outside the view hierarchy asked:
/// a Home Screen quick action, a widget tap, a Spotlight result, or an App Intent.
enum LaunchTarget: Equatable {
    case randomEntry
    case entry(String)
    case search(String)
}

/// Bridges launch requests from UIKit, WidgetKit, Core Spotlight and App Intents into
/// SwiftUI. `JargonApp` observes `pending` and, once the dictionary has loaded,
/// navigates and clears it. The quick action mirrors the Android app's "Random entry"
/// launcher shortcut.
@MainActor
final class PendingLaunch: ObservableObject {
    static let shared = PendingLaunch()
    private init() {}

    @Published var pending: LaunchTarget?
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
        // Home Screen quick actions, widgets and Spotlight can't be driven from XCUITest,
        // so the UI tests simulate the pending launch with launch arguments.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--simulate-random-entry-shortcut") {
            PendingLaunch.shared.pending = .randomEntry
        }
        if let index = arguments.firstIndex(of: "--simulate-open-url"), index + 1 < arguments.count,
           let url = URL(string: arguments[index + 1]), let id = EntryLink.entryId(from: url) {
            PendingLaunch.shared.pending = .entry(id)
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
        PendingLaunch.shared.pending = .randomEntry
        return true
    }
}
