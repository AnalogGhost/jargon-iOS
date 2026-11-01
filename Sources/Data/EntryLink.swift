import Foundation

/// `jargon://entry/<id>` deep links, used by the widget to open the entry it shows.
/// Separate from LinkedText's in-app `jargon-term://` links, which never leave the app.
enum EntryLink {
    static let scheme = "jargon"

    static func url(forEntryId id: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "entry"
        components.path = "/" + id
        return components.url ?? URL(string: "\(scheme)://entry")!
    }

    static func entryId(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == "entry" else { return nil }
        let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return id.isEmpty ? nil : id
    }
}
