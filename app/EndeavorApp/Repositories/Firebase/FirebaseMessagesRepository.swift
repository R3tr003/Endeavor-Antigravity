import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseMessagesRepository: MessagesRepositoryProtocol {

    // Database "messaging" separato da "(default)" che contiene i profili utente.
    // La stringa "messaging" deve corrispondere esattamente al nome del database
    // creato nella Firebase Console.
    private let db = Firestore.firestore(database: "messaging")
    private let conversationsCollection = "conversations"
    private let messagesCollection = "messages"

    // Per leggere i profili utente (nome, ruolo, avatar) serve il database (default).
    // Si usa un'istanza separata per non mescolare le due connessioni.
    private let profilesDb = Firestore.firestore()
    private let usersCollection = "users"

    // MARK: - Listen to Conversations

    func listenToConversations(
        userId: String,
        onUpdate: @escaping (Result<[Conversation], Error>) -> Void
    ) -> ListenerRegistration {

        return db.collection(conversationsCollection)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async { onUpdate(.failure(error)) }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { onUpdate(.success([])) }
                    return
                }

                let conversations = documents.compactMap { doc -> Conversation? in
                    return self.parseConversation(from: doc.data(), id: doc.documentID)
                }

                DispatchQueue.main.async { onUpdate(.success(conversations)) }
            }
    }

    // MARK: - Listen to Messages

    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping (Result<[Message], Error>) -> Void
    ) -> ListenerRegistration {

        return db.collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async { onUpdate(.failure(error)) }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async { onUpdate(.success([])) }
                    return
                }

                let messages = documents.compactMap { doc -> Message? in
                    return self.parseMessage(from: doc.data(), id: doc.documentID)
                }

                DispatchQueue.main.async { onUpdate(.success(messages)) }
            }
    }

    // MARK: - Send Message

    func sendMessage(
        conversationId: String,
        senderId: String,
        recipientId: String,
        text: String,
        completion: @escaping (Error?) -> Void
    ) {
        let batch = db.batch()
        let now = Timestamp(date: Date())
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Nuovo documento messaggio
        let messageRef = db
            .collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .document()

        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": trimmedText,
            "createdAt": now,
            "readBy": [senderId]   // il mittente ha già letto il proprio messaggio
        ]
        batch.setData(messageData, forDocument: messageRef)

        // 2. Aggiornamento conversazione — usa FieldValue.increment per evitare race conditions
        let conversationRef = db
            .collection(conversationsCollection)
            .document(conversationId)

        let conversationUpdate: [String: Any] = [
            "lastMessage": trimmedText,
            "lastMessageAt": now,
            "lastSenderId": senderId,
            "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1))
            // Il contatore del mittente NON viene incrementato
        ]
        batch.updateData(conversationUpdate, forDocument: conversationRef)

        batch.commit { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - Get or Create Conversation

    func getOrCreateConversation(
        between userId1: String,
        and userId2: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Cerca conversazione esistente dove entrambi sono partecipanti
        db.collection(conversationsCollection)
            .whereField("participantIds", arrayContains: userId1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async { completion(.failure(error)) }
                    return
                }

                // Filtra localmente per trovare la conversazione con esattamente userId1 e userId2
                let existingDoc = snapshot?.documents.first { doc in
                    let participants = doc.data()["participantIds"] as? [String] ?? []
                    return participants.contains(userId2)
                }

                if let existing = existingDoc {
                    DispatchQueue.main.async { completion(.success(existing.documentID)) }
                    return
                }

                // Non esiste — crea nuova conversazione
                self.createConversation(between: userId1, and: userId2, completion: completion)
            }
    }

    private func createConversation(
        between userId1: String,
        and userId2: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let newRef = db.collection(conversationsCollection).document()
        let now = Timestamp(date: Date())

        let data: [String: Any] = [
            "participantIds": [userId1, userId2],
            "lastMessage": "",
            "lastMessageAt": now,
            "lastSenderId": "",
            "unreadCounts": [userId1: 0, userId2: 0]
        ]

        newRef.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(newRef.documentID))
                }
            }
        }
    }

    // MARK: - Mark as Read

    func markConversationAsRead(
        conversationId: String,
        userId: String,
        completion: @escaping (Error?) -> Void
    ) {
        // Azzera il contatore unread dell'utente corrente
        db.collection(conversationsCollection)
            .document(conversationId)
            .updateData(["unreadCounts.\(userId)": 0]) { error in
                DispatchQueue.main.async { completion(error) }
            }
    }

    // MARK: - Fetch User Profile (per arricchire conversazioni)

    func fetchUserProfile(
        userId: String,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    ) {
        // Legge dal database (default), non da "messaging"
        profilesDb.collection(usersCollection).document(userId).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = snapshot?.data() else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AppError", code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                }
                return
            }

            // Stesso pattern di mapping usato in FirebaseUserRepository
            var user = UserProfile(
                id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                firstName: data["firstName"] as? String ?? "",
                lastName: data["lastName"] as? String ?? "",
                role: data["role"] as? String ?? "",
                email: data["email"] as? String ?? "",
                location: data["location"] as? String ?? "",
                timeZone: data["timeZone"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String ?? "",
                personalBio: data["personalBio"] as? String ?? ""
            )

            if let ts = data["createdAt"] as? Timestamp { user.createdAt = ts.dateValue() }
            if let ts = data["lastLoginAt"] as? Timestamp { user.lastLoginAt = ts.dateValue() }

            DispatchQueue.main.async { completion(.success(user)) }
        }
    }

    // MARK: - Parse Helpers

    private func parseConversation(from data: [String: Any], id: String) -> Conversation? {
        guard
            let participantIds = data["participantIds"] as? [String],
            let lastMessageAt = (data["lastMessageAt"] as? Timestamp)?.dateValue()
        else { return nil }

        return Conversation(
            id: id,
            participantIds: participantIds,
            lastMessage: data["lastMessage"] as? String ?? "",
            lastMessageAt: lastMessageAt,
            lastSenderId: data["lastSenderId"] as? String ?? "",
            unreadCounts: data["unreadCounts"] as? [String: Int] ?? [:]
        )
    }

    private func parseMessage(from data: [String: Any], id: String) -> Message? {
        guard
            let senderId = data["senderId"] as? String,
            let text = data["text"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        return Message(
            id: id,
            senderId: senderId,
            text: text,
            createdAt: createdAt,
            readBy: data["readBy"] as? [String] ?? []
        )
    }
}
