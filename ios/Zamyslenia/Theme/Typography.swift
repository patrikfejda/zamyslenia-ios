import SwiftUI

/// Centralised type scale. Serif for long-form (body, prayers, scripture);
/// rounded sans for chrome (header, buttons). All sizes Dynamic Type aware.
enum Typography {
    static func sectionTitle(scale: Double = 1.0) -> Font {
        .system(size: 30 * scale, weight: .semibold, design: .serif)
    }

    static func sectionEyebrow(scale: Double = 1.0) -> Font {
        .system(size: 12 * scale, weight: .medium, design: .rounded).smallCaps()
    }

    static func body(scale: Double = 1.0) -> Font {
        .system(size: 18 * scale, weight: .regular, design: .serif)
    }

    static func scripture(scale: Double = 1.0) -> Font {
        .system(size: 17 * scale, weight: .regular, design: .serif)
    }

    static func quote(scale: Double = 1.0) -> Font {
        .system(size: 22 * scale, weight: .regular, design: .serif).italic()
    }

    static func quoteAuthor(scale: Double = 1.0) -> Font {
        .system(size: 14 * scale, weight: .regular, design: .rounded)
    }

    static func headerDate(scale: Double = 1.0) -> Font {
        .system(size: 17 * scale, weight: .semibold, design: .rounded)
    }

    static func headerEyebrow(scale: Double = 1.0) -> Font {
        .system(size: 11 * scale, weight: .medium, design: .rounded).smallCaps()
    }

    static func button(scale: Double = 1.0) -> Font {
        .system(size: 15 * scale, weight: .medium, design: .rounded)
    }

    static func caption(scale: Double = 1.0) -> Font {
        .system(size: 13 * scale, weight: .regular, design: .rounded)
    }
}
