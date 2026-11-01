import Foundation

enum DictionaryRepositoryError: Error {
    case missingResource
}

struct DictionaryRepository {
    func loadEntries() async throws -> [DictionaryEntry] {
        try await DictionaryCache.shared.entries()
    }

    /// The bundled jargon.json. The widget extension doesn't carry its own copy: an
    /// extension lives at Jargon.app/PlugIns/<name>.appex, so it reads the containing
    /// app's file instead of shipping the 1.6 MB dictionary twice.
    static func resourceURL(in bundle: Bundle = .main) -> URL? {
        if let url = bundle.url(forResource: "jargon", withExtension: "json") {
            return url
        }
        guard bundle.bundleURL.pathExtension == "appex" else { return nil }
        let appBundleURL = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        return Bundle(url: appBundleURL)?.url(forResource: "jargon", withExtension: "json")
    }
}

/// Decodes the dictionary once per process. The view model, the Spotlight indexer and
/// the App Intents all ask for it, sometimes at the same moment on launch.
actor DictionaryCache {
    static let shared = DictionaryCache()

    private var cached: [DictionaryEntry]?

    func entries() throws -> [DictionaryEntry] {
        if let cached { return cached }
        guard let url = DictionaryRepository.resourceURL() else {
            throw DictionaryRepositoryError.missingResource
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([DictionaryEntry].self, from: data)
        cached = decoded
        return decoded
    }
}
