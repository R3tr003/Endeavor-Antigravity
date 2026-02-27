import SwiftUI

struct MockMessage: Identifiable {
    let id: UUID
    let text: String
    let isFromMe: Bool
    let time: String

    static let mockMessages: [MockMessage] = [
        MockMessage(id: UUID(), text: "Hi! I saw your profile on Endeavor — your experience scaling SaaS companies is exactly what I'm looking for.", isFromMe: true, time: "10:32"),
        MockMessage(id: UUID(), text: "Happy to connect! What stage are you at right now?", isFromMe: false, time: "10:35"),
        MockMessage(id: UUID(), text: "We're at about 45 employees, just closed our Series A. Struggling with the jump to 100+.", isFromMe: true, time: "10:37"),
        MockMessage(id: UUID(), text: "That's a critical inflection point. Happy to share what worked for us at the 50-person milestone.", isFromMe: false, time: "10:39"),
    ]
}

struct ConversationView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var showConversationStarters: Bool = false
    @State private var messages: [MockMessage] = MockMessage.mockMessages
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    let conversationStarters: [String] = [
        "Seeking advice on...",
        "Exploring partnership opportunities...",
        "Looking for expertise in...",
        "Would love to connect about...",
        "I have a challenge around...",
    ]

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerBar
                
                if showConversationStarters {
                    startersPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                messagesScrollView
                inputBar
            }
        }
        .onTapGesture {
            isInputFocused = false
            withAnimation { showConversationStarters = false }
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

            Circle()
                .fill(conversation.accentColor.opacity(0.15))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(conversation.accentColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(conversation.role)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(conversation.accentColor)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text("Schedule")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.brandPrimary)
                .padding(.vertical, 7)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .overlay(Capsule().stroke(Color.brandPrimary, lineWidth: 1))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.standard)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
    }

    private var startersPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.small) {
                ForEach(conversationStarters, id: \.self) { starter in
                    Button(action: {
                        messageText = starter
                        withAnimation { showConversationStarters = false }
                        isInputFocused = true
                    }) {
                        Text(starter)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.brandPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.brandPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(Color.brandPrimary.opacity(0.15), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
        }
        .padding(.vertical, DesignSystem.Spacing.standard)
        .background(.regularMaterial)
        .overlay(
            VStack {
                HStack {
                    Text("CONVERSATION STARTERS")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.secondary)
                        .padding(.leading, DesignSystem.Spacing.medium)
                        .padding(.top, DesignSystem.Spacing.xSmall)
                    Spacer()
                }
                Spacer()
            }
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.brandPrimary.opacity(0.2)), alignment: .bottom)
    }

    private var messagesScrollView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.isFromMe { Spacer() }
                                
                                VStack(alignment: msg.isFromMe ? .trailing : .leading, spacing: 4) {
                                    Text(msg.text)
                                        .font(.system(size: 15, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .foregroundColor(msg.isFromMe ? .white : .primary)
                                        .background(
                                            msg.isFromMe ? Color.brandPrimary : Color.clear,
                                            in: RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                corners: [.topLeft, .topRight, msg.isFromMe ? .bottomLeft : .bottomRight])
                                        )
                                        .background(
                                            msg.isFromMe
                                                ? Color.clear
                                                : (colorScheme == .dark
                                                    ? Color(UIColor.systemBackground).opacity(0.15)
                                                    : Color(hex: "E0F0EE")),  // tinta teal chiara, visibile su sfondo EFF5F4
                                            in: RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                corners: [.topLeft, .topRight, msg.isFromMe ? .bottomLeft : .bottomRight])
                                        )
                                        .overlay(
                                            RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                corners: [.topLeft, .topRight, msg.isFromMe ? .bottomLeft : .bottomRight])
                                                .stroke(
                                                    msg.isFromMe
                                                        ? Color.clear
                                                        : (colorScheme == .dark ? Color.borderGlare.opacity(0.12) : Color.brandPrimary.opacity(0.2)),
                                                    lineWidth: 1
                                                )
                                        )
                                    
                                    Text(msg.time)
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: geometry.size.width * 0.72, alignment: msg.isFromMe ? .trailing : .leading)
                                
                                if !msg.isFromMe { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.large)
                }
                .onAppear {
                    if let lastId = messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) {
                    if let lastId = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showConversationStarters.toggle()
                }
            }) {
                Image(systemName: showConversationStarters ? "xmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.brandPrimary)
            }

            TextField("Type a message...", text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
                .focused($isInputFocused)
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(isInputFocused ? Color.brandPrimary.opacity(0.5) : Color.borderGlare.opacity(0.15), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                )

            Button(action: {
                guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let newMsg = MockMessage(id: UUID(), text: messageText, isFromMe: true, time: "Now")
                withAnimation { messages.append(newMsg) }
                messageText = ""
                isInputFocused = false
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? .secondary.opacity(0.4)
                        : .brandPrimary)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .top)
    }
}

// Swift UI helper for targeted corner radiuses
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    ConversationView(conversation: Conversation(
        id: UUID(), name: "Maria Lopez", role: "SaaS Scaling Expert",
        lastMessage: "Happy to share what worked for us.",
        time: "2m", unreadCount: 2, initials: "ML", accentColor: Color.brandPrimary
    ))
}
