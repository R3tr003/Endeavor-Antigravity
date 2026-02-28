import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NetworkView: View {
    @State private var searchText: String = ""
    @State private var animateGlow = false
    @State private var selectedCategory: String = "All"
    
    @StateObject private var viewModel = NetworkViewModel(repository: FirebaseNetworkRepository())
    @EnvironmentObject private var conversationsViewModel: ConversationsViewModel
    @State private var activeConversation: Conversation?
    @State private var showConversation: Bool = false
    @State private var companyNames: [String: String] = [:]

    @AppStorage("userId") private var currentUserId: String = ""

    private var filteredProfiles: [UserProfile] {
        let others = viewModel.profiles.filter { $0.id.uuidString != currentUserId }
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
        
        switch selectedCategory {
        case "Mentors":
            return baseProfiles.filter { $0.role.localizedCaseInsensitiveContains("mentor") }
        case "CEOs & Founders":
            return baseProfiles.filter { 
                $0.role.localizedCaseInsensitiveContains("ceo") || 
                $0.role.localizedCaseInsensitiveContains("founder") 
            }
        case "Endeavor Team":
            return baseProfiles.filter { $0.role.localizedCaseInsensitiveContains("endeavor") }
        default:
            return baseProfiles
        }
    }
    
    let categories = ["All", "Mentors", "CEOs & Founders", "Endeavor Team"]
    
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
                                    Text("Search by name or sector...")
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
                                            selectedCategory = category
                                        }
                                    }) {
                                        Text(category)
                                            .font(.system(size: 14, weight: selectedCategory == category ? .bold : .medium, design: .rounded))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, DesignSystem.Spacing.standard)
                                            .background(
                                                selectedCategory == category ? AnyShapeStyle(Color.brandPrimary) : AnyShapeStyle(.ultraThinMaterial),
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
                            ForEach(categoryFilteredProfiles, id: \.id) { profile in
                                networkCard(profile: profile)
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
                                            viewModel.fetchUsers()
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
                        viewModel.fetchUsers(isInitial: true)
                    }
                }
                .onChange(of: viewModel.profiles) { _, profiles in
                    let db = Firestore.firestore()
                    for profile in profiles {
                        let userId = profile.id.uuidString
                        guard companyNames[userId] == nil else { continue }
                        db.collection("companies")
                            .whereField("userId", isEqualTo: userId)
                            .limit(to: 1)
                            .getDocuments { snapshot, _ in
                                if let name = snapshot?.documents.first?.data()["name"] as? String {
                                    DispatchQueue.main.async {
                                        companyNames[userId] = name
                                    }
                                }
                            }
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
                        
                        if let company = companyNames[profile.id.uuidString] {
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
                HStack(spacing: DesignSystem.Spacing.small) {
                    // View Profile Button
                    Button(action: {}) {
                        Text("View Profile")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(Capsule().stroke(Color.brandPrimary, lineWidth: 1.5))
                    }
                    
                    // Connect Button
                    Button(action: {
                        conversationsViewModel.getOrCreateConversation(with: profile.id.uuidString) { result in
                            switch result {
                            case .success(let conversationId):
                                // Creiamo una conversation fittizia per passare il dato al ConversationView
                                // Il ViewModel dentro ConversationView fetcherà i dati veri
                                let newConv = Conversation(
                                    id: conversationId,
                                    participantIds: [UserDefaults.standard.string(forKey: "userId") ?? "", profile.id.uuidString],
                                    lastMessage: "",
                                    lastMessageAt: Date(),
                                    lastSenderId: "",
                                    unreadCounts: [:],
                                    otherParticipantName: profile.firstName + " " + profile.lastName,
                                    otherParticipantCompany: companyNames[profile.id.uuidString] ?? profile.role,
                                    otherParticipantImageUrl: profile.profileImageUrl
                                )
                                self.activeConversation = newConv
                                self.showConversation = true
                            case .failure(let error):
                                print("Error creating or fetching conversation: \(error)")
                            }
                        }
                    }) {
                        Text("Connect")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.brandPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(DesignSystem.Spacing.large)
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
