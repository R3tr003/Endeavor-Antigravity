import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ConversationsViewModel: ObservableObject {

    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var appError: AppError?

    var totalUnreadCount: Int {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return 0 }
        return conversations.reduce(0) { total, conv in
            total + (conv.unreadCounts[currentUserId] ?? 0)
        }
    }

    private let repository: MessagesRepositoryProtocol
    private var conversationsListener: ListenerRegistration?

    /// Cache profili utente per evitare fetch ripetuti
    private var profileCache: [String: UserProfile] = [:]
    private var companyCache: [String: String] = [:]

    init(repository: MessagesRepositoryProtocol = FirebaseMessagesRepository()) {
        self.repository = repository
    }

    deinit {
        // CRITICO: rimuovere listener per evitare memory leak
        conversationsListener?.remove()
    }

    // MARK: - Start Listening

    /// Avvia il listener con l'UID reale di Firebase Auth.
    /// Sostituisce il vecchio `fetchConversations(userId: "currentUserId")`.
    func startListening() {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            appError = .authFailed(reason: "User not authenticated")
            return
        }

        isLoading = true
        conversationsListener?.remove()

        conversationsListener = repository.listenToConversations(
            userId: currentUserId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .success(let rawConversations):
                // Le conversazioni arrivano senza nome/ruolo del partecipante — va arricchito
                self.enrichConversations(rawConversations, currentUserId: currentUserId)

            case .failure(let error):
                self.appError = .unknown(reason: error.localizedDescription)
            }
        }
    }

    // MARK: - Stop Listening

    func stopListening() {
        conversationsListener?.remove()
        conversationsListener = nil
    }

    // MARK: - Get or Create Conversation

    /// Chiamato dal NetworkView quando l'utente preme "Connect" su un profilo.
    /// Ritorna l'ID della conversazione (esistente o nuova) per navigare a ConversationView.
    func getOrCreateConversation(
        with otherUserId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else {
            completion(.failure(NSError(domain: "AppError", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        repository.getOrCreateConversation(
            between: currentUserId,
            and: otherUserId,
            completion: completion
        )
    }

    // MARK: - Enrich Conversations

    /// Recupera i profili degli altri partecipanti e li inserisce nelle conversazioni.
    /// Usa una cache per evitare fetch ridondanti.
    private func enrichConversations(_ rawConversations: [Conversation], currentUserId: String) {
        guard !rawConversations.isEmpty else {
            self.conversations = []
            return
        }

        // Raccoglie gli UID degli altri partecipanti non ancora in cache
        let otherIds = Set(rawConversations.compactMap { conv in
            conv.participantIds.first { $0 != currentUserId }
        })
        let idsToFetch = otherIds.filter { profileCache[$0] == nil || companyCache[$0] == nil }

        // Se tutti i profili sono in cache, aggiorna subito
        guard !idsToFetch.isEmpty else {
            self.conversations = rawConversations.map {
                self.applyProfile(to: $0, currentUserId: currentUserId)
            }
            return
        }

        // Fetch parallelo dei profili mancanti
        let group = DispatchGroup()
        for userId in idsToFetch {
            if profileCache[userId] == nil {
                group.enter()
                repository.fetchUserProfile(userId: userId) { [weak self] result in
                    if case .success(let profile) = result {
                        self?.profileCache[userId] = profile
                    }
                    group.leave()
                }
            }
            
            if companyCache[userId] == nil {
                group.enter()
                Firestore.firestore().collection("companies")
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 1)
                    .getDocuments { [weak self] snapshot, _ in
                        if let name = snapshot?.documents.first?.data()["name"] as? String {
                            self?.companyCache[userId] = name
                        } else {
                            // Caching empty so we don't refetch infinitely if no company exists
                            self?.companyCache[userId] = ""
                        }
                        group.leave()
                    }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.conversations = rawConversations.map {
                self.applyProfile(to: $0, currentUserId: currentUserId)
            }
        }
    }

    private func applyProfile(to conversation: Conversation, currentUserId: String) -> Conversation {
        var enriched = conversation
        let otherId = conversation.participantIds.first { $0 != currentUserId } ?? ""
        if let profile = profileCache[otherId] {
            enriched.otherParticipantName = profile.fullName
            enriched.otherParticipantImageUrl = profile.profileImageUrl
        }
        if let company = companyCache[otherId], !company.isEmpty {
            enriched.otherParticipantCompany = company
        } else if let profile = profileCache[otherId] {
            // Fallback al ruolo se l'azienda non esiste
            enriched.otherParticipantCompany = profile.role
        }
        return enriched
    }
}
