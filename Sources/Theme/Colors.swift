import SwiftUI

enum JargonColors {
    static let terminalGreen = Color(red: 0x1B / 255, green: 0x5E / 255, blue: 0x20 / 255)

    // Light scheme
    static let primaryLight = terminalGreen
    static let onPrimaryLight = Color.white
    static let backgroundLight = Color(red: 0xFA / 255, green: 0xFA / 255, blue: 0xFA / 255)
    static let surfaceLight = Color.white
    static let onBackgroundLight = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1A / 255)

    // Dark scheme
    static let primaryDark = Color(red: 0x81 / 255, green: 0xC7 / 255, blue: 0x84 / 255)
    static let onPrimaryDark = Color(red: 0x00 / 255, green: 0x39 / 255, blue: 0x0B / 255)
    static let backgroundDark = Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x12 / 255)
    static let surfaceDark = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255)
    static let onBackgroundDark = Color(red: 0xE8 / 255, green: 0xE8 / 255, blue: 0xE8 / 255)
}

extension Color {
    static var jargonPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(JargonColors.primaryDark)
                : UIColor(JargonColors.primaryLight)
        })
    }
}
