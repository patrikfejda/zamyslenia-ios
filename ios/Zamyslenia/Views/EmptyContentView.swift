import SwiftUI

/// Shown on first launch (and after a content wipe). Single CTA: sync.
struct EmptyContentView: View {
    @Environment(\.theme) private var theme
    @Environment(ContentSyncService.self) private var sync
    @AppStorage(AppStorageKey.manifestURL) private var manifestURL = AppDefaults.manifestURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(theme.accent)

            VStack(spacing: 8) {
                Text("Zamyslenia")
                    .font(.system(size: 32, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.textPrimary)
                Text("Stiahni si denné texty a čítaj aj bez internetu.")
                    .font(Typography.body())
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if sync.isSyncing {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(theme.accent)
                    if let progress = sync.progress {
                        Text(progressLabel(progress))
                            .font(Typography.caption())
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .padding(.top, 16)
            } else {
                Button {
                    Task { await sync.sync(manifestURLString: manifestURL) }
                } label: {
                    Text("Stiahnuť texty")
                        .font(Typography.button())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.accent)
                        .foregroundStyle(theme.background)
                        .clipShape(Capsule())
                }
                .padding(.top, 16)
            }

            if let error = sync.lastError {
                Text(error)
                    .font(Typography.caption())
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }

            Spacer()
        }
    }

    private func progressLabel(_ p: SyncProgress) -> String {
        switch p.phase {
        case .fetchingManifest: "Sťahujem zoznam dní…"
        case .downloadingDays:  "Sťahujem dni \(p.current + 1)/\(p.total)…"
        case .finalizing:       "Dokončujem…"
        }
    }
}

/// Shown when the header arrows land on a date the user does not have
/// locally. Uses the same `DayContainer` chrome (top strip + bottom toolbar
/// + swipe) so the user can keep navigating, and centers a sync CTA — most
/// "missing" cases are just "not yet pulled".
struct MissingDayView: View {
    let dateISO: String
    let mode: DayMode
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void
    let onOpenBookmarks: () -> Void
    let onOpenCalendar: () -> Void

    @Environment(\.theme) private var theme
    @Environment(ContentSyncService.self) private var sync
    @AppStorage(AppStorageKey.manifestURL) private var manifestURL = AppDefaults.manifestURL

    var body: some View {
        DayContainer(
            dateISO: dateISO,
            mode: mode,
            onPreviousDay: onPreviousDay,
            onNextDay: onNextDay,
            onToggleMode: onToggleMode,
            onOpenSettings: onOpenSettings,
            onOpenBookmarks: onOpenBookmarks,
            onOpenCalendar: onOpenCalendar
        ) {
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(theme.accent)

                VStack(spacing: 8) {
                    Text("Texty pre tento deň nie sú stiahnuté")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Skús aktualizovať texty — možno medzitým pribudol obsah na tento deň.")
                        .font(Typography.body())
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if sync.isSyncing {
                    VStack(spacing: 6) {
                        ProgressView().tint(theme.accent)
                        if let progress = sync.progress {
                            Text(progressLabel(progress))
                                .font(Typography.caption())
                                .foregroundStyle(theme.textTertiary)
                        }
                    }
                } else {
                    Button {
                        Task { await sync.sync(manifestURLString: manifestURL) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Aktualizovať texty")
                        }
                        .font(Typography.button())
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(theme.accent)
                        .foregroundStyle(theme.background)
                        .clipShape(Capsule())
                    }
                }

                if let error = sync.lastError, !sync.isSyncing {
                    Text(error)
                        .font(Typography.caption())
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
    }

    private func progressLabel(_ p: SyncProgress) -> String {
        switch p.phase {
        case .fetchingManifest: "Sťahujem zoznam dní…"
        case .downloadingDays:  "Sťahujem dni \(p.current + 1)/\(p.total)…"
        case .finalizing:       "Dokončujem…"
        }
    }
}
