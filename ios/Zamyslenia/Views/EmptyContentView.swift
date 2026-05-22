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

/// Shown when the user steps to a date that isn't in the manifest. Rare —
/// arrows in the header normally skip to adjacent available days.
struct MissingDayView: View {
    let date: String
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onOpenCalendar: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(theme.textTertiary)
            Text("Pre \(date) zatiaľ nie sú texty.")
                .font(Typography.body())
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button("Späť", action: onPreviousDay)
                Button("Kalendár", action: onOpenCalendar)
                Button("Ďalej", action: onNextDay)
            }
            .font(Typography.button())
            .foregroundStyle(theme.accent)
            .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
