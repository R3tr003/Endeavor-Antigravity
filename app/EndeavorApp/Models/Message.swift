import Foundation

/// Rappresenta un singolo messaggio in una conversazione.
/// `senderId` è il Firebase Auth UID del mittente — NON un Bool `isFromMe`.
/// La distinzione "mio vs altrui" avviene nella View confrontando con l'UID corrente.
struct Message: Identifiable, Codable, Equatable {
    let id: String               // Firestore document ID (auto-generated)
    let senderId: String         // Firebase Auth UID
    let text: String
    let createdAt: Date
    var readBy: [String]         // Array di Firebase Auth UIDs
    var deliveredTo: [String]    // Array di Firebase Auth UIDs che hanno ricevuto il messaggio
    var isSystemMessage: Bool = false

    // Tipo messaggio
    var messageType: MessageType = .text
    // eventId Firestore quando messageType == .meetingInvite o .meetingResponse
    var meetingEventId: String?
    // conversationId — set at parse time from Firestore path
    var conversationId: String?

    enum MessageType: String, Codable {
        case text = "text"
        case meetingInvite = "meeting_invite"
        case meetingResponse = "meeting_response"
    }

    // Media
    var imageUrl: String?
    var documentUrl: String?
    var documentName: String?

    /// Ora di invio/ricezione — solo "HH:mm". Il giorno è mostrato dalle date separator pills nella chat.
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }

    // MARK: - Read Receipt

    enum ReceiptStatus {
        case sent       // consegnato al server, destinatario non ancora connesso
        case delivered  // destinatario ha aperto la chat (deliveredTo contiene recipientId)
        case read       // destinatario ha letto (readBy contiene recipientId)
    }

    /// Restituisce lo stato di consegna/lettura del messaggio dal punto di vista del mittente.
    func receiptStatus(currentUserId: String, recipientId: String) -> ReceiptStatus {
        if readBy.contains(recipientId)      { return .read }
        if deliveredTo.contains(recipientId) { return .delivered }
        return .sent
    }
}
