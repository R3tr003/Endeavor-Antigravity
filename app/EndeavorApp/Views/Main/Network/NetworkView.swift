import SwiftUI

struct NetworkView: View {
    @State private var searchText: String = ""
    
    // Mock Data
    private let profiles = [
        UserProfile(firstName: "Sarah", lastName: "Chen", role: "CEO at Innovate Inc.", location: "", timeZone: ""),
        UserProfile(firstName: "Michael", lastName: "Ross", role: "Founder at FinG", location: "", timeZone: ""),
        UserProfile(firstName: "Jessica", lastName: "Lee", role: "CTO at HealthLink", location: "", timeZone: "")
    ]
    
    var body: some View {
        StackNavigationView { // Helper for navigation bar
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mentor & Entrepreneur Network")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Find the right expert to help you grow.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("", text: $searchText)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search by name, sector, or expertise...")
                                .foregroundColor(.textSecondary.opacity(0.5))
                        }
                        .foregroundColor(.textPrimary)
                }
                .padding()
                .background(Color.inputBackground)
                .cornerRadius(12)
                .frame(height: 48)
                
                // Content List
                ScrollView {
                    VStack(spacing: 16) {
                        // Card 1
                        networkCard(
                            imageName: "",
                            name: "Sarah Chen",
                            role: "CEO at Innovate Inc.",
                            tags: ["Scaling", "Fundraising"]
                        )
                        
                        // Card 2 (Placeholder)
                       networkCard(
                           imageName: "",
                           name: "David Miller",
                           role: "Partner at Greylock",
                           tags: ["Investment", "Strategy"]
                       )
                    }
                    .padding(.bottom, 80)
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    func networkCard(imageName: String, name: String, role: String, tags: [String]) -> some View {
        DashboardCard {
            VStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.inputBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        // Placeholder image or real image
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary)
                    )
                
                // Info
                VStack(spacing: 4) {
                    Text(name)
                        .font(.branding.profileName)
                        .foregroundColor(.textPrimary)
                    
                    Text(role)
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                }
                
                // Tags
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.branding.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.inputBackground)
                            .cornerRadius(20)
                    }
                }
                
                // Button
                Button(action: {}) {
                    Text("View Profile")
                        .font(.branding.body.weight(.bold))
                        .foregroundColor(.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.brandPrimary)
                        .cornerRadius(12)
                }
            }
            .padding(20)
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
