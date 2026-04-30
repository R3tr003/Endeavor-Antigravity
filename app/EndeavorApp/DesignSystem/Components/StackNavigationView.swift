import SwiftUI

// Simple wrapper to ensure background color covers everything if needed
struct StackNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            content
        }
        .edgesIgnoringSafeArea(.bottom) // Allow scrolling under tab bar
    }
}

// MARK: - Liquid Glass helpers (DesignSystem)

enum GlassShape {
    case capsule
    case roundedRect(cornerRadius: CGFloat)
}

struct GlassSurface: ViewModifier {
    let glass: Glass
    let shape: GlassShape

    func body(content: Content) -> some View {
        switch shape {
        case .capsule:
            content.glassEffect(glass, in: Capsule())
        case .roundedRect(let cornerRadius):
            content.glassEffect(glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

extension View {
    func glassSurface(_ glass: Glass = .regular, shape: GlassShape = .capsule) -> some View {
        modifier(GlassSurface(glass: glass, shape: shape))
    }
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let glass: Glass
    let content: Content

    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.xLarge,
        glass: Glass = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.glass = glass
        self.content = content()
    }

    var body: some View {
        content
            .glassSurface(glass, shape: .roundedRect(cornerRadius: cornerRadius))
    }
}

struct GlassRow<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content

    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.xxLarge,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: cornerRadius))
    }
}
