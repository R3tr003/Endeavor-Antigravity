import SwiftUI
import SDWebImageSwiftUI

struct FilteredConversationsView: View {
    @EnvironmentObject private var viewModel: ConversationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConversation: Conversation? = nil
    @State private var conversationToBanDelete: Conversation? = nil
    private let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.medium) {

                        // Banner
                        HStack(alignment: .center, spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            Text(String(localized: "messages.filtered_info",
                                        defaultValue: "These conversations were flagged by AI as potentially irrelevant or promotional."))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.red.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))

                        // Lista conversazioni filtrate
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(viewModel.filteredConversations) { convo in
                                SwipeableFilteredConversationCard(
                                    conversation: convo,
                                    currentUserId: currentUserId,
                                    onTap: {
                                        selectedConversation = convo
                                    },
                                    onDeleteTapped: {
                                        conversationToBanDelete = convo
                                    },
                                    onUnfilter: {
                                        AnalyticsService.shared.logConversationUnfiltered()
                                        viewModel.unfilterConversation(conversationId: convo.id)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.large)
                }
            }
        }
        .sheet(item: $selectedConversation) { convo in
            ConversationView(conversation: convo, currentUserId: currentUserId)
        }
        // Confirmation alert — Delete & Ban
        .alert(
            String(localized: "messages.ban_confirm_title", defaultValue: "Delete & Ban"),
            isPresented: Binding(
                get: { conversationToBanDelete != nil },
                set: { if !$0 { conversationToBanDelete = nil } }
            ),
            presenting: conversationToBanDelete
        ) { convo in
            Button(String(localized: "messages.ban_confirm_button", defaultValue: "Delete & Ban"), role: .destructive) {
                viewModel.banAndDeleteConversation(convo)
                conversationToBanDelete = nil
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                conversationToBanDelete = nil
            }
        } message: { convo in
            Text(String(format: String(localized: "messages.ban_confirm_message",
                                       defaultValue: "This will delete the conversation and prevent %@ from contacting you for 10 days."),
                        convo.otherParticipantName))
        }
    }

    private var headerBar: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            Text(String(localized: "messages.filtered", defaultValue: "Filtered"))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Circle()
                .fill(.clear)
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.standard)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
    }
}

// MARK: - Swipeable Wrapper

private struct SwipeableFilteredConversationCard: View {
    let conversation: Conversation
    let currentUserId: String
    let onTap: () -> Void
    let onDeleteTapped: () -> Void
    let onUnfilter: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isSwipedLeft: Bool = false
    @State private var isSwipedRight: Bool = false

    private func resetOffset() {
        withAnimation(.spring()) { offset = 0; isSwipedLeft = false; isSwipedRight = false }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Left swipe background — red, trash (shown when swiped left)
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
                resetOffset()
                onDeleteTapped()
            }
            .opacity(offset < 0 ? 1 : 0)

            // Right swipe background — green, checkmark (shown when swiped right)
            ZStack(alignment: .leading) {
                Color.green
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(String(localized: "messages.not_spam", defaultValue: "Not Spam"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .padding(.leading, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
            .onTapGesture {
                resetOffset()
                onUnfilter()
            }
            .opacity(offset > 0 ? 1 : 0)

            // Card foreground — tap and drag gestures live here to avoid conflicts
            FilteredConversationCard(conversation: conversation, currentUserId: currentUserId)
                .background(Color.background)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous))
                .offset(x: offset)
                .onTapGesture {
                    if offset != 0 {
                        resetOffset()
                    } else {
                        onTap()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if isSwipedLeft {
                                offset = min(max(value.translation.width - 100, -350), 0)
                            } else if isSwipedRight {
                                offset = min(max(value.translation.width + 100, 0), 350)
                            } else {
                                offset = min(max(value.translation.width, -350), 350)
                            }
                        }
                        .onEnded { value in
                            let dx = value.translation.width
                            if isSwipedRight {
                                // Card is showing "Not Spam" panel
                                if dx < -30 {
                                    // Dragging back left → cancel, return to center
                                    resetOffset()
                                } else if dx > 60 {
                                    // Continuing right → confirm unfilter
                                    resetOffset()
                                    DispatchQueue.main.async { onUnfilter() }
                                } else {
                                    // Small movement → stay revealed
                                    withAnimation(.spring()) { offset = 100 }
                                }
                            } else if isSwipedLeft {
                                // Card is showing delete panel
                                if dx > 30 {
                                    // Dragging back right → cancel, return to center
                                    resetOffset()
                                } else if dx < -60 {
                                    // Continuing left → confirm delete
                                    resetOffset()
                                    DispatchQueue.main.async { onDeleteTapped() }
                                } else {
                                    // Small movement → stay revealed
                                    withAnimation(.spring()) { offset = -100 }
                                }
                            } else {
                                // Card is at neutral position
                                if dx < -150 {
                                    resetOffset()
                                    DispatchQueue.main.async { onDeleteTapped() }
                                } else if dx < -60 {
                                    withAnimation(.spring()) { offset = -100; isSwipedLeft = true; isSwipedRight = false }
                                } else if dx > 150 {
                                    resetOffset()
                                    DispatchQueue.main.async { onUnfilter() }
                                } else if dx > 60 {
                                    withAnimation(.spring()) { offset = 100; isSwipedRight = true; isSwipedLeft = false }
                                } else {
                                    resetOffset()
                                }
                            }
                        }
                )
        }
    }
}

// MARK: - Card

private struct FilteredConversationCard: View {
    let conversation: Conversation
    let currentUserId: String

    var body: some View {
        let avatarColor = conversation.accentColor(currentUserId: currentUserId)
        let unread = conversation.unreadCount(for: currentUserId)
        let recipientId = conversation.participantIds.first(where: { $0 != currentUserId }) ?? ""
        let isMine = conversation.lastSenderId == currentUserId

        VStack(alignment: .leading, spacing: 0) {

            // Riga principale
            HStack(spacing: DesignSystem.Spacing.standard) {

                // Avatar
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
                            Text(conversation.initials)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(avatarColor)
                        }
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().stroke(avatarColor.opacity(0.3), lineWidth: 1.5))

                // Info testo
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(conversation.otherParticipantName)
                        .font(.system(size: 16,
                                      weight: unread > 0 ? .bold : .semibold,
                                      design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !conversation.otherParticipantCompany.isEmpty {
                        Text(conversation.otherParticipantCompany)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(avatarColor)
                            .lineLimit(1)
                    }

                    HStack(spacing: 3) {
                        if isMine {
                            let status: Message.ReceiptStatus = {
                                if conversation.lastMessageReadBy.contains(recipientId) { return .read }
                                if conversation.lastMessageDeliveredTo.contains(recipientId) { return .delivered }
                                return .sent
                            }()
                            ReceiptStatusView(status: status)
                        }
                        Text(conversation.lastMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Metadata destra
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xSmall) {
                    Text(conversation.displayTime)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)

                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.red, in: Circle())
                    } else {
                        Spacer().frame(height: 22)
                    }
                }
            }
            .padding(DesignSystem.Spacing.standard)

            // Motivazione AI — striscia rossa, allineata a sinistra, sparkles grande
            if !conversation.filterReason.isEmpty {
                Rectangle()
                    .fill(Color.red.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, DesignSystem.Spacing.standard)

                HStack(alignment: .center, spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                    Text(conversation.filterReason)
                        .font(.system(size: 12, design: .rounded))
                        .lineLimit(2)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, DesignSystem.Spacing.xSmall)
            }
        }
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xxLarge, style: .continuous)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.red.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}
