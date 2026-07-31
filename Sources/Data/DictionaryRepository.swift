import Foundation

enum DictionaryRepositoryError: Error {
    case missingResource
}

struct DictionaryRepository {
    func loadEntries() async throws -> [DictionaryEntry] {
        guard let url = Bundle.main.url(forResource: "jargon", withExtension: "json") else {
            throw DictionaryRepositoryError.missingResource
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([DictionaryEntry].self, from: data)
    }
}
