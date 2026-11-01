import SwiftUI
import WidgetKit

/// "Word of the day" for the Home Screen and Lock Screen. Reads the containing app's
/// bundled dictionary (see DictionaryRepository.resourceURL), so it needs no App Group,
/// no network and no shared storage: the day's entry is a pure function of the date.
struct WordOfTheDayEntry: TimelineEntry {
    let date: Date
    let entry: DictionaryEntry?
}

struct WordOfTheDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordOfTheDayEntry {
        WordOfTheDayEntry(date: Date(), entry: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WordOfTheDayEntry) -> Void) {
        Task {
            let entries = (try? await DictionaryCache.shared.entries()) ?? []
            completion(WordOfTheDayEntry(date: Date(), entry: WordOfTheDay.entry(for: Date(), in: entries) ?? .placeholder))
        }
    }

    /// A week of entries, one per local midnight, then WidgetKit asks again.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> Void) {
        Task {
            let entries = (try? await DictionaryCache.shared.entries()) ?? []
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
            let timeline = days.map { day in
                WordOfTheDayEntry(date: day, entry: WordOfTheDay.entry(for: day, in: entries))
            }
            completion(Timeline(entries: timeline, policy: .atEnd))
        }
    }
}

struct WordOfTheDayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let item: WordOfTheDayEntry

    var body: some View {
        content
            .widgetURL(item.entry.map { EntryLink.url(forEntryId: $0.id) })
            .containerBackground(for: .widget) { background }
    }

    @ViewBuilder
    private var content: some View {
        if let entry = item.entry {
            switch family {
            case .accessoryInline:
                Text(entry.term)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.term)
                        .font(.headline)
                        .widgetAccentable()
                    Text(entry.definition)
                        .font(.caption)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
                    Text("Word of the day")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(WidgetColors.accent)
                    Text(entry.term)
                        .font(.system(family == .systemSmall ? .headline : .title3, design: .monospaced).weight(.bold))
                        .foregroundStyle(WidgetColors.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(entry.definition)
                        .font(family == .systemLarge ? .body : .caption)
                        .foregroundStyle(WidgetColors.subline)
                        .lineLimit(definitionLines)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        } else {
            Text("Open Jargon to load the dictionary.")
                .font(.caption)
        }
    }

    private var definitionLines: Int {
        switch family {
        case .systemSmall: return 4
        case .systemLarge: return 14
        default: return 4
        }
    }

    @ViewBuilder
    private var background: some View {
        switch family {
        case .accessoryInline, .accessoryRectangular:
            Color.clear
        default:
            WidgetColors.background
        }
    }
}

/// The terminal-green palette of the app icon and store screenshots.
enum WidgetColors {
    static let background = Color(red: 0x0D / 255, green: 0x1A / 255, blue: 0x10 / 255)
    static let ink = Color.white
    static let accent = Color(red: 0x81 / 255, green: 0xC7 / 255, blue: 0x84 / 255)
    static let subline = Color(red: 0xBF / 255, green: 0xD3 / 255, blue: 0xC2 / 255)
}

struct WordOfTheDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WordOfTheDay", provider: WordOfTheDayProvider()) { item in
            WordOfTheDayWidgetView(item: item)
        }
        .configurationDisplayName("Word of the Day")
        .description("A new Jargon File entry every day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct JargonWidgets: WidgetBundle {
    var body: some Widget {
        WordOfTheDayWidget()
    }
}

extension DictionaryEntry {
    static let placeholder = DictionaryEntry(
        id: "hacker",
        term: "hacker",
        sortKey: "hacker",
        definition: "A person who enjoys exploring the details of programmable systems and how to stretch their capabilities."
    )
}
