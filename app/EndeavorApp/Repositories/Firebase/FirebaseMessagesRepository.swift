import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebasePerformance

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
        imageUrl: String?,
        documentUrl: String?,
        documentName: String?,
        completion: @escaping (Error?) -> Void
    ) {
        let trace = Performance.startTrace(name: "Send_Message_Duration")
        let batch = db.batch()
        let now = Timestamp(date: Date())
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Nuovo documento messaggio
        let messageRef = db
            .collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .document()

        var messageData: [String: Any] = [
            "senderId": senderId,
            "text": trimmedText,
            "createdAt": now,
            "readBy": [senderId],   // il mittente ha già letto il proprio messaggio
            "deliveredTo": []       // il destinatario non ha ancora ricevuto
        ]
        
        if let imageUrl = imageUrl {
            messageData["imageUrl"] = imageUrl
        }
        if let documentUrl = documentUrl {
            messageData["documentUrl"] = documentUrl
        }
        if let documentName = documentName {
            messageData["documentName"] = documentName
        }
        
        batch.setData(messageData, forDocument: messageRef)

        // 2. Aggiornamento conversazione — usa FieldValue.increment per evitare race conditions
        let conversationRef = db
            .collection(conversationsCollection)
            .document(conversationId)

        // Determine the last message indicator
        var indicator = trimmedText
        if !indicator.isEmpty && (imageUrl != nil || documentUrl != nil) {
            indicator = "Attachment: " + indicator
        } else if imageUrl != nil {
            indicator = "📷 Photo"
        } else if let docName = documentName {
            indicator = "📄 \(docName)"
        } else if documentUrl != nil {
            indicator = "📄 Document"
        }

        let conversationUpdate: [String: Any] = [
            "lastMessage": indicator,
            "lastMessageAt": now,
            "lastSenderId": senderId,
            "lastMessageReadBy": [senderId],  // al momento dell'invio solo il mittente ha "letto"
            "lastMessageDeliveredTo": [],      // ancora nessun destinatario ha ricevuto
            "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1))
            // Il contatore del mittente NON viene incrementato
        ]
        batch.updateData(conversationUpdate, forDocument: conversationRef)

        batch.commit { error in
            trace?.stop()
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

                // Non esiste — controlla ban prima di creare
                self.checkBanAndCreate(userId1: userId1, userId2: userId2, completion: completion)
            }
    }

    private func checkBanAndCreate(
        userId1: String,
        userId2: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Check if userId1 is banned by userId2: bans/{userId1}/byUser/{userId2}
        db.collection("bans").document(userId1)
            .collection("byUser").document(userId2)
            .getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                if let ts = snap?.data()?["bannedUntil"] as? Timestamp, ts.dateValue() > Date() {
                    DispatchQueue.main.async { completion(.failure(BanError.userIsBanned)) }
                    return
                }
                // Check if userId2 is banned by userId1: bans/{userId2}/byUser/{userId1}
                self.db.collection("bans").document(userId2)
                    .collection("byUser").document(userId1)
                    .getDocument { [weak self] snap2, _ in
                        guard let self = self else { return }
                        if let ts2 = snap2?.data()?["bannedUntil"] as? Timestamp, ts2.dateValue() > Date() {
                            DispatchQueue.main.async { completion(.failure(BanError.userIsBanned)) }
                            return
                        }
                        self.createConversation(between: userId1, and: userId2, completion: completion)
                    }
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
            "unreadCounts": [userId1: 0, userId2: 0],
            "pinnedBy": [],
            "isFiltered": false,
            "filterReason": "",
            "filterCheckedAt": NSNull()
        ]

        newRef.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    AnalyticsService.shared.logConversationCreated()
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

    // MARK: - Delete Conversation

    func deleteConversation(
        conversationId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let convRef = db.collection(conversationsCollection).document(conversationId)
        let messagesRef = convRef.collection(messagesCollection)

        // Delete all messages within the subcollection first
        messagesRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            let batch = self.db.batch()

            if let docs = snapshot?.documents {
                for doc in docs {
                    batch.deleteDocument(doc.reference)
                }
            }

            // Delete the parent conversation document
            batch.deleteDocument(convRef)

            batch.commit { error in
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    // MARK: - Pin Conversation

    func togglePinConversation(
        conversationId: String,
        userId: String,
        isPinned: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let updateData: [String: Any] = [
            "pinnedBy": isPinned ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId])
        ]
        db.collection(conversationsCollection)
            .document(conversationId)
            .updateData(updateData) { error in
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

    // MARK: - Fetch Company Name
    
    /// Cerca il documento company associato a userId nel database (default).
    /// Usato per mostrare il nome azienda nell'header di ConversationView.
    func fetchCompanyName(
        forUserId userId: String,
        completion: @escaping (String?) -> Void
    ) {
        profilesDb.collection("companies")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                let name = snapshot?.documents.first?.data()["name"] as? String
                DispatchQueue.main.async { completion(name) }
            }
    }

    // MARK: - Filter and System messages

    func unfilterConversation(conversationId: String, completion: @escaping (Error?) -> Void) {
        db.collection(conversationsCollection)
            .document(conversationId)
            .updateData([
                "isFiltered": false,
                "filterReason": "",
                "filterCheckedAt": Timestamp(date: Date())
            ]) { error in
                DispatchQueue.main.async { completion(error) }
            }
    }

    func sendSystemMessage(
        conversationId: String,
        text: String,
        completion: @escaping (Error?) -> Void
    ) {
        let messageRef = db
            .collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .document()

        let data: [String: Any] = [
            "senderId": "system",
            "text": text,
            "createdAt": Timestamp(date: Date()),
            "readBy": [],
            "deliveredTo": [],
            "isSystemMessage": true
        ]

        messageRef.setData(data) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - Ban

    func banUser(
        senderId: String,
        currentUserId: String,
        bannedUntil: Date,
        completion: @escaping (Error?) -> Void
    ) {
        // Create ban as a dedicated sub-document: bans/{bannedUserId}/byUser/{currentUserId}
        // This avoids needing update permissions — each ban entry is its own document.
        db.collection("bans")
            .document(senderId)
            .collection("byUser")
            .document(currentUserId)
            .setData(["bannedUntil": Timestamp(date: bannedUntil)]) { error in
                DispatchQueue.main.async { completion(error) }
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
            unreadCounts: data["unreadCounts"] as? [String: Int] ?? [:],
            pinnedBy: data["pinnedBy"] as? [String] ?? [],
            lastMessageReadBy: data["lastMessageReadBy"] as? [String] ?? [],
            lastMessageDeliveredTo: data["lastMessageDeliveredTo"] as? [String] ?? [],
            isFiltered: data["isFiltered"] as? Bool ?? false,
            filterReason: data["filterReason"] as? String ?? "",
            filterCheckedAt: (data["filterCheckedAt"] as? Timestamp)?.dateValue()
        )
    }

    private func parseMessage(from data: [String: Any], id: String) -> Message? {
        guard
            let senderId = data["senderId"] as? String,
            let text = data["text"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        else { return nil }

        let messageTypeRaw = data["messageType"] as? String ?? "text"
        return Message(
            id: id,
            senderId: senderId,
            text: text,
            createdAt: createdAt,
            readBy: data["readBy"] as? [String] ?? [],
            deliveredTo: data["deliveredTo"] as? [String] ?? [],
            isSystemMessage: data["isSystemMessage"] as? Bool ?? false,
            messageType: Message.MessageType(rawValue: messageTypeRaw) ?? .text,
            meetingEventId: data["meetingEventId"] as? String,
            imageUrl: data["imageUrl"] as? String,
            documentUrl: data["documentUrl"] as? String,
            documentName: data["documentName"] as? String
        )
    }

    // MARK: - Meeting Invite Messages

    func sendMeetingInviteMessage(
        conversationId: String,
        senderId: String,
        recipientId: String,
        eventId: String,
        eventTitle: String,
        completion: @escaping (Error?) -> Void
    ) {
        let batch = db.batch()
        let now = Timestamp(date: Date())

        let messageRef = db.collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .document()

        batch.setData([
            "senderId": senderId,
            "text": "📹 Meeting invite: \(eventTitle)",
            "createdAt": now,
            "readBy": [senderId],
            "deliveredTo": [],
            "messageType": "meeting_invite",
            "meetingEventId": eventId,
            "isSystemMessage": false
        ], forDocument: messageRef)

        let conversationRef = db.collection(conversationsCollection).document(conversationId)
        batch.updateData([
            "lastMessage": "📹 Meeting invite: \(eventTitle)",
            "lastMessageAt": now,
            "lastSenderId": senderId,
            "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1)),
            "lastMessageDeliveredTo": [],
            "lastMessageReadBy": [senderId]
        ], forDocument: conversationRef)

        batch.commit { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func sendMeetingResponseMessage(
        conversationId: String,
        senderId: String,
        recipientId: String,
        eventId: String,
        responseType: String,
        completion: @escaping (Error?) -> Void
    ) {
        let batch = db.batch()
        let now = Timestamp(date: Date())
        let text: String
        switch responseType {
        case "accepted":     text = "✅ Meeting accepted"
        case "declined":     text = "❌ Meeting declined"
        case "proposed_new": text = "📅 New time proposed"
        default:             text = "Meeting response"
        }

        let messageRef = db.collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)
            .document()

        batch.setData([
            "senderId": senderId,
            "text": text,
            "createdAt": now,
            "readBy": [senderId],
            "deliveredTo": [],
            "messageType": "meeting_response",
            "meetingEventId": eventId,
            "isSystemMessage": false
        ], forDocument: messageRef)

        let conversationRef = db.collection(conversationsCollection).document(conversationId)
        batch.updateData([
            "lastMessage": text,
            "lastMessageAt": now,
            "lastSenderId": senderId,
            "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1)),
            "lastMessageDeliveredTo": [],
            "lastMessageReadBy": [senderId]
        ], forDocument: conversationRef)

        batch.commit { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - Mark as Delivered

    /// Aggiunge currentUserId a `deliveredTo` di tutti i messaggi inviati dall'altro partecipante
    /// che non lo contengono ancora. Chiamato quando l'utente apre la conversazione.
    func markAsDelivered(conversationId: String, currentUserId: String) async {
        let messagesRef = db
            .collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)

        guard let allSnap = try? await messagesRef
            .whereField("senderId", isNotEqualTo: currentUserId)
            .getDocuments()
        else { return }

        let batch = db.batch()
        var hasChanges = false

        for doc in allSnap.documents {
            let deliveredTo = doc.data()["deliveredTo"] as? [String] ?? []
            if !deliveredTo.contains(currentUserId) {
                batch.updateData(
                    ["deliveredTo": FieldValue.arrayUnion([currentUserId])],
                    forDocument: doc.reference
                )
                hasChanges = true
            }
        }

        if hasChanges {
            try? await batch.commit()
            // Aggiorna anche il documento conversazione per aggiornare la lista
            let convRef = db.collection(conversationsCollection).document(conversationId)
            try? await convRef.updateData([
                "lastMessageDeliveredTo": FieldValue.arrayUnion([currentUserId])
            ])
        }
    }

    // MARK: - Mark Messages as Read

    /// Aggiunge currentUserId sia a `readBy` che a `deliveredTo` (per coerenza) dei messaggi
    /// inviati dall'altro partecipante. Chiamato subito dopo l'apertura per marcare come letti.
    func markMessagesAsRead(conversationId: String, currentUserId: String) async {
        let messagesRef = db
            .collection(conversationsCollection)
            .document(conversationId)
            .collection(messagesCollection)

        guard let allSnap = try? await messagesRef
            .whereField("senderId", isNotEqualTo: currentUserId)
            .getDocuments()
        else { return }

        let batch = db.batch()
        var hasChanges = false

        for doc in allSnap.documents {
            let readBy = doc.data()["readBy"] as? [String] ?? []
            if !readBy.contains(currentUserId) {
                batch.updateData(
                    [
                        "readBy": FieldValue.arrayUnion([currentUserId]),
                        "deliveredTo": FieldValue.arrayUnion([currentUserId])
                    ],
                    forDocument: doc.reference
                )
                hasChanges = true
            }
        }

        if hasChanges {
            try? await batch.commit()
            // Aggiorna anche il documento conversazione per aggiornare la lista
            let convRef = db.collection(conversationsCollection).document(conversationId)
            try? await convRef.updateData([
                "lastMessageReadBy": FieldValue.arrayUnion([currentUserId]),
                "lastMessageDeliveredTo": FieldValue.arrayUnion([currentUserId])
            ])
        }
    }
}

// MARK: - Ban Error

enum BanError: LocalizedError {
    case userIsBanned

    var errorDescription: String? {
        String(localized: "messages.ban_active_error",
               defaultValue: "You cannot start a conversation with this user at this time.")
    }
}
