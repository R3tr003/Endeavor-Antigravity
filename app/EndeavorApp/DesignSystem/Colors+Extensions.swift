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
    // Brand Primary
    static let brandPrimary = dynamicColor(light: "00A896", dark: "00D9C5")
    // Più scuro del teal originale per contrasto WCAG AA su sfondo bianco
    
    // Backgrounds
    static let background = dynamicColor(light: "EFF5F4", dark: "0A1628")
    // Leggera tinta teal-fredda — non bianco puro, non grigio, distinguibile dalle card
    
    static let cardBackground = dynamicColor(light: "FFFFFF", dark: "1E2A3A")
    // Bianco puro — si stacca nettamente da EFF5F4
    
    static let inputBackground = dynamicColor(light: "E0F0EE", dark: "2A3647")
    // Tinta acqua-teal leggermente più satura — riconoscibile come area di input,
    // diversa sia dal background (EFF5F4) che dalle card (FFFFFF)
    
    static let borderGlare = dynamicColor(light: "00A896", dark: "FFFFFF")
    // Teal al posto del bianco. Tutti i bordi `.white.opacity(0.15)` diventano
    // automaticamente bordi teal sottili — identità Endeavor senza toccare le view
    
    // Text Colors — invariati, già corretti
    static let textPrimary = dynamicColor(light: "0F172A", dark: "FFFFFF")
    static let textSecondary = dynamicColor(light: "475569", dark: "8B95A5")
    static let textInverted = dynamicColor(light: "FFFFFF", dark: "111827")
    
    // Status Colors — invariati
    static let success = dynamicColor(light: "059669", dark: "00D98A")
    static let error = dynamicColor(light: "DC2626", dark: "FF4757")
    static let chartAccent = dynamicColor(light: "7C3AED", dark: "A855F7")
    
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

// MARK: - Scroll Preference Key
// Reusable preference key for scroll offset tracking across different views
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
