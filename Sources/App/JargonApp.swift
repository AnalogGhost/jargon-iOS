import CoreSpotlight
import SwiftUI

@main
struct JargonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel: JargonViewModel
    @StateObject private var pendingLaunch = PendingLaunch.shared
    @State private var path: [Route] = []

    init() {
        _viewModel = StateObject(wrappedValue: JargonApp.makeViewModel())
    }

    /// `--screenshot-seed` (passed by the `fastlane snapshot` walkthrough) starts
    /// the app from a deterministic state — a fixed set of favorites, no recent
    /// searches — in an isolated defaults suite, so the screenshots don't depend
    /// on whatever a previous run left behind. "hacker" is deliberately excluded:
    /// the walkthrough favorites it live, so the 03/04 screenshots show a real
    /// before/after instead of a no-op tap on an already-filled star.
    private static func makeViewModel() -> JargonViewModel {
        guard ProcessInfo.processInfo.arguments.contains("--screenshot-seed") else {
            return JargonViewModel()
        }
        let suite = "screenshot-seed"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(["geek", "kludge", "wizard", "grok", "foo"], forKey: FavoritesRepository.favoriteIdsKey)
        return JargonViewModel(
            favoritesRepository: FavoritesRepository(defaults: defaults),
            searchHistoryRepository: SearchHistoryRepository(defaults: defaults)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel, path: $path)
                .onAppear { consumePendingLaunch() }
                .onChange(of: pendingLaunch.pending) { _, pending in
                    if pending != nil { consumePendingLaunch() }
                }
                .onChange(of: viewModel.entries.isEmpty) { _, isEmpty in
                    guard !isEmpty else { return }
                    consumePendingLaunch()
                    SpotlightIndexer.indexIfNeeded(viewModel.entries)
                    JargonShortcuts.updateAppShortcutParameters()
                }
                .onOpenURL { url in
                    if let id = EntryLink.entryId(from: url) {
                        pendingLaunch.pending = .entry(id)
                    }
                }
                .onContinueUserActivity(CSSearchableItemActionType, perform: continueSpotlight)
                .onContinueUserActivity(CSQueryContinuationActionType, perform: continueSpotlight)
        }
    }

    private func continueSpotlight(_ activity: NSUserActivity) {
        pendingLaunch.pending = SpotlightIndexer.launchTarget(for: activity)
    }

    /// Carries out a launch request (quick action, widget, Spotlight, Siri) once the
    /// dictionary has finished loading.
    private func consumePendingLaunch() {
        guard let pending = pendingLaunch.pending, !viewModel.entries.isEmpty else { return }
        pendingLaunch.pending = nil
        switch pending {
        case .randomEntry:
            if let target = viewModel.randomEntry() {
                path = [.detail(target.id)]
            }
        case .entry(let id):
            if viewModel.findById(id) != nil {
                path = [.detail(id)]
            }
        case .search(let query):
            viewModel.searchQuery = query
            path = []
        }
    }
}
