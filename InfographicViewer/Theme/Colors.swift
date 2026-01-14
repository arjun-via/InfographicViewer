import SwiftUI

// MARK: - Color Extensions
// Minimal theme for the infographic viewer

extension Color {
    // Background colors
    static let bgPrimary = Color(hex: "0A0A0A")
    static let bgSecondary = Color(hex: "1A1A1A")
    static let bgTertiary = Color(hex: "2A2A2A")
    
    // Text colors
    static let textPrimary = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "A0A0A0")
    static let textTertiary = Color(hex: "606060")
    
    // Accent colors
    static let accentPrimary = Color(hex: "FF6B4A")
    
    // Status colors
    static let success = Color(hex: "4ADE80")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "F87171")
    
    // Hex initializer
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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
