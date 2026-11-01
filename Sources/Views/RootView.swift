import SwiftUI

enum Route: Hashable {
    case detail(String)
    case about
}

/// One navigation state, two layouts. `path` is the whole route stack; on iPhone (compact
/// width) it drives a single NavigationStack over the list. On iPad (regular width) the
/// list stays in the sidebar, `path.first` is the entry or About page shown in the detail
/// column, and the rest of `path` is what cross-references have pushed on top of it.
/// Because both layouts read the same array, rotating or resizing a Split View window
/// keeps the person where they were.
struct RootView: View {
    @ObservedObject var viewModel: JargonViewModel
    @Binding var path: [Route]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                splitLayout
            } else {
                stackLayout
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            guard let term = linkedTextTerm(from: url) else { return .systemAction }
            handleTermTap(term)
            return .handled
        })
    }

    private var stackLayout: some View {
        NavigationStack(path: $path) {
            entryList(selectedId: nil)
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            entryList(selectedId: selectedEntryId)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 480)
        } detail: {
            NavigationStack(path: detailPath) {
                Group {
                    if let root = path.first {
                        destination(root)
                    } else {
                        WordOfTheDayView(viewModel: viewModel, onOpen: { select($0) })
                    }
                }
                .navigationDestination(for: Route.self, destination: destination)
            }
            // A fresh stack per selection, so picking another entry from the sidebar
            // doesn't animate a push from the previous one.
            .id(path.first)
        }
        .navigationSplitViewStyle(.balanced)
    }

    private func entryList(selectedId: String?) -> some View {
        EntryListView(
            viewModel: viewModel,
            selectedId: selectedId,
            onEntryTap: { select($0) },
            onAboutTap: { path = [.about] }
        )
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .detail(let id):
            if let entry = viewModel.findById(id) {
                EntryDetailView(viewModel: viewModel, entry: entry)
            }
        case .about:
            AboutView()
        }
    }

    private var selectedEntryId: String? {
        if case .detail(let id) = path.first { return id }
        return nil
    }

    private var detailPath: Binding<[Route]> {
        Binding(
            get: { Array(path.dropFirst()) },
            set: { path = Array(path.prefix(1)) + $0 }
        )
    }

    /// Opening an entry from the list (or a widget, Spotlight, Siri) starts a fresh
    /// stack: on iPhone the list is the root underneath it, on iPad it becomes the
    /// detail column's root.
    private func select(_ entry: DictionaryEntry) {
        path = [.detail(entry.id)]
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
