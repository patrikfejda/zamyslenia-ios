import SwiftUI

struct BookmarksView: View {
    let onOpen: (Bookmark) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(BookmarksStore.self) private var bookmarks
    @Environment(ContentStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if bookmarks.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .background(theme.background)
            .navigationTitle("Záložky")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") { dismiss() }
                        .foregroundStyle(theme.accent)
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(bookmarks.items) { item in
                Button { onOpen(item) } label: {
                    BookmarkRow(item: item, preview: preview(for: item))
                }
                .listRowBackground(theme.surface)
            }
            .onDelete { indexSet in
                indexSet.map { bookmarks.items[$0] }.forEach(bookmarks.remove)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(theme.textTertiary)
            Text("Zatiaľ žiadne záložky.")
                .font(Typography.body())
                .foregroundStyle(theme.textSecondary)
            Text("Pri ľubovoľnej modlitbe alebo úryvku ťukni na ikonu záložky.")
                .font(Typography.caption())
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    /// Best-effort first line of the bookmarked section. Returns "" if the
    /// day isn't cached locally; that path is rare (manifest entry without
    /// content file) so we silently fall back.
    private func preview(for bookmark: Bookmark) -> String {
        guard let day = try? store.loadDay(date: bookmark.date) else { return "" }
        let text = day.text(for: bookmark.section)
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? ""
        return firstLine
    }
}

private struct BookmarkRow: View {
    let item: Bookmark
    let preview: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.section.title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.textPrimary)
                Text("·")
                    .foregroundStyle(theme.textTertiary)
                Text(item.section.mode.label)
                    .font(Typography.caption())
                    .foregroundStyle(theme.accent)
                Spacer()
                Text(item.date)
                    .font(Typography.caption())
                    .foregroundStyle(theme.textTertiary)
            }
            if !preview.isEmpty {
                Text(preview)
                    .font(Typography.caption())
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
