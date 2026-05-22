import SwiftUI

/// One day, one mode. Vertical scroll of four section cards. Sticky header
/// with date navigation, mode toggle, and overflow actions.
struct DayScreen: View {
    let day: DayContent
    let mode: DayMode
    let fontScale: Double
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void
    let onOpenCalendar: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            DayHeader(
                day: day,
                mode: mode,
                onPreviousDay: onPreviousDay,
                onNextDay: onNextDay,
                onToggleMode: onToggleMode,
                onOpenSettings: onOpenSettings,
                onOpenBookmarks: onOpenBookmarks,
                onOpenCalendar: onOpenCalendar
            )

            ScrollView {
                VStack(spacing: 36) {
                    ForEach(Array(mode.sections.enumerated()), id: \.element) { index, kind in
                        SectionCard(
                            day: day,
                            kind: kind,
                            index: index,
                            total: mode.sections.count,
                            fontScale: fontScale
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 64)
            }
            .scrollIndicators(.hidden)
        }
        .id("\(day.date)-\(mode.rawValue)")  // re-mount on day/mode change for clean transitions
        .transition(.opacity)
    }
}

/// Single section as a long-form reading card. Tappable bookmark + share
/// button in a small action row. No card chrome — we let the typography
/// carry the visual hierarchy.
struct SectionCard: View {
    let day: DayContent
    let kind: SectionKind
    let index: Int
    let total: Int
    let fontScale: Double

    @Environment(\.theme) private var theme
    @Environment(BookmarksStore.self) private var bookmarks

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Eyebrow: "I / IV  ·  RÁNO"
            HStack(spacing: 8) {
                Text("\(romanNumeral(index + 1)) / \(romanNumeral(total))")
                    .font(Typography.sectionEyebrow(scale: fontScale))
                    .tracking(1.2)
                    .foregroundStyle(theme.textTertiary)
                Text("·")
                    .foregroundStyle(theme.textTertiary)
                Text(kind.mode.label)
                    .font(Typography.sectionEyebrow(scale: fontScale))
                    .tracking(1.2)
                    .foregroundStyle(theme.textTertiary)
                Spacer()
            }

            // Title
            Text(kind.title)
                .font(Typography.sectionTitle(scale: fontScale))
                .foregroundStyle(theme.textPrimary)

            // Optional context line (Scripture ref, thought author)
            if let line = contextLine {
                Text(line)
                    .font(Typography.caption(scale: fontScale))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.top, -6)
            }

            Rectangle()
                .fill(theme.accentMuted.opacity(0.5))
                .frame(width: 36, height: 1)
                .padding(.vertical, 4)

            // Body
            Text(day.text(for: kind))
                .font(textFont)
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(7)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(kind == .morningThought ? .center : .leading)

            actionRow
        }
        .padding(.vertical, 8)
    }

    private var contextLine: String? {
        switch kind {
        case .morningScripture: day.scriptureRef
        case .morningThought:   day.thoughtAuthor
        case .eveningPsalm:     nil
        default:                nil
        }
    }

    private var textFont: Font {
        switch kind {
        case .morningThought:   Typography.quote(scale: fontScale)
        case .morningScripture, .eveningPsalm: Typography.scripture(scale: fontScale)
        default:                Typography.body(scale: fontScale)
        }
    }

    private var actionRow: some View {
        let isBookmarked = bookmarks.isBookmarked(date: day.date, section: kind)
        return HStack(spacing: 18) {
            Button {
                bookmarks.toggle(date: day.date, section: kind)
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isBookmarked ? theme.accent : theme.textTertiary)
            }
            .accessibilityLabel(isBookmarked ? "Odstrániť záložku" : "Pridať záložku")

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.textTertiary)
            }
            .accessibilityLabel("Zdieľať")

            Button {
                UIPasteboard.general.string = shareText
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.textTertiary)
            }
            .accessibilityLabel("Kopírovať")

            Spacer()
        }
        .padding(.top, 12)
    }

    private var shareText: String {
        let header = "\(kind.title) — \(day.date)"
        return "\(header)\n\n\(day.text(for: kind))"
    }

    private func romanNumeral(_ n: Int) -> String {
        ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][safe: n - 1] ?? "\(n)"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
