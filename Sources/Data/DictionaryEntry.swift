import Foundation

struct DictionaryEntry: Codable, Identifiable, Equatable {
    let id: String
    let term: String
    let sortKey: String
    let pronunciation: String?
    let partOfSpeech: String?
    let definition: String
    let etymology: String?
    let history: String?
    let seeAlso: [String]

    init(
        id: String,
        term: String,
        sortKey: String,
        pronunciation: String? = nil,
        partOfSpeech: String? = nil,
        definition: String,
        etymology: String? = nil,
        history: String? = nil,
        seeAlso: [String] = []
    ) {
        self.id = id
        self.term = term
        self.sortKey = sortKey
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.etymology = etymology
        self.history = history
        self.seeAlso = seeAlso
    }
}
