import Foundation

/// Eight fixed sections per day, four morning + four evening. The ordering
/// here is the canonical reading order shown in the UI.
enum SectionKind: String, CaseIterable, Codable, Sendable {
    case morningPrayer       = "morning.prayer"
    case morningScripture    = "morning.scripture"
    case morningComment      = "morning.comment"
    case morningThought      = "morning.thought"
    case eveningPrayer       = "evening.prayer"
    case eveningExamination  = "evening.examination"
    case eveningPsalm        = "evening.psalm"
    case eveningWord         = "evening.word"

    var mode: DayMode {
        switch self {
        case .morningPrayer, .morningScripture, .morningComment, .morningThought:
            return .morning
        case .eveningPrayer, .eveningExamination, .eveningPsalm, .eveningWord:
            return .evening
        }
    }

    var title: String {
        switch self {
        case .morningPrayer:      "Modlitba"
        case .morningScripture:   "Sväté písmo"
        case .morningComment:     "Komentár"
        case .morningThought:     "Myšlienka"
        case .eveningPrayer:      "Modlitba"
        case .eveningExamination: "Svedomie"
        case .eveningPsalm:       "Žalm"
        case .eveningWord:        "Slovko"
        }
    }
}

enum DayMode: String, CaseIterable, Codable, Sendable {
    case morning, evening

    var label: String {
        switch self {
        case .morning: "Ráno"
        case .evening: "Večer"
        }
    }

    var sections: [SectionKind] {
        switch self {
        case .morning: [.morningPrayer, .morningScripture, .morningComment, .morningThought]
        case .evening: [.eveningPrayer, .eveningExamination, .eveningPsalm, .eveningWord]
        }
    }

    var opposite: DayMode { self == .morning ? .evening : .morning }
}

/// One parsed day. The frontmatter map is preserved as-is for any keys the
/// app doesn't yet consume — adding a new key in the content repo can ship
/// without an app update.
struct DayContent: Equatable, Sendable {
    let date: String                            // "YYYY-MM-DD"
    let feast: String?
    let season: String?
    let scriptureRef: String?
    let thoughtAuthor: String?
    let sections: [SectionKind: String]
    let frontmatter: [String: String?]

    func text(for kind: SectionKind) -> String {
        sections[kind] ?? ""
    }
}
