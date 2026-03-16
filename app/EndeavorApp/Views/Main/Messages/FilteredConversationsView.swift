import SwiftUI

struct FilteredConversationsView: View {
    @EnvironmentObject private var viewModel: ConversationsViewModel
    @State private var selectedConversation: Conversation? = nil
    private let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {

                // Spiegazione
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text(String(localized: "messages.filtered_info",
                                defaultValue: "These conversations were flagged by AI as potentially irrelevant or promotional."))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(DesignSystem.Spacing.standard)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

                // Lista conversazioni filtrate
                VStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(viewModel.filteredConversations) { convo in
                        VStack(alignment: .leading, spacing: 0) {
                            SwipeableConversationRow(
                                conversation: convo,
                                currentUserId: currentUserId,
                                onDelete: { /* gestione eliminazione */ },
                                onTogglePin: { }
                            )
                            
                            if !convo.filterReason.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 9))
                                    Text(convo.filterReason)
                                        .font(.system(size: 11, design: .rounded))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                                .padding(.leading, DesignSystem.Spacing.xLarge) // Allineato all'avatar indicativamente
                                .padding(.bottom, DesignSystem.Spacing.standard)
                                .padding(.top, -DesignSystem.Spacing.standard) // Tira su il badge sotto il testo
                                .zIndex(1) // Teniamolo sopra a logiche di clip del row eventuale
                            }
                        }
                        .contextMenu {
                            Button {
                                viewModel.unfilterConversation(conversationId: convo.id)
                            } label: {
                                Label(String(localized: "messages.not_spam", defaultValue: "Not Spam"),
                                      systemImage: "checkmark.shield")
                            }
                        }
                        .onTapGesture {
                            selectedConversation = convo
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.large)
        }
        .navigationTitle(String(localized: "messages.filtered", defaultValue: "Filtered"))
        .navigationBarTitleDisplayMode(.large)
        .background(Color.background.edgesIgnoringSafeArea(.all))
        .navigationDestination(item: $selectedConversation) { convo in
            ConversationView(conversation: convo, currentUserId: currentUserId)
        }
    }
}
