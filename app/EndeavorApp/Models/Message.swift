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
    
    // Iniziative Media Aggiunte
    var imageUrl: String?
    var documentUrl: String?
    var documentName: String?

    /// Formattazione timestamp per la UI (es. "10:32" o "Yesterday")
    var displayTime: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(createdAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "dd/MM"
        }
        return formatter.string(from: createdAt)
    }
}
