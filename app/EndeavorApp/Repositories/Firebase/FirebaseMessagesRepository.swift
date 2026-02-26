import Foundation
import SwiftUI

class FirebaseMessagesRepository: MessagesRepositoryProtocol {
    func fetchConversations(userId: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        // Return dummy data for now to simulate a network request delay
        let dummyData = [
            Conversation(id: UUID(), name: "Maria Lopez", role: "SaaS Scaling Expert",
                         lastMessage: "Happy to share what worked for us at the 50-person milestone.",
                         time: "2m", unreadCount: 2, initials: "ML", accentColor: Color.brandPrimary),
            Conversation(id: UUID(), name: "Carlos Rodriguez", role: "Fintech Founder",
                         lastMessage: "Let's schedule a call this week to discuss the go-to-market.",
                         time: "1h", unreadCount: 1, initials: "CR", accentColor: .purple),
            Conversation(id: UUID(), name: "Ana Martinez", role: "CEO, Series B",
                         lastMessage: "The fundraising deck looks solid. A few suggestions...",
                         time: "3h", unreadCount: 0, initials: "AM", accentColor: .orange),
            Conversation(id: UUID(), name: "Endeavor Team", role: "Account Manager",
                         lastMessage: "Your next mentorship session is confirmed for Thursday.",
                         time: "1d", unreadCount: 0, initials: "ET", accentColor: Color.brandPrimary),
            Conversation(id: UUID(), name: "James Okafor", role: "Operations Expert",
                         lastMessage: "Scaling ops across 3 markets is tough — here's my framework.",
                         time: "2d", unreadCount: 0, initials: "JO", accentColor: .blue)
        ]
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion(.success(dummyData))
        }
    }
}
