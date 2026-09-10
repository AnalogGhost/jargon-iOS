import Foundation

extension DictionaryEntry {
    /// Plain-text rendering of the entry for the Share and Copy actions: term, an
    /// optional pronunciation/part-of-speech line, the definition, and a short
    /// source credit (the dictionary content is CC BY-SA, so a shared snippet
    /// should say where it came from). Mirrors the Android app's `toShareText()`.
    var shareText: String {
        var text = term
        let subtitle = [pronunciation, partOfSpeech]
            .compactMap { $0 }
            .joined(separator: "  ·  ")
        if !subtitle.isEmpty {
            text += "  " + subtitle
        }
        text += "\n\n" + definition
        text += "\n\n— The Jargon File"
        return text
    }
}
