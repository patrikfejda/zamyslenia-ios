import SwiftUI

/// Sticky chrome above the day: date with arrows, current mode (eyebrow),
/// mode toggle (sun/moon), and an overflow menu for Settings / Bookmarks /
/// Calendar. Designed to feel quiet — minimal lines, no boxed buttons.
struct DayHeader: View {
    let day: DayContent
    let mode: DayMode
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void
    let onOpenCalendar: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 8) {
            topRow
            dateRow
            Rectangle()
                .fill(theme.divider)
                .frame(height: 0.5)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(theme.background)
    }

    private var topRow: some View {
        HStack(spacing: 16) {
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .accessibilityLabel("Nastavenia")

            Button(action: onOpenBookmarks) {
                Image(systemName: "bookmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .accessibilityLabel("Záložky")

            Spacer()

            Text(mode.label.uppercased())
                .font(Typography.headerEyebrow())
                .tracking(2.0)
                .foregroundStyle(theme.accent)

            Spacer()

            Button(action: onOpenCalendar) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
            }
            .accessibilityLabel("Kalendár")

            Button(action: onToggleMode) {
                Image(systemName: mode == .morning ? "moon.stars" : "sun.max")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(mode == .morning ? "Prepnúť na večer" : "Prepnúť na ráno")
        }
    }

    private var dateRow: some View {
        HStack(spacing: 0) {
            Button(action: onPreviousDay) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .padding(8)
            }
            .accessibilityLabel("Predošlý deň")

            Spacer()

            Text(formattedDate)
                .font(Typography.headerDate())
                .foregroundStyle(theme.textPrimary)
                .animation(.easeInOut(duration: 0.2), value: day.date)
                .contentTransition(.numericText())

            Spacer()

            Button(action: onNextDay) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                    .padding(8)
            }
            .accessibilityLabel("Nasledujúci deň")
        }
    }

    private var formattedDate: String {
        guard let date = DayResolver.parse(isoDate: day.date) else { return day.date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sk_SK")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date).capitalizingFirstLetter()
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
