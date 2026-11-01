import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

/// Adds every dictionary entry to the on-device Spotlight index, so searching "kluge"
/// from the Home Screen offers Jargon's entry. The index lives on the device like the
/// rest of the app's data; nothing goes over the network.
///
/// Re-indexing 2,300 items is cheap but not free, so it only runs when the bundled
/// dictionary changes (keyed on the app version and entry count).
enum SpotlightIndexer {
    static let domainIdentifier = "com.hackerapps.jargon.entries"
    private static let indexedVersionKey = "spotlight_indexed_version"

    static func indexIfNeeded(_ entries: [DictionaryEntry], defaults: UserDefaults = .standard) {
        guard CSSearchableIndex.isIndexingAvailable(), !entries.isEmpty else { return }
        let version = indexVersion(entryCount: entries.count)
        guard defaults.string(forKey: indexedVersionKey) != version else { return }

        let items = entries.map(searchableItem)
        let index = CSSearchableIndex.default()
        index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { _ in
            index.indexSearchableItems(items) { error in
                if error == nil {
                    defaults.set(version, forKey: indexedVersionKey)
                }
            }
        }
    }

    static func indexVersion(entryCount: Int, bundle: Bundle = .main) -> String {
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        return "\(appVersion)/\(entryCount)"
    }

    static func searchableItem(for entry: DictionaryEntry) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = entry.term
        attributes.displayName = entry.term
        attributes.contentDescription = entry.definition
        attributes.keywords = [entry.term, "jargon", "hacker"]
        return CSSearchableItem(uniqueIdentifier: entry.id, domainIdentifier: domainIdentifier, attributeSet: attributes)
    }

    /// The entry a Spotlight result was opened for, or the query to carry over when the
    /// person taps "Search in app".
    static func launchTarget(for activity: NSUserActivity) -> LaunchTarget? {
        switch activity.activityType {
        case CSSearchableItemActionType:
            guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return nil }
            return .entry(id)
        case CSQueryContinuationActionType:
            guard let query = activity.userInfo?[CSSearchQueryString] as? String else { return nil }
            return .search(query)
        default:
            return nil
        }
    }
}
