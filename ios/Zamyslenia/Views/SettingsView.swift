import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ContentStore.self) private var store
    @Environment(ContentSyncService.self) private var sync

    @AppStorage(AppStorageKey.manifestURL) private var manifestURL = AppDefaults.manifestURL
    @AppStorage(AppStorageKey.fontScale) private var fontScale: Double = AppDefaults.fontScale
    @AppStorage(AppStorageKey.colorSchemeOverride) private var colorSchemeOverride: ColorSchemeOverride = .auto
    @AppStorage(AppStorageKey.lastSyncAt) private var lastSyncAt: Double = 0

    @State private var showWipeConfirm = false

    // Resolve theme inside the sheet so it reacts to the override picker
    // immediately, without having to close and re-open settings.
    private var theme: ResolvedTheme { Theme.resolve(colorScheme) }

    var body: some View {
        NavigationStack {
            Form {
                contentSection
                appearanceSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Nastavenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") { dismiss() }
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .environment(\.theme, theme)
        .preferredColorScheme(colorSchemeOverride.preferredColorScheme)
        .confirmationDialog(
            "Vymazať všetky stiahnuté texty?",
            isPresented: $showWipeConfirm,
            titleVisibility: .visible
        ) {
            Button("Vymazať", role: .destructive) {
                store.wipe()
                dismiss()
            }
            Button("Zrušiť", role: .cancel) {}
        } message: {
            Text("Texty bude treba znova stiahnuť cez Aktualizovať texty.")
        }
    }

    private var contentSection: some View {
        Section("Obsah") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Zdroj textov (manifest URL)")
                    .font(Typography.caption())
                    .foregroundStyle(theme.textSecondary)
                TextField("https://…/manifest.json", text: $manifestURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.done)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                if manifestURL != AppDefaults.manifestURL {
                    Button("Vrátiť predvolenú URL") {
                        manifestURL = AppDefaults.manifestURL
                    }
                    .font(Typography.caption())
                    .foregroundStyle(theme.accent)
                }
            }
            .listRowBackground(theme.surface)

            HStack {
                Button {
                    Task { await sync.sync(manifestURLString: manifestURL) }
                } label: {
                    HStack {
                        if sync.isSyncing { ProgressView().tint(theme.accent) }
                        Text(sync.isSyncing ? "Aktualizujem…" : "Aktualizovať texty")
                    }
                }
                .disabled(sync.isSyncing)
                .foregroundStyle(theme.accent)
                Spacer()
                if lastSyncAt > 0 {
                    Text(lastSyncLabel)
                        .font(Typography.caption())
                        .foregroundStyle(theme.textTertiary)
                }
            }
            .listRowBackground(theme.surface)

            if let error = sync.lastError {
                Text(error)
                    .font(Typography.caption())
                    .foregroundStyle(.red)
                    .listRowBackground(theme.surface)
            }
        }
    }

    private var appearanceSection: some View {
        Section("Vzhľad") {
            Picker("Režim farieb", selection: $colorSchemeOverride) {
                ForEach(ColorSchemeOverride.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .foregroundStyle(theme.textPrimary)
            .listRowBackground(theme.surface)

            VStack(alignment: .leading) {
                HStack {
                    Text("Veľkosť písma")
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text("\(Int(fontScale * 100))%")
                        .foregroundStyle(theme.textSecondary)
                }
                Slider(value: $fontScale, in: 0.85...1.5, step: 0.05)
                    .tint(theme.accent)
            }
            .listRowBackground(theme.surface)
        }
    }

    private var aboutSection: some View {
        Section("Informácie") {
            HStack {
                Text("Verzia")
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(appVersion)
                    .foregroundStyle(theme.textTertiary)
            }
            .listRowBackground(theme.surface)

            Button(role: .destructive) {
                showWipeConfirm = true
            } label: {
                Text("Vymazať stiahnuté texty")
            }
            .listRowBackground(theme.surface)
        }
    }

    private var lastSyncLabel: String {
        let date = Date(timeIntervalSince1970: lastSyncAt)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "sk_SK")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }
}
