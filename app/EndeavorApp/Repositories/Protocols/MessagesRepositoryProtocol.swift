import Foundation
import SwiftUI

struct Conversation: Identifiable {
    let id: UUID
    let name: String
    let role: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let initials: String
    let accentColor: Color
}

protocol MessagesRepositoryProtocol {
    func fetchConversations(userId: String, completion: @escaping (Result<[Conversation], Error>) -> Void)
}
