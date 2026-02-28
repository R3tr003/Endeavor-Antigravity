import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var appViewModel: AppViewModel
    
    @StateObject private var conversationsViewModel = ConversationsViewModel()
    
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
                
                // Mentor Discovery
                MentorDiscoveryView()
                    .tag(2)
                
                MessagesView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            .edgesIgnoringSafeArea(.bottom)
            .environmentObject(conversationsViewModel)
            .onAppear {
                conversationsViewModel.startListening()
            }
            
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
                TabItem(icon: "sparkles", title: "Discover", isSelected: selectedTab == 2, selectedIcon: "sparkles") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 2 }
                }
                Spacer()
                TabItem(icon: "message", title: "Messages", isSelected: selectedTab == 3, badgeCount: conversationsViewModel.totalUnreadCount) {
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
                        colors: [Color.borderGlare.opacity(0.3), .clear, Color.borderGlare.opacity(0.1)],
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
    let selectedIcon: String?   // ← opzionale: icona custom per stato selezionato
    let badgeCount: Int
    let action: () -> Void

    @State private var bounceTrigger: Int = 0

    init(icon: String, title: String, isSelected: Bool, selectedIcon: String? = nil, badgeCount: Int = 0, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.selectedIcon = selectedIcon
        self.badgeCount = badgeCount
        self.action = action
    }

    var body: some View {
        Button(action: {
            bounceTrigger += 1
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Image(systemName: isSelected ? (selectedIcon ?? icon + ".fill") : icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .regular))
                        .symbolEffect(.bounce, value: bounceTrigger)

                    Text(title)
                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(isSelected ? .brandPrimary : .primary.opacity(0.5))
                .frame(width: DesignSystem.Layout.buttonHeight)
                
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 10, y: -5)
                }
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppViewModel())
    }
}
