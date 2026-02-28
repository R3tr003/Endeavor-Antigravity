import Foundation
import FirebaseFirestore

/// Protocollo per la gestione delle conversazioni e messaggi.
/// Usa listener Firestore real-time invece di fetch one-shot.
/// IMPORTANTE: i ListenerRegistration vanno rimossi nel deinit del chiamante.
protocol MessagesRepositoryProtocol {

    /// Avvia un listener real-time sulla lista conversazioni dell'utente.
    /// Ogni update chiama `onUpdate` con la lista aggiornata (non ancora arricchita con i profili).
    /// - Returns: ListenerRegistration da rimuovere nel deinit
    func listenToConversations(
        userId: String,
        onUpdate: @escaping (Result<[Conversation], Error>) -> Void
    ) -> ListenerRegistration

    /// Avvia un listener real-time sui messaggi di una conversazione.
    /// - Returns: ListenerRegistration da rimuovere nel deinit
    func listenToMessages(
        conversationId: String,
        onUpdate: @escaping (Result<[Message], Error>) -> Void
    ) -> ListenerRegistration

    /// Invia un messaggio e aggiorna atomicamente lastMessage e unreadCounts.
    func sendMessage(
        conversationId: String,
        senderId: String,
        recipientId: String,
        text: String,
        imageUrl: String?,
        documentUrl: String?,
        documentName: String?,
        completion: @escaping (Error?) -> Void
    )

    /// Cerca una conversazione esistente tra due utenti.
    /// Se non esiste, la crea e restituisce il suo ID.
    func getOrCreateConversation(
        between userId1: String,
        and userId2: String,
        completion: @escaping (Result<String, Error>) -> Void
    )

    /// Azzera il contatore unread per l'utente corrente e aggiunge il proprio UID a readBy degli ultimi messaggi.
    func markConversationAsRead(
        conversationId: String,
        userId: String,
        completion: @escaping (Error?) -> Void
    )

    /// Recupera il UserProfile di un singolo utente per arricchire le conversazioni.
    func fetchUserProfile(
        userId: String,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    )
}
