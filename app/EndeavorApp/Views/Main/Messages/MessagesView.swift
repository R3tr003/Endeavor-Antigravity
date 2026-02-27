import SwiftUI
import FirebaseAuth

struct MessagesView: View {
    @StateObject private var viewModel = ConversationsViewModel()
    @State private var searchText: String = ""
    @State private var animateGlow: Bool = false
    @State private var selectedConversation: Conversation? = nil
    @State private var showNewConversation: Bool = false
    @State private var pendingConversationId: String? = nil
    @State private var pendingRecipientId: String? = nil

    var filteredConversations: [Conversation] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter {
                $0.otherParticipantName.localizedCaseInsensitiveContains(searchText) ||
                $0.otherParticipantRole.localizedCaseInsensitiveContains(searchText)
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
                        viewModel.startListening()
                    }
                    .onDisappear {
                        viewModel.stopListening()
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
                                
                                let currentUid = Auth.auth().currentUser?.uid ?? ""
                                let totalUnread = viewModel.conversations.reduce(0) { $0 + $1.unreadCount(for: currentUid) }
                                if totalUnread > 0 {
                                    Text("\(totalUnread) unread messages")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, DesignSystem.Spacing.standard)
                                        .background(Color.brandPrimary, in: Capsule())
                                }
                                
                                Button(action: { showNewConversation = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandPrimary)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
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
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))

                        // Conversations List
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(filteredConversations) { convo in
                                ConversationRow(conversation: convo, currentUserId: Auth.auth().currentUser?.uid ?? "")
                                    .onTapGesture {
                                        selectedConversation = convo
                                    }
                            }
                            
                            if viewModel.conversations.isEmpty && !viewModel.isLoading {
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    Spacer().frame(height: DesignSystem.Spacing.xxLarge)
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandPrimary.opacity(0.1))
                                            .frame(width: 80, height: 80)
                                        Image(systemName: "bubble.left.and.bubble.right")
                                            .font(.system(size: 32))
                                            .foregroundColor(.brandPrimary.opacity(0.7))
                                    }
                                    VStack(spacing: DesignSystem.Spacing.xSmall) {
                                        Text("No conversations yet")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text("Start a conversation with someone\nfrom your Endeavor network.")
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    Button(action: { showNewConversation = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.pencil")
                                                .font(.system(size: 15, weight: .semibold))
                                            Text("Start a Conversation")
                                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, DesignSystem.Spacing.large)
                                        .background(Color.brandPrimary, in: Capsule())
                                        .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, DesignSystem.Spacing.large)
                            }
                        }

                        Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
            }
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserId: Auth.auth().currentUser?.uid ?? ""
            )
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { conversationId, recipientId in
                pendingConversationId = conversationId
                pendingRecipientId = recipientId
            }
        }
        .onChange(of: pendingConversationId) { _, newId in
            guard let conversationId = newId, let recipientId = pendingRecipientId else { return }
            let currentUid = Auth.auth().currentUser?.uid ?? ""
            let tempConversation = Conversation(
                id: conversationId,
                participantIds: [currentUid, recipientId],
                lastMessage: "",
                lastMessageAt: Date(),
                lastSenderId: "",
                unreadCounts: [:],
                otherParticipantName: "Loading...",
                otherParticipantRole: "",
                otherParticipantImageUrl: ""
            )
            selectedConversation = tempConversation
            pendingConversationId = nil
            pendingRecipientId = nil
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            
            // Avatar
            Circle()
                .fill(conversation.accentColor(currentUserId: currentUserId).opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                )
                .overlay(
                    Circle().stroke(conversation.unreadCount(for: currentUserId) > 0 ? conversation.accentColor(currentUserId: currentUserId) : Color.borderGlare.opacity(0.15), lineWidth: conversation.unreadCount(for: currentUserId) > 0 ? 2 : 1)
                )

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(conversation.otherParticipantName)
                    .font(.system(size: 16, weight: conversation.unreadCount(for: currentUserId) > 0 ? .bold : .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(conversation.otherParticipantRole)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                    .lineLimit(1)
                
                Text(conversation.lastMessage)
                    .font(.system(size: 14, weight: conversation.unreadCount(for: currentUserId) > 0 ? .medium : .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Metadata
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xSmall) {
                Text(conversation.displayTime)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                
                if conversation.unreadCount(for: currentUserId) > 0 {
                    Text("\(conversation.unreadCount(for: currentUserId))")
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
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    MessagesView()
}
