import CryptoKit
import Foundation
import Observation

/// Owns the on-disk content cache plus the in-memory manifest.
/// Reads are synchronous — day files are small (single-digit KB) so a single
/// disk read per section is fine.
@Observable
final class ContentStore {
    private(set) var manifest: ContentManifest?
    private(set) var loadError: String?

    private let rootURL: URL
    private let manifestURL: URL

    init(rootURL: URL? = nil) {
        let resolved = rootURL ?? Self.defaultRootURL()
        self.rootURL = resolved
        self.manifestURL = resolved.appending(path: "manifest.json")
        loadFromDisk()
    }

    /// `Application Support/ZamysleniaContent/`. Created lazily.
    static func defaultRootURL() -> URL {
        URL.applicationSupportDirectory.appending(path: "ZamysleniaContent", directoryHint: .isDirectory)
    }

    func ensureRootExists() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    func loadFromDisk() {
        do {
            try ensureRootExists()
            guard FileManager.default.fileExists(atPath: manifestURL.path) else {
                manifest = nil
                return
            }
            let data = try Data(contentsOf: manifestURL)
            let decoded = try JSONDecoder().decode(ContentManifest.self, from: data)
            guard decoded.schemaVersion == ContentManifestSchema.currentVersion else {
                loadError = "Neznáma verzia manifestu: \(decoded.schemaVersion). Aktualizuj texty znova."
                manifest = nil
                return
            }
            manifest = decoded
            loadError = nil
        } catch {
            manifest = nil
            loadError = "Lokálny obsah sa nepodarilo načítať: \(error.localizedDescription)"
        }
    }

    func localFileURL(for entry: ManifestEntry) -> URL {
        rootURL.appending(path: entry.path)
    }

    func readText(for entry: ManifestEntry) -> String? {
        let url = localFileURL(for: entry)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// Loads and parses the day for an ISO date, if it is present locally.
    /// Returns nil if the date isn't in the manifest or the file is missing;
    /// throws only on malformed content (which is a content bug, not a
    /// "missing day" — surface it to the user).
    func loadDay(date: String) throws -> DayContent? {
        guard let entry = manifest?.entriesByDate[date] else { return nil }
        guard let raw = readText(for: entry) else { return nil }
        return try DayParser.parse(raw)
    }

    /// Adjacent available date in the manifest, or nil if none. Used by the
    /// header arrows so the user can only step to days that actually exist.
    func adjacentDate(to date: String, direction: Int) -> String? {
        guard let dates = manifest?.sortedDates, !dates.isEmpty else { return nil }
        if direction > 0 {
            return dates.first { $0 > date }
        } else {
            return dates.last { $0 < date }
        }
    }

    func hasDay(date: String) -> Bool {
        manifest?.entriesByDate[date] != nil
    }

    func writeManifest(_ manifest: ContentManifest) throws {
        try ensureRootExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: manifestURL, options: .atomic)
        self.manifest = manifest
    }

    func writeFile(at relativePath: String, data: Data) throws {
        let target = rootURL.appending(path: relativePath)
        let parent = target.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try data.write(to: target, options: .atomic)
    }

    func removeFile(at relativePath: String) {
        let target = rootURL.appending(path: relativePath)
        try? FileManager.default.removeItem(at: target)
    }

    func computedSHA256(at relativePath: String) -> String? {
        let target = rootURL.appending(path: relativePath)
        guard let data = try? Data(contentsOf: target) else { return nil }
        return Self.sha256(data)
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func wipe() {
        try? FileManager.default.removeItem(at: rootURL)
        manifest = nil
        loadError = nil
    }
}
