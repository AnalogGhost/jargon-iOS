import Foundation

/// Picks the same "word of the day" in the app and the widget, with no shared storage:
/// the choice is a pure function of the local calendar day. Only entries with a
/// substantial definition are eligible, so the widget never lands on a one-line
/// "See bit rot." redirect.
enum WordOfTheDay {
    static let minimumDefinitionLength = 120

    static func candidates(_ entries: [DictionaryEntry]) -> [DictionaryEntry] {
        entries.filter { $0.definition.count >= minimumDefinitionLength }
    }

    static func entry(for date: Date, in entries: [DictionaryEntry], calendar: Calendar = .current) -> DictionaryEntry? {
        let pool = candidates(entries)
        guard !pool.isEmpty else { return nil }
        return pool[index(for: dayNumber(for: date, calendar: calendar), count: pool.count)]
    }

    /// Days since 2001-01-01 in the given calendar's time zone, so the word changes at
    /// local midnight rather than UTC midnight.
    static func dayNumber(for date: Date, calendar: Calendar = .current) -> Int {
        let reference = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1)) ?? Date(timeIntervalSinceReferenceDate: 0)
        return calendar.dateComponents([.day], from: reference, to: calendar.startOfDay(for: date)).day ?? 0
    }

    /// Scrambles consecutive days across the pool so successive words aren't
    /// alphabetical neighbours (splitmix64 finalizer).
    static func index(for day: Int, count: Int) -> Int {
        var z = UInt64(bitPattern: Int64(day)) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Int(z % UInt64(count))
    }
}
