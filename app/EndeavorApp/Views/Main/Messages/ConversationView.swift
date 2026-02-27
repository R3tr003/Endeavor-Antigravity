import SwiftUI

struct ConversationView: View {
    let conversation: Conversation
    let currentUserId: String

    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var messageText: String = ""
    @State private var showConversationStarters: Bool = false
    @FocusState private var isInputFocused: Bool

    init(conversation: Conversation, currentUserId: String) {
        self.conversation = conversation
        self.currentUserId = currentUserId

        // Calcola recipientId qui per passarlo al ViewModel
        let recipientId = conversation.participantIds.first { $0 != currentUserId } ?? ""

        self._viewModel = StateObject(wrappedValue: ConversationViewModel(
            conversationId: conversation.id,
            currentUserId: currentUserId,
            recipientId: recipientId
        ))
    }

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

    // MARK: - Header Bar

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

            let imageUrl = viewModel.recipientProfile?.profileImageUrl ?? conversation.otherParticipantImageUrl
            let accentColor = conversation.accentColor(currentUserId: currentUserId)
            let currentName = viewModel.recipientProfile?.fullName ?? conversation.otherParticipantName

            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                if imageUrl.isEmpty {
                    Text(getInitials(from: currentName))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                } else {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                        default:
                            Text(getInitials(from: currentName))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .frame(width: 38, height: 38)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(currentName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    // Se il profilo non è ancora caricato e il nome è vuoto/loading, mostra placeholder animato
                    .redacted(reason: viewModel.recipientProfile == nil && conversation.otherParticipantName == "Loading..." ? .placeholder : [])
                Group {
                    let isLoadingCompany = (viewModel.recipientProfile != nil && viewModel.recipientCompanyName == nil)
                    
                    if isLoadingCompany {
                        Text("Loading role...")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                            .lineLimit(1)
                            .redacted(reason: .placeholder)
                    } else {
                        let company = viewModel.recipientCompanyName ?? ""
                        let role = viewModel.recipientProfile?.role ?? conversation.otherParticipantRole
                        let location = viewModel.recipientProfile?.location ?? ""
                        
                        let mainText = !company.isEmpty ? company : role
                        let subtitle = [mainText, location].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " • ")
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                                .lineLimit(1)
                        }
                    }
                }
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

    // MARK: - Starters Panel (invariato rispetto all'attuale)

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

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding(.top, DesignSystem.Spacing.xxLarge)
                    } else {
                        // Empty state
                        if !viewModel.isLoading && viewModel.messages.isEmpty {
                            VStack(spacing: DesignSystem.Spacing.medium) {
                                Spacer().frame(height: DesignSystem.Spacing.xxLarge)
                                ZStack {
                                    Circle()
                                        .fill(Color.brandPrimary.opacity(0.1))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 26))
                                        .foregroundColor(.brandPrimary.opacity(0.6))
                                }
                                VStack(spacing: DesignSystem.Spacing.xSmall) {
                                    Text("Start the conversation")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Send a message to connect with\n\(viewModel.recipientProfile?.fullName ?? "this person").")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        }

                        // Lista messaggi (visibile quando messages non è vuoto)
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(viewModel.messages) { msg in
                                let fromMe = viewModel.isFromMe(msg)
                                HStack {
                                    if fromMe { Spacer() }
                                    VStack(alignment: fromMe ? .trailing : .leading, spacing: 4) {
                                        Text(msg.text)
                                            .font(.system(size: 15, design: .rounded))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .foregroundColor(fromMe ? .white : .primary)
                                            .background(
                                                fromMe ? Color.brandPrimary : Color.clear,
                                                in: RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                    corners: [.topLeft, .topRight, fromMe ? .bottomLeft : .bottomRight])
                                            )
                                            .background(
                                                fromMe
                                                    ? Color.clear
                                                    : (colorScheme == .dark
                                                        ? Color(UIColor.systemBackground).opacity(0.15)
                                                        : Color(hex: "E0F0EE")),
                                                in: RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                    corners: [.topLeft, .topRight, fromMe ? .bottomLeft : .bottomRight])
                                            )
                                            .overlay(
                                                RoundedCornerShape(radius: DesignSystem.CornerRadius.large,
                                                    corners: [.topLeft, .topRight, fromMe ? .bottomLeft : .bottomRight])
                                                    .stroke(
                                                        fromMe
                                                            ? Color.clear
                                                            : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.brandPrimary.opacity(0.2)),
                                                        lineWidth: 1
                                                    )
                                            )

                                        Text(msg.displayTime)
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: geometry.size.width * 0.72, alignment: fromMe ? .trailing : .leading)
                                    if !fromMe { Spacer() }
                                }
                                .id(msg.id)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, DesignSystem.Spacing.large)
                    }
                }
                .onAppear {
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

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
                let text = messageText
                messageText = ""
                isInputFocused = false
                viewModel.sendMessage(text: text)
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

    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ").filter { !$0.isEmpty }
        if components.isEmpty { return "" }
        if components.count == 1 {
            return String(components[0].prefix(2)).uppercased()
        }
        let first = components[0].prefix(1)
        let last = components[components.count - 1].prefix(1)
        return "\(first)\(last)".uppercased()
    }


// MARK: - RoundedCornerShape (invariato)
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
