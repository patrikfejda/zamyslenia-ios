import Foundation

/// Schema for `manifest.json`. Bump when the on-disk format changes; the parser
/// must then explicitly reject older payloads instead of best-effort decoding.
enum ContentManifestSchema {
    static let currentVersion = 1
}

struct ManifestEntry: Codable, Identifiable, Hashable, Sendable {
    let date: String            // "YYYY-MM-DD"
    let path: String            // "days/YYYY/MM/DD.md"
    let sha256: String
    let size: Int
    let feast: String?
    let season: String?

    var id: String { date }
}

struct ContentManifest: Codable, Sendable {
    let schemaVersion: Int
    let title: String?
    let generatedAt: String?
    let entries: [ManifestEntry]

    /// Entries indexed by ISO date for O(1) lookup.
    var entriesByDate: [String: ManifestEntry] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.date, $0) })
    }

    var sortedDates: [String] {
        entries.map(\.date).sorted()
    }
}
