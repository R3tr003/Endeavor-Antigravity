import Foundation
import CoreGraphics

public struct DesignSystem {
    public struct Spacing {
        public static let xxSmall: CGFloat = 4
        public static let xSmall: CGFloat = 8
        public static let small: CGFloat = 12
        public static let standard: CGFloat = 16
        public static let medium: CGFloat = 20
        public static let large: CGFloat = 24
        public static let xLarge: CGFloat = 32
        public static let xxLarge: CGFloat = 40
        public static let xxxLarge: CGFloat = 48
        public static let massive: CGFloat = 64
        public static let bottomSafePadding: CGFloat = 120
    }
    
    public struct CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let xLarge: CGFloat = 24
        public static let circle: CGFloat = 100
    }
    
    public struct Layout {
        public static let buttonHeight: CGFloat = 50
        public static let largeButtonHeight: CGFloat = 56
        public static let inputHeight: CGFloat = 50
        public static let navBarHeight: CGFloat = 65
    }
    
    public struct IconSize {
        public static let small: CGFloat = 16
        public static let standard: CGFloat = 24
        public static let large: CGFloat = 32
        public static let xLarge: CGFloat = 48
        public static let profileMassive: CGFloat = 100
    }
}
