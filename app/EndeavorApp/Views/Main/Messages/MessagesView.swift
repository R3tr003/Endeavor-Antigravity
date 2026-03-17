import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct MessagesView: View {
    @EnvironmentObject private var viewModel: ConversationsViewModel
    @State private var searchText: String = ""
    @State private var animateGlow: Bool = false
    @State private var selectedConversation: Conversation? = nil
    @State private var showNewConversation: Bool = false
    @State private var pendingConversationId: String? = nil
    @State private var pendingRecipientId: String? = nil
    @State private var conversationToDelete: Conversation? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showFilteredConversations: Bool = false
    var filteredConversations: [Conversation] {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        let base = viewModel.conversations.filter { convo in
            if convo.isFiltered {
                return convo.lastSenderId == currentUserId
            }
            return true
        }
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return base
        }
        return base.filter {
            $0.otherParticipantName.localizedCaseInsensitiveContains(searchText) ||
            $0.otherParticipantCompany.localizedCaseInsensitiveContains(searchText)
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
                            Text(String(localized: "nav.messages"))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                            
                            HStack {
                                Text(String(localized: "messages.purpose_driven"))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
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
                            
                            TextField(String(localized: "messages.search_placeholder", defaultValue: "Search conversations..."), text: $searchText)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))

                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)

                    // Riga "Filtered" — slim, stile WhatsApp
                    if !viewModel.filteredConversations.isEmpty {
                        Button(action: {
                            AnalyticsService.shared.logFilteredConversationsViewed(count: viewModel.filteredConversations.count)
                            showFilteredConversations = true
                        }) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)

                                Text(String(localized: "messages.filtered", defaultValue: "Filtered"))
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.secondary)

                                Spacer()

                                if viewModel.filteredUnreadCount > 0 {
                                    Text("\(viewModel.filteredUnreadCount)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red, in: Capsule())
                                }

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.4))
                            }
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.vertical, DesignSystem.Spacing.small)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.xSmall)
                    }

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.small) {

                            ForEach(filteredConversations) { convo in
                                SwipeableConversationRow(
                                    conversation: convo,
                                    currentUserId: UserDefaults.standard.string(forKey: "userId") ?? "",
                                    onDelete: {
                                        conversationToDelete = convo
                                        showDeleteConfirmation = true
                                    },
                                    onTogglePin: {
                                        let currentUid = UserDefaults.standard.string(forKey: "userId") ?? ""
                                        let isPinned = convo.pinnedBy.contains(currentUid)
                                        viewModel.togglePin(convo, isPinned: !isPinned)
                                    }
                                )
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
                                        Text(String(localized: "messages.no_conversations"))
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Text(String(localized: "messages.no_conversations_subtitle", defaultValue: "Start a conversation with someone\nfrom your Endeavor network."))
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    Button(action: { showNewConversation = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.pencil")
                                                .font(.system(size: 15, weight: .semibold))
                                            Text(String(localized: "messages.start_conversation"))
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
                        .padding(.horizontal, DesignSystem.Spacing.medium)

                        Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                    }
                }
            }
        }
        .sheet(item: $selectedConversation) { conversation in
            ConversationView(
                conversation: conversation,
                currentUserId: UserDefaults.standard.string(forKey: "userId") ?? ""
            )
        }
        .sheet(isPresented: $showFilteredConversations) {
            FilteredConversationsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { conversationId, recipientId in
                pendingConversationId = conversationId
                pendingRecipientId = recipientId
            }
        }
        .onChange(of: pendingConversationId) { _, newId in
            guard let conversationId = newId, let recipientId = pendingRecipientId else { return }
            let currentUid = UserDefaults.standard.string(forKey: "userId") ?? ""
            let tempConversation = Conversation(
                id: conversationId,
                participantIds: [currentUid, recipientId],
                lastMessage: "",
                lastMessageAt: Date(),
                lastSenderId: "",
                unreadCounts: [:],
                otherParticipantName: "Loading...",
                otherParticipantCompany: "",
                otherParticipantImageUrl: ""
            )
            selectedConversation = tempConversation
            pendingConversationId = nil
            pendingRecipientId = nil
        }
        .alert(String(localized: "messages.delete_conversation", defaultValue: "Delete Conversation"), isPresented: $showDeleteConfirmation, presenting: conversationToDelete) { convo in
            Button(String(localized: "common.delete"), role: .destructive) {
                viewModel.deleteConversation(convo)
            }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        } message: { convo in
            Text(String(localized: "messages.delete_confirmation", defaultValue: "Are you sure you want to delete this conversation with \(convo.otherParticipantName)? This action cannot be undone."))
        }
    }
}

