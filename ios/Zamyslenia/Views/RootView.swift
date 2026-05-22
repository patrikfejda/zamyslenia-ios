import SwiftUI

/// Top-level orchestrator: resolves which day+mode to show, manages user
/// navigation (day arrows, mode toggle), exposes Settings/Bookmarks/Calendar.
/// Holds the navigation state so the children stay stateless.
struct RootView: View {
    @Environment(ContentStore.self) private var store
    @Environment(ContentSyncService.self) private var sync
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(AppStorageKey.manifestURL) private var manifestURL = AppDefaults.manifestURL
    @AppStorage(AppStorageKey.fontScale) private var fontScale: Double = AppDefaults.fontScale

    @State private var currentDate: String = DayResolver.resolve().date
    @State private var mode: DayMode = DayResolver.resolve().mode

    @State private var showSettings = false
    @State private var showBookmarks = false
    @State private var showCalendar = false

    private var theme: ResolvedTheme { Theme.resolve(colorScheme) }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            content
        }
        .environment(\.theme, theme)
        .task {
            // First launch: nothing cached → kick off a sync. Skip the
            // network call when we already have something to render.
            if store.manifest == nil {
                await sync.sync(manifestURLString: manifestURL)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.theme, theme)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(onOpen: { bookmark in
                currentDate = bookmark.date
                mode = bookmark.section.mode
                showBookmarks = false
            })
            .environment(\.theme, theme)
        }
        .sheet(isPresented: $showCalendar) {
            HistoryCalendarView(selectedDate: currentDate) { date in
                currentDate = date
                showCalendar = false
            }
            .environment(\.theme, theme)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.manifest == nil {
            EmptyContentView()
        } else if let day = try? store.loadDay(date: currentDate) {
            DayScreen(
                day: day,
                mode: mode,
                fontScale: fontScale,
                onPreviousDay: { stepDay(-1) },
                onNextDay: { stepDay(+1) },
                onToggleMode: { withAnimation(.easeInOut) { mode = mode.opposite } },
                onOpenSettings: { showSettings = true },
                onOpenBookmarks: { showBookmarks = true },
                onOpenCalendar: { showCalendar = true }
            )
        } else {
            MissingDayView(
                date: currentDate,
                onPreviousDay: { stepDay(-1) },
                onNextDay: { stepDay(+1) },
                onOpenCalendar: { showCalendar = true }
            )
        }
    }

    /// Step to the next/previous *available* day so the user never lands on a
    /// day with no content.
    private func stepDay(_ direction: Int) {
        if let next = store.adjacentDate(to: currentDate, direction: direction) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentDate = next
            }
        }
    }
}
