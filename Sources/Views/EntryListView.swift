import SwiftUI

private let scrubberLetters: [Character] = ["#"] + Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

struct EntryListView: View {
    @ObservedObject var viewModel: JargonViewModel
    let onEntryTap: (DictionaryEntry) -> Void
    let onAboutTap: () -> Void

    var body: some View {
        content
            .navigationTitle("Jargon")
            .toolbar { toolbarContent }
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.loadError, viewModel.entries.isEmpty {
            ErrorStateView(error: error, onRetry: { viewModel.retryLoad() })
        } else if viewModel.entries.isEmpty {
            ProgressView()
        } else {
            EntryListBody(viewModel: viewModel, onEntryTap: onEntryTap)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button(action: onAboutTap) {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("About")

            Button(action: { viewModel.toggleShowFavoritesOnly() }) {
                Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
            }
            .accessibilityLabel(viewModel.showFavoritesOnly ? "Show all entries" : "Show favorites only")

            Button(action: {
                if let entry = viewModel.randomEntry() {
                    onEntryTap(entry)
                }
            }) {
                Image(systemName: "shuffle")
            }
            .accessibilityLabel("Random entry")
        }
    }
}

private struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Couldn't load the dictionary")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct EntryListBody: View {
    @ObservedObject var viewModel: JargonViewModel
    let onEntryTap: (DictionaryEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)

            if viewModel.visibleEntries.isEmpty {
                Spacer()
                Text(viewModel.showFavoritesOnly ? "No favorites yet" : "No entries found")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                EntryListWithScrubber(
                    entries: viewModel.visibleEntries,
                    favoriteIds: viewModel.favoriteIds,
                    onEntryTap: onEntryTap
                )
            }
        }
    }
}

private struct EntryListWithScrubber: View {
    let entries: [DictionaryEntry]
    let favoriteIds: Set<String>
    let onEntryTap: (DictionaryEntry) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                List(entries, id: \.id) { entry in
                    EntryRow(entry: entry, isFavorite: favoriteIds.contains(entry.id))
                        .contentShape(Rectangle())
                        .onTapGesture { onEntryTap(entry) }
                        .id(entry.id)
                }
                .listStyle(.plain)

                AlphabetScrubber(entries: entries) { letter in
                    if let id = idForLetter(entries, letter: letter) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }
}

private struct EntryRow: View {
    let entry: DictionaryEntry
    let isFavorite: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.term)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(entry.definition.prefix(80))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.jargonPrimary)
            }
        }
    }
}

private func idForLetter(_ entries: [DictionaryEntry], letter: Character) -> String? {
    guard !entries.isEmpty else { return nil }
    if letter == "#" { return entries.first?.id }
    let key = Character(letter.lowercased())
    let match = entries.first { ($0.sortKey.first ?? "#") >= key }
    return (match ?? entries.last)?.id
}

private struct AlphabetScrubber: View {
    let entries: [DictionaryEntry]
    let onLetterTap: (Character) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(scrubberLetters, id: \.self) { letter in
                Text(String(letter))
                    .font(.system(size: 10))
                    .frame(maxHeight: .infinity)
                    .onTapGesture { onLetterTap(letter) }
            }
        }
        .frame(width: 24)
        .padding(.vertical, 4)
    }
}
