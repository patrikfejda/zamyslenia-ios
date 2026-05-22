import Foundation
import Observation

struct Bookmark: Codable, Identifiable, Hashable, Sendable {
    let date: String        // "YYYY-MM-DD"
    let section: SectionKind
    let createdAt: Date

    var id: String { "\(date)#\(section.rawValue)" }
}

/// Bookmarks are stored as a JSON-encoded blob in UserDefaults. Volume is tiny
/// (dozens to low hundreds of entries) and we never query across them, so a
/// real database is overkill.
@Observable
final class BookmarksStore {
    private(set) var items: [Bookmark] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isBookmarked(date: String, section: SectionKind) -> Bool {
        items.contains { $0.date == date && $0.section == section }
    }

    func toggle(date: String, section: SectionKind) {
        if let idx = items.firstIndex(where: { $0.date == date && $0.section == section }) {
            items.remove(at: idx)
        } else {
            items.append(Bookmark(date: date, section: section, createdAt: .now))
        }
        save()
    }

    func remove(_ bookmark: Bookmark) {
        items.removeAll { $0.id == bookmark.id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: AppStorageKey.bookmarks),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data)
        else {
            items = []
            return
        }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        items.sort { $0.createdAt > $1.createdAt }
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: AppStorageKey.bookmarks)
    }
}
