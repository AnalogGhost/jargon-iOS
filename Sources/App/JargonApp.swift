import SwiftUI

enum Route: Hashable {
    case detail(String)
    case about
}

@main
struct JargonApp: App {
    @StateObject private var viewModel = JargonViewModel()
    @State private var path: [Route] = []
    @State private var pendingSearchTerm: String?

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
        }
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
