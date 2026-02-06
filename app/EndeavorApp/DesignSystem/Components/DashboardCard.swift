import SwiftUI

struct DashboardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.cardBackground, Color.cardBackground.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
    }
}

struct DashboardCard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Impact Score")
                    .font(.branding.inputLabel)
                    .foregroundColor(.textSecondary)
                Text("8.7/10")
                    .font(.branding.scoreLarge)
                    .foregroundColor(.textPrimary)
                Text("+0.5 this month")
                    .font(.branding.inputLabel)
                    .foregroundColor(.success)
            }
        }
        .padding()
        .background(Color.background)
    }
}
