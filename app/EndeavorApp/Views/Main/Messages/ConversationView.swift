import SwiftUI
import SDWebImageSwiftUI
import UniformTypeIdentifiers

struct ConversationView: View {
    let conversation: Conversation
    let currentUserId: String

    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var messageText: String = ""
    @State private var showMediaMenu: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    
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

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerBar
                messagesScrollView
                if viewModel.isUploadingMedia {
                    ProgressView("Uploading Media...")
                        .font(.system(size: 13, design: .rounded))
                        .padding(.vertical, 8)
                }
                
                if let image = selectedImage {
                    imagePreviewPanel(image: image)
                }
                
                inputBar
            }
        }
        .onTapGesture {
            isInputFocused = false
            withAnimation { showMediaMenu = false }
        }
        // Action Sheet per selezione Media
        .confirmationDialog("Choose Attachment", isPresented: $showMediaMenu, titleVisibility: .visible) {
            Button("Photo Library") {
                showPhotoPicker = true
            }
            Button("Files & Documents") {
                showDocumentPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        // Image Picker
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary, allowsEditing: false)
        }
        // Document Picker
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item], // General fallback for all file types
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedUrl = urls.first else { return }
                // Trigger upload function directly since we don't preview PDFs in the chat bar right now
                viewModel.uploadAndSendDocument(url: selectedUrl, documentName: selectedUrl.lastPathComponent)
            case .failure(let error):
                print("Error picking document: \(error)")
            }
        }
        // Mostra errori dal ViewModel (ex. problemi di permessi o Firebase)
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.appError != nil },
                set: { if !$0 { viewModel.appError = nil } }
            ),
            presenting: viewModel.appError
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
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
                    WebImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 38, height: 38)
                            .clipShape(Circle())
                    } placeholder: {
                        Text(getInitials(from: currentName))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
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
                        Text("Loading company...")
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
        .background(.regularMaterial)
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
                                        if let documentUrl = msg.documentUrl, let documentName = msg.documentName {
                                            // Document Bubble
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
                                                    Label("Download Document", systemImage: "arrow.down.circle")
                                                }
                                            }
                                        }

                                        if let imageUrl = msg.imageUrl, let url = URL(string: imageUrl) {
                                            // Image Bubble
                                            WebImage(url: url)
                                                .resizable()
                                                .indicator(.activity)
                                                .scaledToFit()
                                                .frame(maxWidth: 200, maxHeight: 200)
                                                .cornerRadius(DesignSystem.CornerRadius.medium)
                                                .padding(.bottom, msg.text.isEmpty ? 0 : 4)
                                                .onTapGesture {
                                                    UIApplication.shared.open(url)
                                                }
                                                .contextMenu {
                                                    Button {
                                                        UIApplication.shared.open(url)
                                                    } label: {
                                                        Label("View & Download", systemImage: "arrow.down.circle")
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
                                                                : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.brandPrimary.opacity(0.2)),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }

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
                // Remove input focus to show native action sheet safely
                isInputFocused = false
                showMediaMenu = true
            }) {
                Image(systemName: "plus.circle.fill")
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
                
                if let finalImage = selectedImage {
                    selectedImage = nil
                    viewModel.uploadAndSendImage(finalImage, additionalText: text)
                } else {
                    viewModel.sendMessage(text: text)
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        (messageText.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage == nil)
                        ? .secondary.opacity(0.4)
                        : .brandPrimary
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty && selectedImage == nil)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .top)
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
