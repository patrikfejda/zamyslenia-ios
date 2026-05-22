import Foundation
import Observation

enum SyncError: LocalizedError {
    case invalidURL
    case manifestFetchFailed(Int)
    case manifestDecodeFailed(String)
    case unsupportedSchemaVersion(Int)
    case fileFetchFailed(path: String, status: Int)
    case hashMismatch(path: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Neplatná URL manifestu. Skontroluj nastavenia."
        case .manifestFetchFailed(let status):
            "Nepodarilo sa stiahnuť manifest (HTTP \(status))."
        case .manifestDecodeFailed(let detail):
            "Chyba v manifeste: \(detail)"
        case .unsupportedSchemaVersion(let version):
            "Manifest má neznámu verziu \(version). Aktualizuj appku."
        case .fileFetchFailed(let path, let status):
            "Nepodarilo sa stiahnuť \(path) (HTTP \(status))."
        case .hashMismatch(let path):
            "Stiahnutý súbor \(path) má nesprávny hash."
        }
    }
}

struct SyncProgress: Sendable {
    let phase: Phase
    let current: Int
    let total: Int

    enum Phase: String, Sendable {
        case fetchingManifest
        case downloadingDays
        case finalizing
    }
}

/// Manifest → diff → download flow. Stateless beyond the `ContentStore` it
/// writes into; instantiate per app, sync any number of times.
@Observable
final class ContentSyncService {
    private(set) var isSyncing: Bool = false
    private(set) var progress: SyncProgress?
    private(set) var lastError: String?

    private let store: ContentStore
    private let session: URLSession

    init(store: ContentStore, session: URLSession = .shared) {
        self.store = store
        self.session = session
    }

    func sync(manifestURLString: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        lastError = nil
        defer { isSyncing = false; progress = nil }

        do {
            try await performSync(manifestURLString: manifestURLString)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: AppStorageKey.lastSyncAt)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func performSync(manifestURLString: String) async throws {
        guard let manifestURL = URL(string: manifestURLString) else { throw SyncError.invalidURL }
        let baseURL = manifestURL.deletingLastPathComponent()

        progress = SyncProgress(phase: .fetchingManifest, current: 0, total: 1)
        let remote = try await fetchManifest(from: manifestURL)
        guard remote.schemaVersion == ContentManifestSchema.currentVersion else {
            throw SyncError.unsupportedSchemaVersion(remote.schemaVersion)
        }

        let toDownload = entriesNeedingDownload(remote: remote, local: store.manifest)

        for (index, entry) in toDownload.enumerated() {
            progress = SyncProgress(phase: .downloadingDays, current: index, total: toDownload.count)
            try await downloadEntry(entry, baseURL: baseURL)
        }

        progress = SyncProgress(phase: .finalizing, current: toDownload.count, total: toDownload.count)
        removeStaleFiles(remote: remote, local: store.manifest)
        try store.writeManifest(remote)
    }

    private func fetchManifest(from url: URL) async throws -> ContentManifest {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw SyncError.manifestFetchFailed(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(ContentManifest.self, from: data)
        } catch {
            throw SyncError.manifestDecodeFailed(String(describing: error))
        }
    }

    private func entriesNeedingDownload(
        remote: ContentManifest,
        local: ContentManifest?
    ) -> [ManifestEntry] {
        let localBySha = Dictionary(
            uniqueKeysWithValues: (local?.entries ?? []).map { ($0.path, $0.sha256) }
        )
        return remote.entries.filter { entry in
            guard let existingSha = localBySha[entry.path] else { return true }
            if existingSha != entry.sha256 { return true }
            // sha matches in manifest, but verify the file actually exists on disk
            return store.computedSHA256(at: entry.path) != entry.sha256
        }
    }

    private func downloadEntry(_ entry: ManifestEntry, baseURL: URL) async throws {
        let fileURL = baseURL.appending(path: entry.path)
        let (data, response) = try await session.data(from: fileURL)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw SyncError.fileFetchFailed(path: entry.path, status: http.statusCode)
        }
        let computed = ContentStore.sha256(data)
        guard computed == entry.sha256 else {
            throw SyncError.hashMismatch(path: entry.path)
        }
        try store.writeFile(at: entry.path, data: data)
    }

    private func removeStaleFiles(remote: ContentManifest, local: ContentManifest?) {
        guard let local else { return }
        let remotePaths = Set(remote.entries.map(\.path))
        for entry in local.entries where !remotePaths.contains(entry.path) {
            store.removeFile(at: entry.path)
        }
    }
}
