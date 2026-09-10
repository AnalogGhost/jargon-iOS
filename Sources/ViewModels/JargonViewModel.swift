import Foundation
import Combine

@MainActor
final class JargonViewModel: ObservableObject {
    @Published private(set) var entries: [DictionaryEntry] = []
    @Published var searchQuery: String = ""
    @Published private(set) var showFavoritesOnly: Bool = false
    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var recentSearches: [String] = []
    @Published private(set) var loadError: String?

    @Published private(set) var visibleEntries: [DictionaryEntry] = []

    private let repository: DictionaryRepository
    private let favoritesRepository: FavoritesRepository
    private let searchHistoryRepository: SearchHistoryRepository
    private var cancellables: Set<AnyCancellable> = []

    init(
        repository: DictionaryRepository = DictionaryRepository(),
        favoritesRepository: FavoritesRepository = FavoritesRepository(),
        searchHistoryRepository: SearchHistoryRepository = SearchHistoryRepository()
    ) {
        self.repository = repository
        self.favoritesRepository = favoritesRepository
        self.searchHistoryRepository = searchHistoryRepository

        favoritesRepository.favoriteIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                self?.favoriteIds = ids
                self?.recomputeVisibleEntries()
            }
            .store(in: &cancellables)

        searchHistoryRepository.recentSearches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.recentSearches = $0 }
            .store(in: &cancellables)

        // Local search over ~2,300 entries is fast, but re-running it on every keystroke still
        // churns the list; wait for a short typing pause first. Clearing the field (empty query)
        // applies immediately so the full list comes back without a lag.
        //
        // `$searchQuery` (like all @Published projected publishers) emits on willSet, before
        // `searchQuery` itself is actually updated -- so the closures below must use the emitted
        // value directly rather than re-reading `self.searchQuery`, which would still hold the
        // *previous* value at this point.
        let clears = $searchQuery.filter { $0.isEmpty }
        let typing = $searchQuery
            .filter { !$0.isEmpty }
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
        clears
            .merge(with: typing)
            .sink { [weak self] query in self?.recomputeVisibleEntries(query: query) }
            .store(in: &cancellables)

        loadEntries()
    }

    func loadEntries() {
        loadError = nil
        Task {
            do {
                entries = try await repository.loadEntries()
                recomputeVisibleEntries()
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    func retryLoad() {
        loadEntries()
    }

    /// Records the current query in the recent-search history. Call on an explicit
    /// search submit (keyboard "Search" key), not on every keystroke.
    func commitSearch() {
        searchHistoryRepository.record(searchQuery)
    }

    func selectRecentSearch(_ query: String) {
        searchQuery = query
        searchHistoryRepository.record(query)
    }

    func clearSearchHistory() {
        searchHistoryRepository.clear()
    }

    func toggleShowFavoritesOnly() {
        showFavoritesOnly.toggle()
        recomputeVisibleEntries()
    }

    func toggleFavorite(_ id: String) {
        favoritesRepository.toggleFavorite(id)
    }

    func findById(_ id: String) -> DictionaryEntry? {
        entries.first { $0.id == id }
    }

    func findByTermText(_ term: String) -> DictionaryEntry? {
        jargon_findByTermText(entries, term: term)
    }

    func randomEntry() -> DictionaryEntry? {
        entries.randomElement()
    }

    private func recomputeVisibleEntries(query: String? = nil) {
        let filtered = filterByQuery(entries, query: query ?? searchQuery)
        visibleEntries = filterFavorites(filtered, favoriteIds: favoriteIds, showFavoritesOnly: showFavoritesOnly)
    }
}

// Local alias to avoid ambiguity with the instance method name `findByTermText`.
private func jargon_findByTermText(_ entries: [DictionaryEntry], term: String) -> DictionaryEntry? {
    findByTermText(entries, term: term)
}
