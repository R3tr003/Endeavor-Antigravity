import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NetworkView: View {
    @State private var searchText: String = ""
    @State private var animateGlow = false
    @State private var selectedCategories: Set<String> = ["All"]
    
    @StateObject private var viewModel = NetworkViewModel(repository: FirebaseNetworkRepository())
    @EnvironmentObject private var conversationsViewModel: ConversationsViewModel
    @State private var activeConversation: Conversation?
    @State private var showConversation: Bool = false
    @State private var selectedProfile: UserProfile? = nil
    @AppStorage("userId") private var currentUserId: String = ""

    private var filteredProfiles: [UserProfile] {
        let others = viewModel.profiles.filter { profile in 
            profile.id.uuidString != currentUserId &&
            !conversationsViewModel.hasConversation(with: profile.id.uuidString)
        }
        if searchText.isEmpty {
            return others
        } else {
            return others.filter { profile in
                profile.firstName.localizedCaseInsensitiveContains(searchText) ||
                profile.lastName.localizedCaseInsensitiveContains(searchText) ||
                profile.role.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var categoryFilteredProfiles: [UserProfile] {
        let baseProfiles = filteredProfiles
        
        if selectedCategories.contains("All") {
            return baseProfiles
        }
        
        // Convert selected frontend categories to backend userTypes
        var validUserTypes = Set<String>()
        if selectedCategories.contains("Entrepreneurs") { validUserTypes.insert("Entrepreneur") }
        if selectedCategories.contains("Mentors")       { validUserTypes.insert("Mentor") }
        if selectedCategories.contains("Investors")     { validUserTypes.insert("Investor") }
        if selectedCategories.contains("Endeavor Team") { validUserTypes.insert("Staff") }
        
        return baseProfiles.filter { validUserTypes.contains($0.userType) }
    }
    
    let categories = ["All", "Entrepreneurs", "Mentors", "Investors", "Endeavor Team"]
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                GeometryReader { proxy in
                    ZStack {
                        // Ambient glows
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
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        // Glass Search Bar
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("", text: $searchText)
                                .placeholder(when: searchText.isEmpty) {
                                    Text(String(localized: "network.search_placeholder"))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        // Category Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            if category == "All" {
                                                selectedCategories = ["All"]
                                            } else {
                                                if selectedCategories.contains("All") {
                                                    selectedCategories.remove("All")
                                                }
                                                
                                                if selectedCategories.contains(category) {
                                                    selectedCategories.remove(category)
                                                    if selectedCategories.isEmpty {
                                                        selectedCategories.insert("All") // fallback
                                                    }
                                                } else {
                                                    selectedCategories.insert(category)
                                                }
                                            }
                                        }
                                    }) {
                                        let isSelected = selectedCategories.contains(category)
                                        Text(category)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, DesignSystem.Spacing.standard)
                                            .background(
                                                isSelected ? AnyShapeStyle(Color.brandPrimary) : AnyShapeStyle(.ultraThinMaterial),
                                                in: Capsule()
                                            )
                                            .overlay(
                                                Capsule().stroke(Color.borderGlare.opacity(0.15), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        }
                        
                        // Results Counter
                        if !(viewModel.isLoading && categoryFilteredProfiles.isEmpty) {
                            Text("\(categoryFilteredProfiles.count) members")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, DesignSystem.Spacing.large)
                                .padding(.top, -DesignSystem.Spacing.small) // pulls it closer to filters
                        }
                        
                        // Content List
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            if viewModel.isLoading && viewModel.profiles.isEmpty {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.brandPrimary)
                                    Text(String(localized: "network.loading"))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(categoryFilteredProfiles, id: \.id) { profile in
                                    Button(action: {
                                        selectedProfile = profile
                                    }) {
                                        networkCard(profile: profile)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Pagination Trigger
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.vertical, DesignSystem.Spacing.medium)
                            } else if viewModel.hasMoreData {
                                Color.clear
                                    .frame(height: 44) // standard height instead of layout struct parameter
                                    .onAppear {
                                        // Trigger only if we aren't filtering locally by text
                                        if searchText.isEmpty {
                                            viewModel.fetchUsers(currentUserId: currentUserId)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.bottomSafePadding)
                    }
                }
                .onAppear {
                    if viewModel.profiles.isEmpty {
                        viewModel.fetchUsers(currentUserId: currentUserId, isInitial: true)
                    }
                }
                
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .sheet(isPresented: $showConversation) {
            if let activeConv = activeConversation, let currentUserId = UserDefaults.standard.string(forKey: "userId") {
                ConversationView(conversation: activeConv, currentUserId: currentUserId)
            }
        }
        .sheet(item: $selectedProfile) { profile in
            UserProfileView(
                profile: profile,
                companyName: viewModel.companyNames[profile.id.uuidString]
            )
            .environmentObject(conversationsViewModel)
        }
    }
    
    @ViewBuilder
    private func networkCard(profile: UserProfile) -> some View {
        DashboardCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                
                // Avatar, Name, Role
                HStack(spacing: DesignSystem.Spacing.standard) {
                    if profile.profileImageUrl.isEmpty {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary.opacity(0.5))
                            )
                            .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                    } else {
                        WebImage(url: URL(string: profile.profileImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                        } placeholder: {
                            Circle()
                                .fill(Color.primary.opacity(0.05))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.secondary.opacity(0.5))
                                )
                                .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                        Text("\(profile.firstName) \(profile.lastName)")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                        
                        if !profile.userType.isEmpty {
                            Text(profile.userType)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(userTypeColor(profile.userType))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(userTypeColor(profile.userType).opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        if let company = viewModel.companyNames[profile.id.uuidString] {
                            Text(company)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            // Placeholder animato mentre carica
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundColor(.clear)
                                .redacted(reason: .placeholder)
                        }
                    }
                    Spacer()
                }
                
                // Action Buttons (Side by Side)
                Button(action: {
                    selectedProfile = profile
                }) {
                    Text(String(localized: "network.view_profile"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
    }
    private func userTypeColor(_ userType: String) -> Color {
        switch userType {
        case "Entrepreneur": return .brandPrimary
        case "Mentor":       return .orange
        case "Investor":     return Color(red: 0.4, green: 0.2, blue: 0.9)
        case "Staff":        return .green
        default:             return .secondary
        }
    }
}

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
            .environmentObject(ConversationsViewModel())
    }
}
