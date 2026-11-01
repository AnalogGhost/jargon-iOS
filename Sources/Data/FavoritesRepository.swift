import Foundation
import Combine

final class FavoritesRepository {
    private let defaults: UserDefaults
    static let favoriteIdsKey = "favorite_ids"

    private let subject: CurrentValueSubject<Set<String>, Never>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let initial = Set(defaults.stringArray(forKey: Self.favoriteIdsKey) ?? [])
        self.subject = CurrentValueSubject(initial)
    }

    var favoriteIds: AnyPublisher<Set<String>, Never> {
        subject.eraseToAnyPublisher()
    }

    func toggleFavorite(_ id: String) {
        var current = subject.value
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        defaults.set(Array(current), forKey: Self.favoriteIdsKey)
        subject.send(current)
    }
}
