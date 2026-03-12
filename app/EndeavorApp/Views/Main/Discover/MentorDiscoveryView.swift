import SwiftUI
import SDWebImageSwiftUI
import FirebaseFunctions
import FirebasePerformance

struct MentorDiscoveryView: View {
    @State private var query: String = ""
    @State private var isSearching: Bool = false
    @State private var hasSearched: Bool = false
    @State private var animateGlow: Bool = false
    @FocusState private var isInputFocused: Bool
    @State private var aiMatches: [(userId: String, score: Int, reason: String)] = []
    
    @EnvironmentObject private var conversationsViewModel: ConversationsViewModel
    @StateObject private var networkViewModel = NetworkViewModel(repository: FirebaseNetworkRepository())
    @AppStorage("userId") private var currentUserId: String = ""
    @State private var activeConversation: Conversation?
    @State private var showConversation: Bool = false
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                // Due cerchi blur animati
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: proxy.size.width * 1.4, height: proxy.size.width * 1.4)
                            .blur(radius: 100)
                            .offset(x: animateGlow ? -80 : 60, y: animateGlow ? 120 : -60)
                        
                        Circle()
                            .fill(Color.purple.opacity(0.08))
                            .frame(width: proxy.size.width * 1.1, height: proxy.size.width * 1.1)
                            .blur(radius: 110)
                            .offset(x: animateGlow ? 120 : -80, y: animateGlow ? -180 : -80)
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
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            Text(String(localized: "discover.header.title1"))
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text(String(localized: "discover.header.title2"))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                            Text(String(localized: "discover.header.subtitle"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, DesignSystem.Spacing.xxSmall)
                        }
                        .padding(.top, DesignSystem.Spacing.standard)
                        
                        // Search Input Card
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.small) {
                            TextField(String(localized: "discover.search_placeholder"), text: $query, axis: .vertical)
                                .lineLimit(1...4)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.primary)
                                .focused($isInputFocused)
                                .padding()
                            
                            Button(action: {
                                isInputFocused = false
                                isSearching = true
                                hasSearched = true
                                aiMatches = []
                                
                                let trace = Performance.startTrace(name: "AI_Search_Duration")
                                
                                Functions.functions(region: "europe-west1")
                                    .httpsCallable("searchUsersWithAI")
                                    .call(["query": query, "currentUserId": currentUserId]) { result, error in
                                        DispatchQueue.main.async {
                                            isSearching = false
                                            guard error == nil,
                                                  let data = result?.data as? [String: Any],
                                                  let results = data["results"] as? [[String: Any]] else {
                                                trace?.stop()
                                                return
                                            }
                                            aiMatches = results.compactMap { r in
                                                guard let userId = r["userId"] as? String,
                                                      let score = r["score"] as? Int,
                                                      let reason = r["reason"] as? String else { return nil }
                                                return (userId: userId, score: score, reason: reason)
                                            }
                                            trace?.setValue(Int64(aiMatches.count), forMetric: "search_results_count")
                                            trace?.stop()
                                        }
                                    }
                            }) {
                                Text(String(localized: "discover.search_button"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(query.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .white)
                                    .padding(.horizontal, DesignSystem.Spacing.large)
                                    .padding(.vertical, 10)
                                    .background(query.trimmingCharacters(in: .whitespaces).isEmpty ? Color.primary.opacity(0.1) : Color.brandPrimary)
                                    .clipShape(Capsule())
                            }
                            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                            .padding(.bottom, DesignSystem.Spacing.standard)
                            .padding(.trailing, DesignSystem.Spacing.standard)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
                        
                        // Example Queries OR Results
                        if !hasSearched {
                            // Example Queries
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text(String(localized: "discover.try_asking"))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(1)
                                    .foregroundColor(.textSecondary)
                                
                                VStack(spacing: DesignSystem.Spacing.xSmall) {
                                    exampleChip("Who has experience scaling SaaS from 50 to 200 employees?")
                                    exampleChip("I need help with enterprise sales in fintech. Who should I talk to?")
                                    exampleChip("Which mentors have expanded companies into Latin America?")
                                }
                            }
                        } else {
                            if isSearching {
                                // Loading State
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                                        .scaleEffect(1.2)
                                    Text(String(localized: "discover.finding_matches"))
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.xxLarge)
                            } else {
                                // Results State
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    Text(String(localized: "discover.best_matches"))
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    let availableProfiles = networkViewModel.profiles.filter { profile in
                                        profile.id.uuidString != currentUserId &&
                                        !conversationsViewModel.hasConversation(with: profile.id.uuidString)
                                    }
                                    
                                    let joinedMatches = aiMatches.compactMap { match -> (profile: UserProfile, score: Int, reason: String)? in
                                        if let profile = availableProfiles.first(where: { $0.id.uuidString == match.userId }) {
                                            return (profile: profile, score: match.score, reason: match.reason)
                                        }
                                        return nil
                                    }
                                    
                                    if joinedMatches.isEmpty {
                                        Text(String(localized: "discover.no_matches"))
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .padding(.vertical)
                                    } else {
                                        VStack(spacing: DesignSystem.Spacing.standard) {
                                            ForEach(Array(joinedMatches.enumerated()), id: \.element.profile.id) { index, matchData in
                                                MatchCard(
                                                    profile: matchData.profile,
                                                    matchPercent: matchData.score,
                                                    companyName: networkViewModel.companyNames[matchData.profile.id.uuidString] ?? matchData.profile.role,
                                                    reason: matchData.reason,
                                                    onConnect: {
                                                        conversationsViewModel.getOrCreateConversation(with: matchData.profile.id.uuidString) { result in
                                                            if case .success(let convId) = result {
                                                                let newConv = Conversation(
                                                                    id: convId,
                                                                    participantIds: [currentUserId, matchData.profile.id.uuidString],
                                                                    lastMessage: "",
                                                                    lastMessageAt: Date(),
                                                                    lastSenderId: "",
                                                                    unreadCounts: [:],
                                                                    otherParticipantName: matchData.profile.fullName,
                                                                    otherParticipantCompany: networkViewModel.companyNames[matchData.profile.id.uuidString] ?? matchData.profile.role,
                                                                    otherParticipantImageUrl: matchData.profile.profileImageUrl
                                                                )
                                                                self.activeConversation = newConv
                                                                self.showConversation = true
                                                            }
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    
                                    // New Search Button
                                    Button(action: {
                                        query = ""
                                        hasSearched = false
                                        isSearching = false
                                    }) {
                                        Text(String(localized: "discover.new_search"))
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.brandPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DesignSystem.Spacing.small)
                                            .overlay(Capsule().stroke(Color.brandPrimary, lineWidth: 1))
                                    }
                                    .padding(.top, DesignSystem.Spacing.medium)
                                }
                            }
                        }
                        
                        Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
                .onAppear {
                    if networkViewModel.profiles.isEmpty {
                        networkViewModel.fetchUsers(currentUserId: currentUserId, isInitial: true)
                    }
                }
            }
        }
        .sheet(isPresented: $showConversation) {
            if let activeConv = activeConversation {
                ConversationView(conversation: activeConv, currentUserId: currentUserId)
            }
        }
    }
    
    @ViewBuilder
    private func exampleChip(_ text: String) -> some View {
        Button(action: {
            query = text
            isInputFocused = false
        }) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.standard) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.brandPrimary)
                
                Text(text)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(DesignSystem.Spacing.standard)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
        }
    }
}

struct MatchCard: View {
    let profile: UserProfile
    let matchPercent: Int
    let companyName: String
    let reason: String
    let onConnect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            
            // Top Row
            HStack(spacing: DesignSystem.Spacing.small) {
                // Initial Circle or Avatar
                if profile.profileImageUrl.isEmpty {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(profile.firstName.prefix(1)))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                        )
                } else {
                    WebImage(url: URL(string: profile.profileImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: 60, height: 60)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.fullName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(companyName)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Match Percent Badge
                Text("\(matchPercent)% Match")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandPrimary, in: Capsule())
            }
            
            // Description Row
            Text("Experienced professional in the Endeavor network. Mentorship areas include: \(profile.role).")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(["Leadership", "Strategy", "Growth"], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.brandPrimary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.brandPrimary.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            
            if !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // Action Button
            Button(action: onConnect) {
                Text(String(localized: "discover.connect"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.brandPrimary.opacity(0.12), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    MentorDiscoveryView()
        .environmentObject(ConversationsViewModel())
}
