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
    
    // Upload state
    @Published var isUploadingMedia: Bool = false

    private let repository: MessagesRepositoryProtocol
    private let storageRepository: StorageRepositoryProtocol
    private var messagesListener: ListenerRegistration?
    private var loadMessagesTrace: Trace?
    private var fetchProfileTrace: Trace?
    private var isFirstMessagesLoad = true

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
        AnalyticsService.shared.logConversationOpened()
    }

    deinit {
        // CRITICO: rimuovere il listener per evitare memory leak e callback su oggetti deallocati
        messagesListener?.remove()
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
