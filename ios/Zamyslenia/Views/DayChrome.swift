import SwiftUI

/// Container shared by `DayScreen` and `MissingDayView`: provides the
/// minimal top date strip, a slot for the day's body, the bottom toolbar,
/// and a horizontal swipe gesture that pages through calendar days.
///
/// Everything navigation-related (arrows, mode toggle, settings, bookmarks,
/// calendar) lives in the bottom toolbar so the top of the screen stays
/// quiet — just the date and the time-of-day eyebrow.
struct DayContainer<Content: View>: View {
    let dateISO: String
    let mode: DayMode
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void
    let onOpenCalendar: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.theme) private var theme

    /// Threshold for treating a drag as a horizontal swipe — generous enough
    /// to feel intentional, small enough that a flick still pages.
    private let swipeThreshold: CGFloat = 60
    /// How much more horizontal than vertical motion we require before we
    /// treat it as a day swipe (vs. a diagonal scroll).
    private let horizontalDominance: CGFloat = 1.5

    var body: some View {
        VStack(spacing: 0) {
            DayDateStrip(dateISO: dateISO, mode: mode)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            DayFooter(
                mode: mode,
                onPreviousDay: onPreviousDay,
                onNextDay: onNextDay,
                onToggleMode: onToggleMode,
                onOpenSettings: onOpenSettings,
                onOpenBookmarks: onOpenBookmarks,
                onOpenCalendar: onOpenCalendar
            )
        }
        // simultaneousGesture so vertical scroll inside `content()` still
        // wins for primarily-vertical drags.
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    guard abs(h) > swipeThreshold,
                          abs(h) > abs(v) * horizontalDominance
                    else { return }
                    if h < 0 { onNextDay() } else { onPreviousDay() }
                }
        )
    }
}

/// Top of the screen. Just the eyebrow (RÁNO/VEČER) and the formatted date.
/// No tappable elements — chrome lives in the footer.
struct DayDateStrip: View {
    let dateISO: String
    let mode: DayMode

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 6) {
            Text(mode.label.uppercased())
                .font(Typography.headerEyebrow())
                .tracking(2.4)
                .foregroundStyle(theme.accent)
                .contentTransition(.opacity)

            Text(formattedDate)
                .font(Typography.headerDate())
                .foregroundStyle(theme.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: dateISO)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
        .background(theme.background)
    }

    private var formattedDate: String {
        guard let date = DayResolver.parse(isoDate: dateISO) else { return dateISO }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sk_SK")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date).capitalizingFirstLetter()
    }
}

/// Bottom toolbar. Three groups: utility (settings/bookmarks), navigation
/// (prev/mode/next), and calendar. Even spacing keeps it visually balanced.
struct DayFooter: View {
    let mode: DayMode
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void
    let onOpenCalendar: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.divider)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                leftGroup
                Spacer(minLength: 16)
                centerGroup
                Spacer(minLength: 16)
                rightGroup
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(theme.background)
    }

    private var leftGroup: some View {
        HStack(spacing: 22) {
            toolbarButton("gearshape", label: "Nastavenia", action: onOpenSettings, tint: theme.textSecondary)
            toolbarButton("bookmark", label: "Záložky", action: onOpenBookmarks, tint: theme.textSecondary)
        }
    }

    private var centerGroup: some View {
        HStack(spacing: 18) {
            toolbarButton("chevron.left", label: "Predošlý deň", action: onPreviousDay, tint: theme.textSecondary)
            Button(action: onToggleMode) {
                Image(systemName: mode == .morning ? "moon.stars" : "sun.max")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(theme.accent)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 36, height: 32)
            }
            .accessibilityLabel(mode == .morning ? "Prepnúť na večer" : "Prepnúť na ráno")
            toolbarButton("chevron.right", label: "Nasledujúci deň", action: onNextDay, tint: theme.textSecondary)
        }
    }

    private var rightGroup: some View {
        toolbarButton("calendar", label: "Kalendár", action: onOpenCalendar, tint: theme.textSecondary)
    }

    private func toolbarButton(_ system: String, label: String, action: @escaping () -> Void, tint: Color) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 34, height: 32)
        }
        .accessibilityLabel(label)
    }
}

private extension String {
    func capitalizingFirstLetter() -> String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
