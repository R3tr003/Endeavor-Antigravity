import SwiftUI
import SDWebImageSwiftUI

struct FilteredConversationsView: View {
    @EnvironmentObject private var viewModel: ConversationsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConversation: Conversation? = nil
    private let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header — stesso pattern di ConversationView
                headerBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.medium) {

                        // Banner — stesso stile del system message in ConversationView
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
                                FilteredConversationCard(
                                    conversation: convo,
                                    currentUserId: currentUserId,
                                    onUnfilter: {
                                        viewModel.unfilterConversation(conversationId: convo.id)
                                    },
                                    onDelete: {
                                        viewModel.deleteConversation(convo)
                                    }
                                )
                                .onTapGesture {
                                    selectedConversation = convo
                                }
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

            // Placeholder per centrare il titolo
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

// MARK: - Card

private struct FilteredConversationCard: View {
    let conversation: Conversation
    let currentUserId: String
    let onUnfilter: () -> Void
    let onDelete: () -> Void

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

            // Motivazione AI — rossa, centrata, dentro la card
            if !conversation.filterReason.isEmpty {
                Rectangle()
                    .fill(Color.red.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, DesignSystem.Spacing.standard)

                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text(conversation.filterReason)
                        .font(.system(size: 12, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
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
        .contextMenu {
            Button {
                onUnfilter()
            } label: {
                Label(String(localized: "messages.not_spam", defaultValue: "Not Spam"),
                      systemImage: "checkmark.shield")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "common.delete"), systemImage: "trash")
            }
        }
    }
}
