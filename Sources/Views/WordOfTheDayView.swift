import SwiftUI

/// The iPad detail column before anything is selected: today's entry, the same one the
/// widget shows, rather than an empty pane.
struct WordOfTheDayView: View {
    @ObservedObject var viewModel: JargonViewModel
    let onOpen: (DictionaryEntry) -> Void

    var body: some View {
        if let entry = WordOfTheDay.entry(for: Date(), in: viewModel.entries) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Word of the day")
                        .font(.subheadline.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.jargonPrimary)

                    Text(entry.term)
                        .font(.system(.largeTitle, design: .monospaced).weight(.bold))

                    let subtitle = [entry.pronunciation, entry.partOfSpeech]
                        .compactMap { $0 }
                        .joined(separator: "  ·  ")
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LinkedText(text: entry.definition, terms: entry.seeAlso, font: .title3)

                    Button("Open entry") { onOpen(entry) }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.jargonPrimary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(40)
                .frame(maxWidth: .infinity)
            }
        } else if viewModel.entries.isEmpty {
            ProgressView()
        } else {
            ContentUnavailableView("Pick an entry", systemImage: "text.book.closed")
        }
    }
}
