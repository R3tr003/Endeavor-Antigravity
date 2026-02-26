import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var searchText: String = ""
    @State private var animateGlow: Bool = false
    @State private var selectedConversation: Conversation? = nil

    var filteredConversations: [Conversation] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter {
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
                        if viewModel.conversations.isEmpty {
                            viewModel.fetchConversations(userId: "currentUserId")
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
                                
                                let totalUnread = viewModel.conversations.reduce(0) { $0 + $1.unreadCount }
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
    let conversation: Conversation
    
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
