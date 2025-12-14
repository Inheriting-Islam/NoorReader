// Color+Theme.swift
// NoorReader
//
// App color palette and theme colors

import SwiftUI

extension Color {
    // MARK: - Brand Colors

    /// Primary brand color - Deep teal
    static let noorTeal = Color(hex: "#0D7377")

    /// Secondary brand color - Warm gold
    static let noorGold = Color(hex: "#D4AF37")

    // MARK: - Theme Colors

    /// Day theme background
    static let dayBackground = Color(hex: "#FFFFFF")
    static let dayText = Color(hex: "#1A1A1A")
    static let daySecondary = Color(hex: "#666666")

    /// Sepia theme background
    static let sepiaBackground = Color(hex: "#FFF8F0")
    static let sepiaText = Color(hex: "#5C4033")
    static let sepiaSecondary = Color(hex: "#8B7355")

    /// Night theme background
    static let nightBackground = Color(hex: "#1E2A38")
    static let nightText = Color(hex: "#E8E8E8")
    static let nightSecondary = Color(hex: "#A0A0A0")

    // MARK: - Semantic Colors

    static let noorSuccess = Color(hex: "#2E8B57")
    static let noorWarning = Color(hex: "#E8A838")
    static let noorError = Color(hex: "#DC3545")

    // MARK: - Highlight Colors

    static let highlightYellow = Color(hex: "#FFF3A3")
    static let highlightGreen = Color(hex: "#A8E6CF")
    static let highlightBlue = Color(hex: "#A8D8EA")
    static let highlightPink = Color(hex: "#FFAAA5")
    static let highlightOrange = Color(hex: "#FFD3A5")
    static let highlightPurple = Color(hex: "#D5AAFF")
    static let highlightRed = Color(hex: "#FF8B94")
    static let highlightGray = Color(hex: "#C9C9C9")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
