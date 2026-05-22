import Foundation
import SwiftUI

/// Single source of truth for UserDefaults / AppStorage keys.
enum AppStorageKey {
    static let manifestURL          = "manifestURL"
    static let lastSyncAt           = "lastSyncAt"
    static let fontScale            = "fontScale"
    static let colorSchemeOverride  = "colorSchemeOverride"
    static let bookmarks            = "bookmarks"
    static let morningReminderHour  = "morningReminderHour"
    static let morningReminderOn    = "morningReminderOn"
    static let eveningReminderHour  = "eveningReminderHour"
    static let eveningReminderOn    = "eveningReminderOn"
}

enum ColorSchemeOverride: String, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto:  "Podľa systému"
        case .light: "Denný (sépiový)"
        case .dark:  "Nočný"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto:  nil
        case .light: .light
        case .dark:  .dark
        }
    }
}

/// Default manifest URL — overridable in Settings. Pointed at the repo's main
/// branch so the app works out of the box for the maintainer's deploy.
enum AppDefaults {
    static let manifestURL = "https://raw.githubusercontent.com/patrikfejda/zamyslenia-ios/main/content/manifest.json"
    static let fontScale: Double = 1.0
    static let morningReminderHour = 7
    static let eveningReminderHour = 21
}