struct SwipeableConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    let onDelete: () -> Void
    let onTogglePin: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwipedLeft: Bool = false
    
    var isPinned: Bool {
        conversation.pinnedBy.contains(currentUserId)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Sfondo con azione Delete (swipe verso sinistra)
            ZStack(alignment: .trailing) {
                Color.red
                
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "common.delete"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.trailing, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
            .onTapGesture {
                onDelete()
                withAnimation(.spring()) {
                    offset = 0
                    isSwipedLeft = false
                }
            }
            .opacity(offset < 0 ? 1 : 0)

            // Sfondo con azione Pin (swipe verso destra)
            ZStack(alignment: .leading) {
                Color.green
                
                VStack(spacing: 4) {
                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isPinned ? String(localized: "messages.unpin", defaultValue: "Unpin") : String(localized: "messages.pin", defaultValue: "Pin"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.leading, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
            .opacity(offset > 0 ? 1 : 0)

            // Foreground Content (la row normale)
            ConversationRow(conversation: conversation, currentUserId: currentUserId)
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if isSwipedLeft {
                                offset = min(max(value.translation.width - 100, -350), 100)
                            } else {
                                offset = min(max(value.translation.width, -350), 100)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                if value.translation.width < -150 {
                                    // Full swipe: trigger delete immediately
                                    offset = 0
                                    isSwipedLeft = false
                                    onDelete()
                                } else if value.translation.width < -60 {
                                    // Partial swipe: show delete button
                                    offset = -100
                                    isSwipedLeft = true
                                } else if value.translation.width > 60 {
                                    // Swipe right: toggle pin
                                    onTogglePin()
                                    offset = 0
                                    isSwipedLeft = false
                                } else {
                                    // Cancel swipe
                                    offset = 0
                                    isSwipedLeft = false
                                }
                            }
                        }
                )
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            
            // Avatar
            let avatarColor = conversation.accentColor(currentUserId: currentUserId)
            let hasUnread = conversation.unreadCount(for: currentUserId) > 0

            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                if conversation.otherParticipantImageUrl.isEmpty {
                    Text(conversation.initials)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(avatarColor)
                } else {
                    WebImage(url: URL(string: conversation.otherParticipantImageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                    } placeholder: {
                        EmptyView()
                    }
                    .transition(.fade(duration: 0))
                }
            }
            .transaction { $0.animation = nil }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    hasUnread ? avatarColor : Color.borderGlare.opacity(0.15),
                    lineWidth: hasUnread ? 2 : 1
                )
            )

            // Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(conversation.otherParticipantName)
                    .font(.system(size: 16, weight: conversation.unreadCount(for: currentUserId) > 0 ? .bold : .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                if !conversation.otherParticipantCompany.isEmpty {
                    Text(conversation.otherParticipantCompany)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                        .lineLimit(1)
                }
                
                let isMine = conversation.lastSenderId == currentUserId
                let recipientId = conversation.participantIds.first(where: { $0 != currentUserId }) ?? ""
                HStack(spacing: 3) {
                    if isMine {
                        // Determina lo stato dalla conversazione (no fetch extra)
                        let status: Message.ReceiptStatus = {
                            if conversation.lastMessageReadBy.contains(recipientId) { return .read }
                            if conversation.lastMessageDeliveredTo.contains(recipientId) { return .delivered }
                            return .sent
                        }()
                        ReceiptStatusView(status: status)
                    }
                    let isMeetingInvite = conversation.lastMessage.contains("Meeting invite:")
                    if isMeetingInvite {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Text(isMeetingInvite
                         ? conversation.lastMessage.replacingOccurrences(of: "📅 ", with: "").replacingOccurrences(of: "📹 ", with: "")
                         : conversation.lastMessage)
                        .font(.system(size: 14, weight: conversation.unreadCount(for: currentUserId) > 0 ? .medium : .regular, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Metadata
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xSmall) {
                HStack(spacing: 4) {
                    if conversation.pinnedBy.contains(currentUserId) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(UIColor.lightGray))
                            .rotationEffect(.degrees(45))
                    }
                    Text(conversation.displayTime)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                if conversation.isFiltered && conversation.lastSenderId == currentUserId {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.red, in: Circle())
                } else if conversation.unreadCount(for: currentUserId) > 0 {
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous).stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    MessagesView()
        .environmentObject(ConversationsViewModel())
}
