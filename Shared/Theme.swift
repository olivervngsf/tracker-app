import SwiftUI

/// The whole color system: paper, ink, two greys and one orange for "today".
struct Palette {
    let paper: Color
    let ink: Color
    let muted: Color
    let faint: Color
    let line: Color
    let accent: Color

    static let light = Palette(
        paper: Color(hex: 0xE8E6E1),
        ink: Color(hex: 0x141413),
        muted: Color(hex: 0x5F5D58),
        faint: Color(hex: 0xC9C6BF),
        line: Color(hex: 0xCFCCC5),
        accent: Color(hex: 0xE0703A)
    )

    static let dark = Palette(
        paper: Color(hex: 0x000000),
        ink: Color(hex: 0xFFFFFF),
        muted: Color(hex: 0xB4B4B4),
        faint: Color(hex: 0x4A4A4A),
        line: Color(hex: 0x2C2C2C),
        accent: Color(hex: 0xE0703A)
    )

    static func of(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.light
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

extension Animation {
    /// The one spring used for dots, buttons and numbers.
    static let dot = Animation.spring(response: 0.34, dampingFraction: 0.62)
}
