import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Hide native tab bar helper for iOS 16+
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.edgesIgnoringSafeArea(.all)
            
            // Content
            TabView(selection: $selectedTab) {
                // Ensure the content scrolls under the floating tab bar by adding bottom padding internally if needed,
                // or letting it just underlap.
                HomeView()
                    .tag(0)
                
                NetworkView()
                    .tag(1)
                
                // AI Guide (Placeholder)
                ZStack {
                    Color.background.edgesIgnoringSafeArea(.all)
                    VStack {
                        Spacer()
                        Text("AI Guide Coming Soon")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                }
                .tag(2)
                
                GrowthView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // Floating Liquid Glass Tab Bar
            HStack(spacing: 0) {
                TabItem(icon: "house", title: "Home", isSelected: selectedTab == 0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 0 }
                }
                Spacer()
                TabItem(icon: "person.3", title: "Network", isSelected: selectedTab == 1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 1 }
                }
                Spacer()
                TabItem(icon: "sparkles", title: "AI Guide", isSelected: selectedTab == 2) { // Changed icon to 'sparkles' for AI
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 2 }
                }
                Spacer()
                TabItem(icon: "chart.bar", title: "Growth", isSelected: selectedTab == 3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 3 }
                }
                Spacer()
                TabItem(icon: "person", title: "Profile", isSelected: selectedTab == 4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 4 }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, 0) // Sit right above the home indicator
        }
    }
}

// Custom Floating Tab Item
struct TabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                // Animated icon
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                    .symbolEffect(.bounce, value: isSelected) // iOS 17+ subtle micro-interaction
                
                // Optional: show text only if selected or always show text
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .brandPrimary : .primary.opacity(0.5))
            .frame(width: DesignSystem.Layout.buttonHeight) // Fixed width to prevent shifting when text bold state changes
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppViewModel())
    }
}
