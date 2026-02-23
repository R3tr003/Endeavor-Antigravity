import SwiftUI

struct DashboardCard<Content: View>: View {
    let content: Content
    
    // Add a simple interaction state for micro-animation
    @State private var isPressed: Bool = false
    
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
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
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
