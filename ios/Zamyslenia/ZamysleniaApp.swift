import SwiftUI

@main
struct ZamysleniaApp: App {
    @AppStorage(AppStorageKey.colorSchemeOverride)
    private var colorSchemeOverride: ColorSchemeOverride = .auto

    @State private var contentStore = ContentStore()
    @State private var bookmarks = BookmarksStore()
    @State private var syncService: ContentSyncService

    init() {
        let store = ContentStore()
        _contentStore = State(initialValue: store)
        _syncService = State(initialValue: ContentSyncService(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(contentStore)
                .environment(syncService)
                .environment(bookmarks)
                .preferredColorScheme(colorSchemeOverride.preferredColorScheme)
        }
    }
}
