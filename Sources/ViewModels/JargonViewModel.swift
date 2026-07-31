import Foundation
import Combine

@MainActor
final class JargonViewModel: ObservableObject {
    @Published private(set) var entries: [DictionaryEntry] = []
    @Published var searchQuery: String = ""
    @Published private(set) var showFavoritesOnly: Bool = false
    @Published private(set) var favoriteIds: Set<String> = []
    @Published private(set) var loadError: String?

    @Published private(set) var visibleEntries: [DictionaryEntry] = []

    private let repository: DictionaryRepository
    private let favoritesRepository: FavoritesRepository
    private var cancellables: Set<AnyCancellable> = []

    init(
        repository: DictionaryRepository = DictionaryRepository(),
        favoritesRepository: FavoritesRepository = FavoritesRepository()
    ) {
        self.repository = repository
        self.favoritesRepository = favoritesRepository

        favoritesRepository.favoriteIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                self?.favoriteIds = ids
                self?.recomputeVisibleEntries()
            }
            .store(in: &cancellables)

        $searchQuery
            .sink { [weak self] _ in self?.recomputeVisibleEntries() }
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

    private func recomputeVisibleEntries() {
        let filtered = filterByQuery(entries, query: searchQuery)
        visibleEntries = filterFavorites(filtered, favoriteIds: favoriteIds, showFavoritesOnly: showFavoritesOnly)
    }
}

// Local alias to avoid ambiguity with the instance method name `findByTermText`.
private func jargon_findByTermText(_ entries: [DictionaryEntry], term: String) -> DictionaryEntry? {
    findByTermText(entries, term: term)
}
