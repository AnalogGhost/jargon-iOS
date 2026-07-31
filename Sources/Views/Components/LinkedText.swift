import SwiftUI

private let linkScheme = "jargon-term"

/// Builds an AttributedString where each occurrence of a `terms` entry (longest match first,
/// case-insensitive) is wrapped in a `jargon-term://<term>` link, so tapping it can be
/// intercepted via `.environment(\.openURL, ...)` without dropping to UIViewRepresentable.
func buildLinkedText(_ text: String, terms: [String], linkColor: Color) -> AttributedString {
    guard !terms.isEmpty, !text.isEmpty else { return AttributedString(text) }

    let sortedTerms = terms.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        .sorted { $0.count > $1.count }
    guard !sortedTerms.isEmpty else { return AttributedString(text) }

    var result = AttributedString()
    let chars = Array(text)
    var i = 0

    while i < chars.count {
        var matched: String?
        for term in sortedTerms {
            let termChars = Array(term)
            guard i + termChars.count <= chars.count else { continue }
            let slice = String(chars[i..<(i + termChars.count)])
            if slice.caseInsensitiveCompare(term) == .orderedSame {
                matched = slice
                break
            }
        }

        if let matched {
            var run = AttributedString(matched)
            let encoded = matched.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? matched
            run.link = URL(string: "\(linkScheme)://term/\(encoded)")
            run.foregroundColor = linkColor
            run.underlineStyle = .single
            result += run
            i += matched.count
        } else {
            result += AttributedString(String(chars[i]))
            i += 1
        }
    }

    return result
}

func linkedTextTerm(from url: URL) -> String? {
    guard url.scheme == linkScheme else { return nil }
    let encoded = url.lastPathComponent
    return encoded.removingPercentEncoding ?? encoded
}

struct LinkedText: View {
    let text: String
    let terms: [String]
    var font: Font = .body

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(buildLinkedText(text, terms: terms, linkColor: .jargonPrimary))
            .font(font)
    }
}
