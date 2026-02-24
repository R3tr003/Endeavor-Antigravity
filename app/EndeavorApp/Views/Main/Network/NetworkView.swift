import SwiftUI
import SDWebImageSwiftUI
struct NetworkView: View {
    @State private var searchText: String = ""
    @State private var animateGlow = false
    
    @StateObject private var viewModel = NetworkViewModel(repository: FirebaseNetworkRepository())

    
    private var filteredProfiles: [UserProfile] {
        if searchText.isEmpty {
            return viewModel.profiles
        } else {
            return viewModel.profiles.filter { profile in
                profile.firstName.localizedCaseInsensitiveContains(searchText) ||
                profile.lastName.localizedCaseInsensitiveContains(searchText) ||
                profile.role.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                // Immersive Background
                Color.background.edgesIgnoringSafeArea(.all)
                
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
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
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Mentor\nNetwork")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                                .lineSpacing(-4)
                            
                            Text("Find the right expert to help you grow.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, DesignSystem.Spacing.standard)
                        
                        // Glass Search Bar
                        HStack(spacing: DesignSystem.Spacing.small) {
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Content List
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            ForEach(filteredProfiles, id: \.id) { profile in
                                networkCard(
                                    imageName: profile.profileImageUrl,
                                    name: "\(profile.firstName) \(profile.lastName)",
                                    role: profile.role,
                                    tags: [profile.location].filter { !$0.isEmpty } // using location as a tag placeholder
                                )
                            }
                            
                            // Pagination Trigger
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.vertical, DesignSystem.Spacing.medium)
                            } else if viewModel.hasMoreData {
                                Color.clear
                                    .frame(height: DesignSystem.Layout.buttonHeight)
                                    .onAppear {
                                        // Only fetch more if we aren't actively filtering
                                        if searchText.isEmpty {
                                            viewModel.fetchUsers()
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, DesignSystem.Spacing.bottomSafePadding) // Space for floating tab bar
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
                .onAppear {
                    if viewModel.profiles.isEmpty {
                        viewModel.fetchUsers(isInitial: true)
                    }
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
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Top section: Avatar and Info
                HStack(spacing: DesignSystem.Spacing.standard) {
                    if imageName.isEmpty {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary.opacity(0.5))
                            )
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    } else {
                        WebImage(url: URL(string: imageName)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        } placeholder: {
                            Circle()
                                .fill(Color.primary.opacity(0.05))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.secondary.opacity(0.5))
                                )
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
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
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, DesignSystem.Spacing.small)
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
            .padding(DesignSystem.Spacing.large)
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



struct NetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView()
    }
}
