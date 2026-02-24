import SwiftUI

struct NetworkView: View {
    @State private var searchText: String = ""
    @State private var animateGlow = false
    
    // Mock Data
    private let profiles = [
        UserProfile(firstName: "Sarah", lastName: "Chen", role: "CEO at Innovate Inc.", location: "", timeZone: ""),
        UserProfile(firstName: "Michael", lastName: "Ross", role: "Founder at FinG", location: "", timeZone: ""),
        UserProfile(firstName: "Jessica", lastName: "Lee", role: "CTO at HealthLink", location: "", timeZone: "")
    ]
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                // Immersive Background
                Color.background.edgesIgnoringSafeArea(.all)
                
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color("TealDark", bundle: nil).opacity(0.15))
                            .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                            .blur(radius: 100)
                            .offset(x: animateGlow ? -100 : 50, y: animateGlow ? 150 : -50)
                        
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: proxy.size.width * 1.2, height: proxy.size.width * 1.2)
                            .blur(radius: 120)
                            .offset(x: animateGlow ? 100 : -100, y: animateGlow ? -200 : -100)
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                            animateGlow = true
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mentor\nNetwork")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                                .lineSpacing(-4)
                            
                            Text("Find the right expert to help you grow.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Glass Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("", text: $searchText)
                                .placeholder(when: searchText.isEmpty) {
                                    Text("Search by name or sector...")
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Content List
                        VStack(spacing: 20) {
                            networkCard(
                                imageName: "",
                                name: "Sarah Chen",
                                role: "CEO at Innovate Inc.",
                                tags: ["Scaling", "Fundraising"]
                            )
                            
                            networkCard(
                                imageName: "",
                                name: "David Miller",
                                role: "Partner at Greylock",
                                tags: ["Investment", "Strategy"]
                            )
                        }
                        .padding(.bottom, 120) // Space for floating tab bar
                    }
                    .padding(.horizontal, 24)
                }
                
                // Status bar blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
    
    @ViewBuilder
    func networkCard(imageName: String, name: String, role: String, tags: [String]) -> some View {
        DashboardCard {
            VStack(spacing: 20) {
                // Top section: Avatar and Info
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text(role)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Tags
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.primary.opacity(0.05), in: Capsule())
                    }
                    Spacer()
                }
                
                // Action Button
                Button(action: {}) {
                    Text("View Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(24)
        }
    }
}

// Helper for search placeholder color
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

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

struct NetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView()
    }
}
