import SwiftUI

enum Route: Hashable {
    case detail(String)
    case about
}

@main
struct JargonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel: JargonViewModel
    @StateObject private var quickActions = QuickActions.shared
    @State private var path: [Route] = []
    @State private var pendingSearchTerm: String?

    init() {
        _viewModel = StateObject(wrappedValue: JargonApp.makeViewModel())
    }

    /// `--screenshot-seed` (passed by the `fastlane snapshot` walkthrough) starts
    /// the app from a deterministic state — a fixed pair of favorites, no recent
    /// searches — in an isolated defaults suite, so the screenshots don't depend
    /// on whatever a previous run left behind.
    private static func makeViewModel() -> JargonViewModel {
        guard ProcessInfo.processInfo.arguments.contains("--screenshot-seed") else {
            return JargonViewModel()
        }
        let suite = "screenshot-seed"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        defaults.set(["hacker", "geek"], forKey: "favorite_ids")
        return JargonViewModel(
            favoritesRepository: FavoritesRepository(defaults: defaults),
            searchHistoryRepository: SearchHistoryRepository(defaults: defaults)
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                EntryListView(
                    viewModel: viewModel,
                    onEntryTap: { entry in path.append(.detail(entry.id)) },
                    onAboutTap: { path.append(.about) }
                )
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let id):
                        if let entry = viewModel.findById(id) {
                            EntryDetailView(
                                viewModel: viewModel,
                                entry: entry,
                                onTermTap: { term in handleTermTap(term) }
                            )
                        }
                    case .about:
                        AboutView()
                    }
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                guard let term = linkedTextTerm(from: url) else { return .systemAction }
                handleTermTap(term)
                return .handled
            })
            .onAppear { consumePendingRandomEntry() }
            .onChange(of: quickActions.pendingRandomEntry) { _, pending in
                if pending { consumePendingRandomEntry() }
            }
            .onChange(of: viewModel.entries.isEmpty) { _, isEmpty in
                if !isEmpty { consumePendingRandomEntry() }
            }
        }
    }

    /// Navigates straight to a random entry when the "Random entry" quick action
    /// is pending and the dictionary has finished loading.
    private func consumePendingRandomEntry() {
        guard quickActions.pendingRandomEntry, !viewModel.entries.isEmpty else { return }
        guard let target = viewModel.randomEntry() else { return }
        quickActions.pendingRandomEntry = false
        path = [.detail(target.id)]
    }

    private func handleTermTap(_ term: String) {
        if let target = viewModel.findByTermText(term) {
            path.append(.detail(target.id))
        } else {
            viewModel.searchQuery = term
            path = []
        }
    }
}
