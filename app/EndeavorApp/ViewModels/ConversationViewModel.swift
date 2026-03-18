import Foundation
import FirebaseFirestore
import FirebasePerformance
import Combine

class ConversationViewModel: ObservableObject {

    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var appError: AppError?
    @Published var recipientProfile: UserProfile?
    @Published var recipientCompanyName: String? = nil
    @Published var myCalendarEvents: [CalendarEvent] = []

    // Upload state
    @Published var isUploadingMedia: Bool = false

    private let repository: MessagesRepositoryProtocol
    private let storageRepository: StorageRepositoryProtocol
    private let calendarRepository: CalendarRepositoryProtocol = FirebaseCalendarRepository()
    private var messagesListener: ListenerRegistration?
    private var loadMessagesTrace: Trace?
    private var fetchProfileTrace: Trace?
    private var isFirstMessagesLoad = true
    /// Tracks when the conversation was opened, for profile_view_duration event.
    private let conversationOpenedAt = Date()
    /// Guards first_message_sent so it fires exactly once per user lifetime (checked against message count).
    private var firstMessageEventFired = false

    let conversationId: String
    let currentUserId: String
    let recipientId: String

    init(
        conversationId: String,
        currentUserId: String,
        recipientId: String,
        repository: MessagesRepositoryProtocol = FirebaseMessagesRepository(),
        storageRepository: StorageRepositoryProtocol = FirebaseStorageRepository()
    ) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        self.repository = repository
        self.storageRepository = storageRepository
        startListening()
        fetchRecipientProfile()
        fetchMyCalendarEvents()
        // conversation_opened is now logged in startListening() after the first successful load (Bug Fix #2)
    }

    deinit {
        messagesListener?.remove()
        // Log how long the user had this conversation open (a proxy for profile view time).
        let seconds = Int(Date().timeIntervalSince(conversationOpenedAt))
        if seconds > 1 {
            AnalyticsService.shared.logProfileViewDuration(seconds: seconds, userId: recipientId)
        }
    }

    // MARK: - Listener

    func startListening() {
        isLoading = true
        messagesListener?.remove()

        // Trace solo sul primo caricamento — misura latenza + cattura CPU/RAM nel Sessions panel
        if isFirstMessagesLoad {
            loadMessagesTrace = Performance.startTrace(name: "Load_Messages_Duration")
        }

        messagesListener = repository.listenToMessages(
            conversationId: conversationId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let msgs):
                self.messages = msgs
                if self.isFirstMessagesLoad {
                    self.isFirstMessagesLoad = false
                    if let trace = self.loadMessagesTrace {
                        trace.incrementMetric("message_count", by: Int64(msgs.count))
                        trace.stop()
                        self.loadMessagesTrace = nil
                    }
                    // Bug Fix #2: log conversation_opened only when the first batch successfully loads
                    AnalyticsService.shared.logConversationOpened()
                }
                // Marca come letti all'apertura e ad ogni nuovo messaggio
                Task { await self.markMessagesAsRead() }
            case .failure(let error):
                self.loadMessagesTrace?.stop()
                self.loadMessagesTrace = nil
                self.isFirstMessagesLoad = false
                self.appError = .unknown(reason: error.localizedDescription)
            }
        }
    }

    // MARK: - Send

    func sendMessage(
        text: String,
        imageUrl: String? = nil,
        documentUrl: String? = nil,
        documentName: String? = nil
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty && imageUrl == nil && documentUrl == nil { return }

        // Determina il tipo di messaggio per analytics
        let msgType: AnalyticsService.MessageType
        switch (imageUrl != nil, documentUrl != nil, !trimmed.isEmpty) {
        case (true, _, true):   msgType = .textImage
        case (_, true, true):   msgType = .textDocument
        case (true, _, false):  msgType = .image
        case (_, true, false):  msgType = .document
        default:                msgType = .text
        }
        AnalyticsService.shared.logMessageSent(type: msgType, characterCount: trimmed.count)

        // Conversion event: fires once — only when this is the user's very first message ever sent.
        // We detect this by checking that there are no prior messages in the conversation.
        if !firstMessageEventFired && messages.isEmpty {
            firstMessageEventFired = true
            AnalyticsService.shared.logFirstMessageSent()
        }

        repository.sendMessage(
            conversationId: conversationId,
            senderId: currentUserId,
            recipientId: recipientId,
            text: trimmed,
            imageUrl: imageUrl,
            documentUrl: documentUrl,
            documentName: documentName
        ) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Media Uploads
    
    func uploadAndSendImage(_ image: UIImage, additionalText: String = "") {
        DispatchQueue.main.async { self.isUploadingMedia = true }
        let path = "chat_media/\(conversationId)/\(UUID().uuidString).jpg"
        storageRepository.uploadImage(image: image, path: path) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploadingMedia = false
                switch result {
                case .success(let url):
                    AnalyticsService.shared.logMediaUploaded(type: "image")
                    self?.sendMessage(text: additionalText, imageUrl: url)
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
    
    func uploadAndSendDocument(url fileURL: URL, documentName: String) {
        DispatchQueue.main.async { self.isUploadingMedia = true }
        let fileExtension = fileURL.pathExtension
        let path = "chat_media/\(conversationId)/\(UUID().uuidString).\(fileExtension)"
        storageRepository.uploadDocument(url: fileURL, path: path) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploadingMedia = false
                switch result {
                case .success(let downloadUrl):
                    AnalyticsService.shared.logMediaUploaded(type: "document")
                    self?.sendMessage(text: "", documentUrl: downloadUrl, documentName: documentName)
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Read Receipts

    /// Marca i messaggi dell'altro partecipante come "consegnati" (aperto la chat).
    func markAsDelivered() async {
        await repository.markAsDelivered(
            conversationId: conversationId,
            currentUserId: currentUserId
        )
    }

    /// Marca i messaggi dell'altro partecipante come "letti" (e come consegnati per coerenza).
    func markMessagesAsRead() async {
        let hasUnread = messages.contains { !isFromMe($0) && !$0.readBy.contains(currentUserId) }
        await repository.markMessagesAsRead(
            conversationId: conversationId,
            currentUserId: currentUserId
        )
        // Azzera anche il badge unread nella conversazione
        repository.markConversationAsRead(
            conversationId: conversationId,
            userId: currentUserId
        ) { _ in }
        // Log solo se c'erano effettivamente messaggi non letti da marcare
        if hasUnread { AnalyticsService.shared.logMessagesRead() }
    }

    // MARK: - Meeting Responses

    // MARK: - Meeting Accept (Bug Fix #1: consolidated into one call site)

    /// Accepts a meeting and logs the event exactly once, regardless of link generation path.
    private func notifyMeetingAccepted(provider: CalendarEvent.MeetProvider) {
        AnalyticsService.shared.logMeetingAccepted(provider: provider.rawValue)
    }

    func acceptMeeting(eventId: String) {
        Firestore.firestore().collection("events").document(eventId).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            let data = snap?.data()
            let providerRaw = data?["meetProvider"] as? String ?? "none"
            let provider = CalendarEvent.MeetProvider(rawValue: providerRaw) ?? .none
            let existingLink = data?["meetLink"] as? String ?? ""

            // Sender already generated the link — just confirm the event, no need to regenerate.
            if !existingLink.isEmpty {
                self.calendarRepository.updateEventStatus(
                    eventId: eventId,
                    status: .confirmed,
                    meetLink: existingLink
                ) { [weak self] error in
                    if error != nil { self?.appError = .meetingUpdateFailed; return }
                    self?.notifyMeetingAccepted(provider: provider)
                }
                return
            }

            // No link yet — try to generate with the recipient's account.
            MeetProviderService.shared.generateMeetLink(
                eventId: eventId,
                provider: provider,
                userId: self.currentUserId
            ) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    // If the recipient has no Google account, accept anyway without a link.
                    if case AppError.meetGoogleAccountRequired = error {
                        self.calendarRepository.updateEventStatus(
                            eventId: eventId,
                            status: .confirmed,
                            meetLink: nil
                        ) { [weak self] updateError in
                            if updateError != nil { self?.appError = .meetingUpdateFailed; return }
                            self?.notifyMeetingAccepted(provider: provider)
                        }
                    } else {
                        self.appError = .unknown(reason: error.localizedDescription)
                    }

                case .success(let link):
                    self.calendarRepository.updateEventStatus(
                        eventId: eventId,
                        status: .confirmed,
                        meetLink: link.isEmpty ? nil : link
                    ) { [weak self] error in
                        guard let self = self else { return }
                        if error != nil { self.appError = .meetingUpdateFailed; return }
                        self.notifyMeetingAccepted(provider: provider)
                    }
                }
            }
        }
    }

    func triggerAIRecheckIfNeeded(conversation: Conversation) {
        MeetProviderService.shared.triggerAIRecheckIfNeeded(
            conversationId: conversation.id,
            filterCheckedAt: conversation.filterCheckedAt
        ) { wasFiltered in
            if wasFiltered {
                print("[ConversationViewModel] Conversation filtered by AI recheck")
            }
        }
    }

    func fetchMyCalendarEvents() {
        calendarRepository.fetchEvents(userId: currentUserId) { [weak self] result in
            if case .success(let events) = result {
                DispatchQueue.main.async {
                    self?.myCalendarEvents = events
                }
            }
        }
    }

    func declineMeeting(eventId: String) {
        calendarRepository.updateEventStatus(
            eventId: eventId,
            status: .cancelled,
            declinedBy: currentUserId
        ) { [weak self] error in
            guard let self = self else { return }
            if error != nil {
                self.appError = .meetingUpdateFailed
                return
            }
            MeetProviderService.shared.cancelGoogleCalendarEvent(eventId: eventId)
            AnalyticsService.shared.logMeetingDeclined()
        }
    }

    // MARK: - Helper

    /// Restituisce true se un messaggio è stato inviato dall'utente corrente
    func isFromMe(_ message: Message) -> Bool {
        return message.senderId == currentUserId
    }

    // MARK: - Fetch Recipient Profile
    private func fetchRecipientProfile() {
        fetchProfileTrace = Performance.startTrace(name: "Fetch_Recipient_Profile_Duration")
        repository.fetchUserProfile(userId: recipientId) { [weak self] result in
            self?.fetchProfileTrace?.stop()
            self?.fetchProfileTrace = nil
            if case .success(let profile) = result {
                DispatchQueue.main.async {
                    self?.recipientProfile = profile
                }
                
                // If using FirebaseMessagesRepository, try to fetch company name
                if let firebaseRepo = self?.repository as? FirebaseMessagesRepository {
                    firebaseRepo.fetchCompanyName(forUserId: self?.recipientId ?? "") { companyName in
                        DispatchQueue.main.async {
                            // Se nil, salviamo una stringa vuota per indicare che il fetch è finito e fermare l'animazione di caricamento
                            self?.recipientCompanyName = companyName ?? ""
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.recipientCompanyName = ""
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.recipientCompanyName = ""
                }
            }
        }
    }
}
