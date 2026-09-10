import SwiftUI
import UIKit

struct EntryDetailView: View {
    @ObservedObject var viewModel: JargonViewModel
    let entry: DictionaryEntry
    let onTermTap: (String) -> Void

    @State private var showCopiedConfirmation = false

    private var isFavorite: Bool {
        viewModel.favoriteIds.contains(entry.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let subtitle = [entry.pronunciation, entry.partOfSpeech]
                    .compactMap { $0 }
                    .joined(separator: "  ·  ")
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let etymology = entry.etymology {
                    LinkedText(text: etymology, terms: entry.seeAlso, font: .subheadline)
                }

                LinkedText(text: entry.definition, terms: entry.seeAlso, font: .body)

                if let history = entry.history {
                    LinkedText(text: history, terms: entry.seeAlso, font: .subheadline)
                }

                if !entry.seeAlso.isEmpty {
                    LinkedText(
                        text: "See also: " + entry.seeAlso.joined(separator: ", "),
                        terms: entry.seeAlso,
                        font: .caption
                    )
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle(entry.term)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.openURL, OpenURLAction { url in
            guard let term = linkedTextTerm(from: url) else { return .systemAction }
            onTermTap(term)
            return .handled
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: entry.shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIPasteboard.general.string = entry.shareText
                    withAnimation { showCopiedConfirmation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { showCopiedConfirmation = false }
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite(entry.id)
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedConfirmation {
                Text("Copied")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 32)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
    }
}
