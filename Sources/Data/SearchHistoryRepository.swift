import Foundation
import Combine

final class SearchHistoryRepository {
    private let defaults: UserDefaults
    private let recentSearchesKey = "recent_searches"

    private let subject: CurrentValueSubject<[String], Never>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.subject = CurrentValueSubject(defaults.stringArray(forKey: recentSearchesKey) ?? [])
    }

    var recentSearches: AnyPublisher<[String], Never> {
        subject.eraseToAnyPublisher()
    }

    func record(_ query: String) {
        let updated = updatedSearchHistory(subject.value, adding: query)
        guard updated != subject.value else { return }
        defaults.set(updated, forKey: recentSearchesKey)
        subject.send(updated)
    }

    func clear() {
        defaults.removeObject(forKey: recentSearchesKey)
        subject.send([])
    }
}
