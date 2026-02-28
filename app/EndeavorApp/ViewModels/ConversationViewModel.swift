import Foundation
import FirebaseFirestore
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
    }

    deinit {
        // CRITICO: rimuovere il listener per evitare memory leak e callback su oggetti deallocati
        messagesListener?.remove()
    }

    // MARK: - Listener

    func startListening() {
        isLoading = true
        messagesListener?.remove()

        messagesListener = repository.listenToMessages(
            conversationId: conversationId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let msgs):
                self.messages = msgs
                // Marca come letti all'apertura e ad ogni nuovo messaggio
                self.markAsRead()
            case .failure(let error):
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
        if trimmed.isEmpty && imageUrl == nil && documentUrl == nil { return } // non inviare nulla se è tutto vuoto
        
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
                    self?.sendMessage(text: "", documentUrl: downloadUrl, documentName: documentName)
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Mark as Read

    private func markAsRead() {
        repository.markConversationAsRead(
            conversationId: conversationId,
            userId: currentUserId
        ) { _ in /* silent fail — non critico */ }
    }

    // MARK: - Helper

    /// Restituisce true se un messaggio è stato inviato dall'utente corrente
    func isFromMe(_ message: Message) -> Bool {
        return message.senderId == currentUserId
    }

    // MARK: - Fetch Recipient Profile
    private func fetchRecipientProfile() {
        let networkRepo = FirebaseNetworkRepository()
        networkRepo.fetchUserProfile(userId: recipientId) { [weak self] result in
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
