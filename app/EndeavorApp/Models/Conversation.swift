import Foundation
import SwiftUI

/// Rappresenta una conversazione tra due utenti.
/// `name`, `role`, `initials` vengono popolati dopo il fetch dei profili utente — NON sono salvati in Firestore.
/// `accentColor` è generata deterministicamente dall'UID per coerenza visiva.
struct Conversation: Identifiable, Equatable {
    let id: String                      // Firestore document ID
    let participantIds: [String]        // Array di Firebase Auth UIDs [uid_A, uid_B]
    var lastMessage: String
    var lastMessageAt: Date
    var lastSenderId: String
    var unreadCounts: [String: Int]     // UID → contatore non letti

    // Campi UI — popolati dopo il fetch di UserProfile, non da Firestore
    var otherParticipantName: String = ""
    var otherParticipantRole: String = ""
    var otherParticipantImageUrl: String = ""

    /// Restituisce il contatore unread per uno specifico UID
    func unreadCount(for userId: String) -> Int {
        return unreadCounts[userId] ?? 0
    }

    /// Iniziali per l'avatar (es. "ML" da "Maria Lopez")
    var initials: String {
        let components = otherParticipantName.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    /// Colore avatar deterministico basato sul partecipante opposto.
    /// Usa l'UID per garantire che lo stesso utente abbia sempre lo stesso colore.
    func accentColor(currentUserId: String) -> Color {
        let palette: [Color] = [.brandPrimary, .purple, .orange, .blue, .pink, .teal, .indigo]
        let otherId = participantIds.first { $0 != currentUserId } ?? ""
        let hash = abs(otherId.hashValue)
        return palette[hash % palette.count]
    }

    /// Formattazione del timestamp per la lista conversazioni
    var displayTime: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(lastMessageAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDateInYesterday(lastMessageAt) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: lastMessageAt, to: Date()).day, daysAgo < 7 {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "dd/MM"
        }
        return formatter.string(from: lastMessageAt)
    }
}
