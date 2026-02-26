import SwiftUI

struct DashboardCard<Content: View>: View {
    let content: Content
    
    // Add a simple interaction state for micro-animation
    @State private var isPressed: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(24)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            // Dark: bagliore bianco superiore. Light: accent teal sottile.
                            colorScheme == .dark ? .white.opacity(0.3) : Color.brandPrimary.opacity(0.3),
                            colorScheme == .dark ? .clear : Color.brandPrimary.opacity(0.05),
                            colorScheme == .dark ? .white.opacity(0.1) : Color.brandPrimary.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.08)
                : Color.black.opacity(0.12),  // più definita in light
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: colorScheme == .dark ? 6 : 3
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 100, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct DashboardCard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Impact Score")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("8.7/10")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("+0.5 this month")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        // Adding a gradient background to preview the glass effect
        .background(
            LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
