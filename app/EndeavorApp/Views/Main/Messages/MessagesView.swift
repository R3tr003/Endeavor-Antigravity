import SwiftUI

struct MockConversation: Identifiable {
    let id: UUID
    let name: String
    let role: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let initials: String
    let accentColor: Color

    static let mockConversations: [MockConversation] = [
        MockConversation(id: UUID(), name: "Maria Lopez", role: "SaaS Scaling Expert",
            lastMessage: "Happy to share what worked for us at the 50-person milestone.",
            time: "2m", unreadCount: 2, initials: "ML", accentColor: Color.brandPrimary),

        MockConversation(id: UUID(), name: "Carlos Rodriguez", role: "Fintech Founder",
            lastMessage: "Let's schedule a call this week to discuss the go-to-market.",
            time: "1h", unreadCount: 1, initials: "CR", accentColor: .purple),

        MockConversation(id: UUID(), name: "Ana Martinez", role: "CEO, Series B",
            lastMessage: "The fundraising deck looks solid. A few suggestions...",
            time: "3h", unreadCount: 0, initials: "AM", accentColor: .orange),

        MockConversation(id: UUID(), name: "Endeavor Team", role: "Account Manager",
            lastMessage: "Your next mentorship session is confirmed for Thursday.",
            time: "1d", unreadCount: 0, initials: "ET", accentColor: Color.brandPrimary),

        MockConversation(id: UUID(), name: "James Okafor", role: "Operations Expert",
            lastMessage: "Scaling ops across 3 markets is tough — here's my framework.",
            time: "2d", unreadCount: 0, initials: "JO", accentColor: .blue),
    ]
}

struct MessagesView: View {
    @State private var searchText: String = ""
    @State private var animateGlow: Bool = false
    @State private var selectedConversation: MockConversation? = nil

    var filteredConversations: [MockConversation] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return MockConversation.mockConversations
        } else {
            return MockConversation.mockConversations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.role.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)

                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.12))
                            .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                            .blur(radius: 100)
                            .offset(x: animateGlow ? -80 : 60, y: animateGlow ? 100 : -80)
                        
                        Circle()
                            .fill(Color.purple.opacity(0.08))
                            .frame(width: proxy.size.width * 1.2, height: proxy.size.width * 1.2)
                            .blur(radius: 110)
                            .offset(x: animateGlow ? 100 : -60, y: animateGlow ? -200 : -60)
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
                            Text("Messages")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                            
                            HStack {
                                Text("Purpose-driven conversations.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                let totalUnread = MockConversation.mockConversations.reduce(0) { $0 + $1.unreadCount }
                                if totalUnread > 0 {
                                    Text("\(totalUnread) unread messages")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, DesignSystem.Spacing.standard)
                                        .background(Color.brandPrimary, in: Capsule())
                                }
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.standard)

                        // Search Bar
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                            
                            TextField("Search conversations...", text: $searchText)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))

                        // Conversations List
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(filteredConversations) { convo in
                                ConversationRow(conversation: convo)
                                    .onTapGesture {
                                        selectedConversation = convo
                                    }
                            }
                        }

                        Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
            }
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationView(conversation: conversation)
        }
    }
}

struct ConversationRow: View {
    let conversation: MockConversation
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            
            // Avatar
            Circle()
                .fill(conversation.accentColor.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(conversation.accentColor)
                )
                .overlay(
                    Circle().stroke(conversation.unreadCount > 0 ? conversation.accentColor : Color.white.opacity(0.15), lineWidth: conversation.unreadCount > 0 ? 2 : 1)
                )

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(conversation.name)
                    .font(.system(size: 16, weight: conversation.unreadCount > 0 ? .bold : .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(conversation.role)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(conversation.accentColor)
                    .lineLimit(1)
                
                Text(conversation.lastMessage)
                    .font(.system(size: 14, weight: conversation.unreadCount > 0 ? .medium : .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Metadata
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xSmall) {
                Text(conversation.time)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.brandPrimary, in: Circle())
                } else {
                    Spacer().frame(height: 22)
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    MessagesView()
}
