import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(ContentStore.self) private var store
    @Environment(ContentSyncService.self) private var sync

    @AppStorage(AppStorageKey.manifestURL) private var manifestURL = AppDefaults.manifestURL
    @AppStorage(AppStorageKey.fontScale) private var fontScale: Double = AppDefaults.fontScale
    @AppStorage(AppStorageKey.colorSchemeOverride) private var colorSchemeOverride: ColorSchemeOverride = .auto
    @AppStorage(AppStorageKey.lastSyncAt) private var lastSyncAt: Double = 0

    @State private var draftURL: String = ""

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
            .onAppear { draftURL = manifestURL }
        }
    }

    private var contentSection: some View {
        Section("Obsah") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Zdroj textov (manifest URL)")
                    .font(Typography.caption())
                    .foregroundStyle(theme.textSecondary)
                TextField("https://…/manifest.json", text: $draftURL, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .font(.system(size: 14, design: .monospaced))
                    .onSubmit { commitURL() }
            }
            .listRowBackground(theme.surface)

            HStack {
                Button {
                    commitURL()
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
            .listRowBackground(theme.surface)

            VStack(alignment: .leading) {
                HStack {
                    Text("Veľkosť písma")
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
                Spacer()
                Text(appVersion)
                    .foregroundStyle(theme.textTertiary)
            }
            .listRowBackground(theme.surface)

            Button(role: .destructive) {
                store.wipe()
            } label: {
                Text("Vymazať stiahnuté texty")
            }
            .listRowBackground(theme.surface)
        }
    }

    private func commitURL() {
        let trimmed = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { manifestURL = trimmed }
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
