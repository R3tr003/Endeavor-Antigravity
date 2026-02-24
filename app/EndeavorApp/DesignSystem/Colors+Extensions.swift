import SwiftUI
import UIKit

extension Color {
    // MARK: - Dynamic Color Helper
    private static func dynamicColor(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
    
    // MARK: - Brand Colors
    // Primary: Keep Teal for both, maybe slightly darker for light mode visibility if needed, but user said "keep similar".
    // 00D9C5 is quite bright. On white it might be hard to read text, but as a button bg it's fine.
    static let brandPrimary = dynamicColor(light: "00B8A5", dark: "00D9C5") // Slightly darker for light mode contrast
    
    // Backgrounds
    static let background = dynamicColor(light: "E2E8F0", dark: "0A1628") // Softer grayish-blue Light / Dark Blue Dark
    static let cardBackground = dynamicColor(light: "F1F5F9", dark: "1E2A3A") // Slight off-white Light / Blue Gray Dark
    static let inputBackground = dynamicColor(light: "E2E8F0", dark: "2A3647") // Deepest Gray Input Light / Dark Blue Gray Dark
    static let borderGlare = dynamicColor(light: "0F172A", dark: "FFFFFF") // Very Dark Slate border for light mode, White for dark mode
    
    // Text Colors
    static let textPrimary = dynamicColor(light: "0F172A", dark: "FFFFFF") // Very Dark Slate Light / White Dark
    static let textSecondary = dynamicColor(light: "475569", dark: "8B95A5") // Darker Gray Light (readability) / Gray Dark
    static let textInverted = dynamicColor(light: "FFFFFF", dark: "111827") // For buttons on primary
    
    // Status Colors
    static let success = dynamicColor(light: "059669", dark: "00D98A")
    static let error = dynamicColor(light: "DC2626", dark: "FF4757")
    static let chartAccent = dynamicColor(light: "9333EA", dark: "A855F7")
    
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

// Helper for UIColor initialization from Hex
extension UIColor {
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
