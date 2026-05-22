import SwiftUI

/// Devotional theme — sepia daylight palette + warm dark night palette.
/// Driven by SwiftUI's environment color scheme; resolves to a single
/// `ResolvedTheme` for views to consume.
struct ResolvedTheme {
    let background: Color
    let surface: Color           // card background (sits on `background`)
    let surfaceMuted: Color      // alt card (toolbar etc.)
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accent: Color
    let accentMuted: Color
    let divider: Color
    let modeIndicator: Color     // dot color in the section indicator
    let modeIndicatorInactive: Color
}

enum Theme {
    /// Resolve palette for the current color scheme. Designed so views call
    /// `@Environment(\.colorScheme)` once and pass the result down.
    static func resolve(_ scheme: ColorScheme) -> ResolvedTheme {
        switch scheme {
        case .dark:  return night
        default:     return day
        }
    }

    // Daylight — warm parchment. Designed for long-form reading, not glare.
    static let day = ResolvedTheme(
        background:            Color(hex: 0xF4EEDE),
        surface:               Color(hex: 0xFBF7EC),
        surfaceMuted:          Color(hex: 0xEDE4CE),
        textPrimary:           Color(hex: 0x2A1F14),
        textSecondary:         Color(hex: 0x5C4A35),
        textTertiary:          Color(hex: 0x8A7657),
        accent:                Color(hex: 0x8B6F47),
        accentMuted:           Color(hex: 0xB89A6F),
        divider:               Color(hex: 0xE0D5B8),
        modeIndicator:         Color(hex: 0x8B6F47),
        modeIndicatorInactive: Color(hex: 0xD6C9A6)
    )

    // Night — deep warm dark. Avoids pure black so OLED contrast doesn't
    // hammer the eyes during evening prayer.
    static let night = ResolvedTheme(
        background:            Color(hex: 0x121316),
        surface:               Color(hex: 0x1B1D22),
        surfaceMuted:          Color(hex: 0x252830),
        textPrimary:           Color(hex: 0xECE3CF),
        textSecondary:         Color(hex: 0xB8AC93),
        textTertiary:          Color(hex: 0x7E7563),
        accent:                Color(hex: 0xCAA76A),
        accentMuted:           Color(hex: 0x8E7847),
        divider:               Color(hex: 0x2C2F36),
        modeIndicator:         Color(hex: 0xCAA76A),
        modeIndicatorInactive: Color(hex: 0x44464E)
    )
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ResolvedTheme = Theme.day
}

extension EnvironmentValues {
    var theme: ResolvedTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
