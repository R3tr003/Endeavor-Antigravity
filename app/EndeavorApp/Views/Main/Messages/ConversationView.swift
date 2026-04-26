import SwiftUI
import SDWebImageSwiftUI
import UniformTypeIdentifiers
import Photos

struct ConversationView: View {
    let conversation: Conversation
    let currentUserId: String

    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var conversationsViewModel: ConversationsViewModel
    @State private var messageText: String = ""
    @State private var showAttachmentPanel: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var showScheduleMeeting: Bool = false
    @State private var proposeNewForEvent: CalendarEvent? = nil
    @State private var showNotEnoughMessagesAlert: Bool = false
    @State private var showRecipientProfile: Bool = false

    // Image viewer state
    @State private var selectedImageIndex: Int? = nil

    @FocusState private var isInputFocused: Bool

    init(conversation: Conversation, currentUserId: String) {
        self.conversation = conversation
        self.currentUserId = currentUserId

        let recipientId = conversation.participantIds.first { $0 != currentUserId } ?? ""

        self._viewModel = StateObject(wrappedValue: ConversationViewModel(
            conversationId: conversation.id,
            currentUserId: currentUserId,
            recipientId: recipientId
        ))
    }

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerBar
                messagesScrollView
            }
        }
        .onTapGesture {
            isInputFocused = false
            withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
        }
        // Image Picker (Photo Library)
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary, allowsEditing: false)
        }
        // Camera Picker
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(image: $selectedImage, sourceType: .camera, allowsEditing: false)
        }
        // Document Picker
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedUrl = urls.first else { return }
                viewModel.uploadAndSendDocument(url: selectedUrl, documentName: selectedUrl.lastPathComponent)
            case .failure(let error):
                print("Error picking document: \(error)")
            }
        }
        .sheet(isPresented: $showScheduleMeeting) {
            ScheduleMeetingView(
                conversationId: conversation.id,
                currentUserId: currentUserId,
                recipientId: viewModel.recipientId,
                recipientName: viewModel.recipientProfile?.fullName ?? conversation.otherParticipantName,
                existingEvents: viewModel.myCalendarEvents
            )
        }
        .sheet(item: $proposeNewForEvent) { event in
            ScheduleMeetingView(
                conversationId: conversation.id,
                currentUserId: currentUserId,
                recipientId: viewModel.recipientId,
                recipientName: viewModel.recipientProfile?.fullName ?? conversation.otherParticipantName,
                existingEvents: viewModel.myCalendarEvents,
                existingEvent: event
            )
        }
        .sheet(isPresented: $showRecipientProfile) {
            if let profile = viewModel.recipientProfile {
                ChatUserProfileView(
                    profile: profile,
                    companyName: viewModel.recipientCompanyName
                )
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImageIndex.map { IdentifiableInt(value: $0) } },
            set: { selectedImageIndex = $0?.value }
        )) { item in
            ChatImageViewerView(
                images: imageItems,
                initialIndex: item.value
            )
        }
        .alert(
            String(localized: "common.error", defaultValue: "Error"),
            isPresented: Binding(
                get: { viewModel.appError != nil },
                set: { if !$0 { viewModel.appError = nil } }
            ),
            presenting: viewModel.appError
        ) { _ in
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            String(localized: "schedule.not_ready_title", defaultValue: "Almost there!"),
            isPresented: $showNotEnoughMessagesAlert
        ) {
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: {
            Text(String(localized: "schedule.not_enough_messages",
                        defaultValue: "Keep the conversation going — you need at least 10 messages exchanged (3 from each side) before scheduling a meeting."))
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

            Button(action: {
                if viewModel.recipientProfile != nil { showRecipientProfile = true }
            }) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 38, height: 38)

                        if imageUrl.isEmpty {
                            Text(getInitials(from: currentName))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(accentColor)
                        } else {
                            WebImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 38, height: 38)
                                    .clipShape(Circle())
                            } placeholder: {
                                EmptyView()
                            }
                            .transition(.fade(duration: 0))
                        }
                    }
                    .transaction { $0.animation = nil }
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .redacted(reason: viewModel.recipientProfile == nil && conversation.otherParticipantName == "Loading..." ? .placeholder : [])
                        Group {
                            let isLoadingCompany = (viewModel.recipientProfile != nil && viewModel.recipientCompanyName == nil)

                            if isLoadingCompany {
                                Text(String(localized: "messages.loading_company", defaultValue: "Loading company..."))
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                                    .lineLimit(1)
                                    .redacted(reason: .placeholder)
                            } else {
                                let company = viewModel.recipientCompanyName ?? conversation.otherParticipantCompany
                                let location = viewModel.recipientProfile?.location ?? ""

                                let subtitle = [company, location].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " • ")

                                if !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(conversation.accentColor(currentUserId: currentUserId))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: {
                let totalMessages = viewModel.messages.filter { !$0.isSystemMessage }.count
                let myMessages = viewModel.messages.filter { $0.senderId == currentUserId && !$0.isSystemMessage }.count
                let theirMessages = totalMessages - myMessages
                guard totalMessages >= 10 && myMessages >= 3 && theirMessages >= 3 else {
                    AnalyticsService.shared.logMeetingScheduleBlocked(
                        messageCount: totalMessages,
                        myCount: myMessages,
                        theirCount: theirMessages
                    )
                    showNotEnoughMessagesAlert = true
                    return
                }
                AnalyticsService.shared.logMeetingScheduleOpened(conversationMessageCount: totalMessages)
                viewModel.triggerAIRecheckIfNeeded(conversation: conversation)
                showScheduleMeeting = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(String(localized: "messages.schedule", defaultValue: "Schedule"))
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

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding(.top, DesignSystem.Spacing.xxLarge)
                    } else {
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
                                    Text(String(localized: "messages.start_the_conversation", defaultValue: "Start the conversation"))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(String(localized: "messages.send_message_connect", defaultValue: "Send a message to connect with\n\(viewModel.recipientProfile?.fullName ?? "this person")."))
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        }

                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { idx, msg in
                                // Date separator pill — shown when the day changes between messages
                                let prevMsg = idx > 0 ? viewModel.messages[idx - 1] : nil
                                let isNewDay = prevMsg.map {
                                    !Calendar.current.isDate(msg.createdAt, inSameDayAs: $0.createdAt)
                                } ?? true
                                if isNewDay {
                                    dateSeparatorPill(date: msg.createdAt)
                                }

                                if msg.messageType == .meetingInvite {
                                    let fromMe = viewModel.isFromMe(msg)
                                    HStack {
                                        if fromMe { Spacer() }
                                        MeetingInviteCard(
                                            message: msg,
                                            isFromMe: fromMe,
                                            currentUserId: currentUserId,
                                            onAccept: { resetSpinner in
                                                guard let eventId = msg.meetingEventId else { resetSpinner(); return }
                                                viewModel.acceptMeeting(eventId: eventId, onFailure: resetSpinner)
                                            },
                                            onDecline: {
                                                guard let eventId = msg.meetingEventId else { return }
                                                viewModel.declineMeeting(eventId: eventId)
                                            },
                                            onProposeNew: { event in
                                                proposeNewForEvent = event
                                            }
                                        )
                                        .frame(maxWidth: geometry.size.width * 0.72, alignment: fromMe ? .trailing : .leading)
                                        if !fromMe { Spacer() }
                                    }
                                    .id(msg.id)
                                } else if msg.isSystemMessage {
                                    let isWarning = msg.text.hasPrefix("⚠️")
                                    let systemText: String = {
                                        if msg.text == "ai_filter_warning" {
                                            let flaggedBySender = prevMsg?.senderId == currentUserId
                                            return flaggedBySender
                                                ? String(localized: "messages.ai_filter_warning_sender", defaultValue: "Your message was flagged by Endeavor's AI filter as potentially promotional or irrelevant to our network's purpose.")
                                                : String(localized: "messages.ai_filter_warning_receiver", defaultValue: "The message above was flagged by Endeavor's AI filter as potentially promotional or irrelevant to our network's purpose.")
                                        }
                                        return msg.text.replacingOccurrences(of: "⚠️ ", with: "")
                                    }()
                                    HStack(alignment: .center, spacing: 6) {
                                        Image(systemName: isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(isWarning ? .red : .secondary)
                                        Text(systemText)
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.medium)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(
                                        isWarning ? Color.red.opacity(0.12) : Color(.systemGray5).opacity(0.5),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isWarning ? Color.red.opacity(0.3) : Color(.systemGray4).opacity(0.6),
                                                lineWidth: 1
                                            )
                                    )
                                    .padding(.horizontal, DesignSystem.Spacing.large)
                                    .padding(.vertical, DesignSystem.Spacing.small)
                                    .id(msg.id)
                                } else {
                                    let fromMe = viewModel.isFromMe(msg)
                                    HStack {
                                        if fromMe { Spacer() }
                                        VStack(alignment: fromMe ? .trailing : .leading, spacing: 4) {
                                        if let documentUrl = msg.documentUrl, let documentName = msg.documentName {
                                            Button(action: {
                                                if let url = URL(string: documentUrl) {
                                                    UIApplication.shared.open(url)
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "doc.text.fill")
                                                        .font(.system(size: 24))
                                                    Text(documentName)
                                                        .lineLimit(1)
                                                        .font(.system(size: 14, design: .rounded))
                                                }
                                                .padding(12)
                                                .foregroundColor(fromMe ? .white : .brandPrimary)
                                                .background(fromMe ? Color.brandPrimary.opacity(0.8) : Color.borderGlare.opacity(0.1))
                                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                            }
                                            .contextMenu {
                                                Button {
                                                    if let url = URL(string: documentUrl) {
                                                        UIApplication.shared.open(url)
                                                    }
                                                } label: {
                                                    Label(String(localized: "messages.download_document", defaultValue: "Download Document"), systemImage: "arrow.down.circle")
                                                }
                                            }
                                        }

                                        if let imageUrl = msg.imageUrl {
                                            WebImage(url: URL(string: imageUrl))
                                                .resizable()
                                                .indicator(.activity)
                                                .scaledToFill()
                                                .frame(width: 200, height: 200)
                                                .clipped()
                                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                                .padding(.bottom, msg.text.isEmpty ? 0 : 4)
                                                .onTapGesture {
                                                    selectedImageIndex = imageItems.firstIndex(where: { $0.url == imageUrl })
                                                }
                                                .contextMenu {
                                                    Button {
                                                        selectedImageIndex = imageItems.firstIndex(where: { $0.url == imageUrl })
                                                    } label: {
                                                        Label(String(localized: "messages.view_photo", defaultValue: "View Photo"),
                                                              systemImage: "photo")
                                                    }

                                                    Button {
                                                        saveImageDirectly(imageUrl: imageUrl)
                                                    } label: {
                                                        Label(String(localized: "messages.save_to_photos", defaultValue: "Save to Photos"),
                                                              systemImage: "arrow.down.circle")
                                                    }

                                                    Button {
                                                        shareImageDirectly(imageUrl: imageUrl)
                                                    } label: {
                                                        Label(String(localized: "messages.share", defaultValue: "Share"),
                                                              systemImage: "square.and.arrow.up")
                                                    }
                                                }
                                        }

                                        if !msg.text.isEmpty {
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
                                                                : Color.brandPrimary.opacity(0.55),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }

                                        let recipientId = conversation.participantIds.first(where: { $0 != currentUserId }) ?? ""
                                        if fromMe {
                                            HStack(spacing: 3) {
                                                Text(msg.displayTime)
                                                    .font(.system(size: 11, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                ReceiptStatusView(
                                                    status: msg.receiptStatus(
                                                        currentUserId: currentUserId,
                                                        recipientId: recipientId
                                                    )
                                                )
                                            }
                                        } else {
                                            Text(msg.displayTime)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: geometry.size.width * 0.72, alignment: fromMe ? .trailing : .leading)
                                    if !fromMe { Spacer() }
                                }
                                .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, DesignSystem.Spacing.large)
                    }
                }
                .defaultScrollAnchor(.bottom)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.last?.id) { _, lastId in
                    guard let lastId else { return }
                    // Small delay lets SwiftUI lay out the new message before scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .task {
                    await viewModel.markAsDelivered()
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
    }

    // MARK: - Bottom Bar (input + panels)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if viewModel.isUploadingMedia {
                ProgressView(String(localized: "messages.uploading_media", defaultValue: "Uploading Media..."))
                    .font(.system(size: 13, design: .rounded))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            if let image = selectedImage {
                imagePreviewPanel(image: image)
            }
            inputBar
            if showAttachmentPanel {
                attachmentPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(.all, edges: .bottom)
        }
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .top)
    }

    // MARK: - Selected Image Preview

    private func imagePreviewPanel(image: UIImage) -> some View {
        HStack {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                    .clipped()

                Button {
                    withAnimation { selectedImage = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black.opacity(0.6))
                        .background(Circle().fill(.white))
                }
                .offset(x: 5, y: -5)
            }
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            // + / keyboard toggle button
            Button(action: {
                if showAttachmentPanel {
                    withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isInputFocused = true }
                } else {
                    isInputFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = true }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(showAttachmentPanel ? Color.brandPrimary : Color(.systemGray5).opacity(0.8))
                        .frame(width: 36, height: 36)
                    Image(systemName: showAttachmentPanel ? "keyboard.fill" : "plus")
                        .font(.system(size: showAttachmentPanel ? 13 : 15, weight: .semibold))
                        .foregroundColor(showAttachmentPanel ? .white : .primary)
                        .scaleEffect(showAttachmentPanel ? 0.95 : 1.0)
                }
            }

            // Text field
            TextField(String(localized: "messages.type_message", defaultValue: "Type a message..."), text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
                .focused($isInputFocused)
                .onChange(of: isInputFocused) { _, focused in
                    if focused { withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false } }
                }
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(isInputFocused ? Color.brandPrimary.opacity(0.5) : Color.borderGlare.opacity(0.15), lineWidth: 1)
                        .animation(.easeInOut(duration: 0.2), value: isInputFocused)
                )

            // Send/Camera button
            let canSend = !messageText.trimmingCharacters(in: .whitespaces).isEmpty || selectedImage != nil
            Button(action: {
                if canSend {
                    let text = messageText
                    messageText = ""
                    isInputFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                    if let finalImage = selectedImage {
                        selectedImage = nil
                        viewModel.uploadAndSendImage(finalImage, additionalText: text)
                    } else {
                        viewModel.sendMessage(text: text)
                    }
                } else {
                    // No text: open camera directly
                    isInputFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showCameraPicker = true }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(canSend ? Color.brandPrimary : Color(.systemGray5).opacity(0.8))
                        .frame(width: 36, height: 36)
                    if canSend {
                        Image("icon_send")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, 7)
    }

    // MARK: - Attachment Panel

    private var attachmentPanel: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            attachmentOption(
                icon: "photo.on.rectangle.angled",
                label: String(localized: "messages.photo_library", defaultValue: "Photos"),
                gradient: [Color(hex: "3B82F6"), Color(hex: "6366F1")]
            ) {
                withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showPhotoPicker = true }
            }

            attachmentOption(
                icon: "camera.fill",
                label: String(localized: "messages.camera", defaultValue: "Camera"),
                gradient: [Color(.systemGray2), Color(.systemGray3)]
            ) {
                withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showCameraPicker = true }
            }

            attachmentOption(
                icon: "folder.fill",
                label: String(localized: "messages.file", defaultValue: "File"),
                gradient: [Color(hex: "10B981"), Color(hex: "059669")]
            ) {
                withAnimation(.easeInOut(duration: 0.25)) { showAttachmentPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { showDocumentPicker = true }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, 20)
        .padding(.bottom, 28)
    }

    @ViewBuilder
    private func attachmentOption(
        icon: String,
        label: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: gradient.first?.opacity(0.35) ?? .clear, radius: 8, x: 0, y: 4)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Separator

    @ViewBuilder
    private func dateSeparatorPill(date: Date) -> some View {
        Text(dateSeparatorLabel(for: date))
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DesignSystem.Spacing.xSmall)
    }

    private func dateSeparatorLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "common.today", defaultValue: "Today")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "common.yesterday", defaultValue: "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            let isThisYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
            // setLocalizedDateFormatFromTemplate auto-localizes: "26 Mar" in EN, "26 mar" in IT, etc.
            formatter.setLocalizedDateFormatFromTemplate(isThisYear ? "dMMM" : "dMMMy")
            return formatter.string(from: date)
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

    // MARK: - Image Viewer Helpers

    private struct IdentifiableInt: Identifiable {
        let id = UUID()
        let value: Int
    }

    /// All image messages in this conversation, in order, for the viewer's thumbnail strip.
    private var imageItems: [ChatImageItem] {
        viewModel.messages.compactMap { msg in
            guard let imageUrl = msg.imageUrl else { return nil }
            let name = viewModel.isFromMe(msg)
                ? String(localized: "messages.you", defaultValue: "You")
                : (viewModel.recipientProfile?.fullName ?? conversation.otherParticipantName)
            return ChatImageItem(url: imageUrl, senderName: name, timestamp: msg.createdAt)
        }
    }

    private func saveImageDirectly(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        AnalyticsService.shared.logChatImageSaved()
                    }
                }
            }
        }.resume()
    }

    private func shareImageDirectly(imageUrl: String) {
        guard let url = URL(string: imageUrl) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }
        }.resume()
    }
}

// MARK: - RoundedCornerShape
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
