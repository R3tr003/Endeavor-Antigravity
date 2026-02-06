import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.edgesIgnoringSafeArea(.all)
            
            // Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                NetworkView()
                    .tag(1)
                
                // AI Guide (Placeholder)
                ZStack {
                    Color.background.edgesIgnoringSafeArea(.all)
                    Text("AI Guide Coming Soon")
                        .font(.branding.cardTitle)
                        .foregroundColor(.textPrimary)
                }
                .tag(2)
                
                GrowthView()
                    .tag(3)
                
                ProfileView()
                    .tag(4)
            }
            // Hiding standard tab bar to use custom one if needed, 
            // but for simplicity and native behavior we can use .toolbar or standard TabView
            // However, spec asks for "custom tab bar" behavior/look.
            // Using standard TabView with UITabBarAppearance is usually safer, 
            // but for exact "5 tab icons equalized" and specific colors, standard might work.
            // Let's customize the standard one via init() in App or here.
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color.background)
                appearance.shadowColor = UIColor(Color.textSecondary.opacity(0.1)) // Border top
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            .tabViewStyle(DefaultTabViewStyle())
            
            // Custom Tab Bar Overlay (Creating a custom one to ensure exact spec match)
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    TabItem(icon: "house", title: "Home", isSelected: selectedTab == 0) { selectedTab = 0 }
                    TabItem(icon: "person.3", title: "Network", isSelected: selectedTab == 1) { selectedTab = 1 }
                    TabItem(icon: "lightbulb", title: "AI Guide", isSelected: selectedTab == 2) { selectedTab = 2 } // "AI Guide" is long, might need spacing check
                    TabItem(icon: "chart.bar", title: "Growth", isSelected: selectedTab == 3) { selectedTab = 3 }
                    TabItem(icon: "person", title: "Profile", isSelected: selectedTab == 4) { selectedTab = 4 }
                }
                .padding(.top, 12)
                .padding(.bottom, 34) // Safe area
                .background(Color.background)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.textSecondary.opacity(0.2)),
                    alignment: .top
                )
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// Custom Tab Item logic avoiding standard TabView limitations
struct TabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .brandPrimary : .textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppViewModel())
    }
}
