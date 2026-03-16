import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import FirebasePerformance

class ConversationsViewModel: ObservableObject {

    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var appError: AppError?

    var totalUnreadCount: Int {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return 0 }
        return conversations.reduce(0) { total, conv in
            if conv.isFiltered { return total }
            return total + (conv.unreadCounts[currentUserId] ?? 0)
        }
    }

    /// Checks if a conversation already exists with the given user ID.
    func hasConversation(with otherUserId: String) -> Bool {
        return conversations.contains { $0.participantIds.contains(otherUserId) }
    }

    private let repository: MessagesRepositoryProtocol
    private var conversationsListener: ListenerRegistration?
    private var fetchConversationsTrace: Trace?

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
        
        // Start Firebase Performance trace for the initial fetch
        fetchConversationsTrace = Performance.startTrace(name: "Fetch_Conversations_Duration")

        conversationsListener = repository.listenToConversations(
            userId: currentUserId
        ) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            // Stop the trace on first load
            if let trace = self.fetchConversationsTrace {
                trace.stop()
                self.fetchConversationsTrace = nil
            }

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

    // MARK: - Delete Conversation

    func deleteConversation(_ conversation: Conversation) {
        let conversationId = conversation.id
        AnalyticsService.shared.logConversationDeleted()
        repository.deleteConversation(conversationId: conversationId) { [weak self] error in
            if let error = error {
                self?.appError = .unknown(reason: "Could not delete conversation: \(error.localizedDescription)")
            } else {
                // Rimuoviamo localmente. Il listener in ogni caso dovrebbe sincronizzare,
                // ma aggiornare l'UI al volo rende tutto più fluido.
                self?.conversations.removeAll { $0.id == conversationId }
            }
        }
    }

    // MARK: - Pin Conversation

    func togglePin(_ conversation: Conversation, isPinned: Bool) {
        guard let currentUserId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        AnalyticsService.shared.logConversationPinToggled(isPinned: isPinned)
        
        // Aggiorna optimisticamente l'UI
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            var updated = conversations[index]
            if isPinned {
                if !updated.pinnedBy.contains(currentUserId) { updated.pinnedBy.append(currentUserId) }
            } else {
                updated.pinnedBy.removeAll { $0 == currentUserId }
            }
            conversations[index] = updated
            self.sortConversations(currentUserId: currentUserId)
        }
        
        repository.togglePinConversation(conversationId: conversation.id, userId: currentUserId, isPinned: isPinned) { [weak self] error in
            if let error = error {
                self?.appError = .unknown(reason: "Could not pin/unpin conversation: \(error.localizedDescription)")
            }
        }
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
            let enriched = rawConversations.map {
                self.applyProfile(to: $0, currentUserId: currentUserId)
            }
            self.conversations = enriched
            self.sortConversations(currentUserId: currentUserId)
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
            let enriched = rawConversations.map {
                self.applyProfile(to: $0, currentUserId: currentUserId)
            }
            self.conversations = enriched
            self.sortConversations(currentUserId: currentUserId)
        }
    }

    private func sortConversations(currentUserId: String) {
        self.conversations.sort { c1, c2 in
            let c1Pinned = c1.pinnedBy.contains(currentUserId)
            let c2Pinned = c2.pinnedBy.contains(currentUserId)
            if c1Pinned == c2Pinned {
                return c1.lastMessageAt > c2.lastMessageAt
            }
            return c1Pinned && !c2Pinned
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
        } else {
            enriched.otherParticipantCompany = ""
        }
        return enriched
    }
    
    // MARK: - Filters
    
    func unfilterConversation(conversationId: String) {
        repository.unfilterConversation(conversationId: conversationId) { [weak self] error in
            if let error = error {
                self?.appError = .unknown(reason: error.localizedDescription)
            }
        }
    }

    var filteredConversations: [Conversation] {
        let currentUserId = UserDefaults.standard.string(forKey: "userId") ?? ""
        return conversations.filter { $0.isFiltered && $0.lastSenderId != currentUserId }
    }
}
