import Foundation
import FirebaseFirestore
@testable import app

class MockMessagesRepository: MessagesRepositoryProtocol {
    
    var mockConversations: [Conversation] = []
    var mockMessages: [Message] = []
    var mockUserProfiles: [String: UserProfile] = [:]
    
    // Captured calls
    var fetchUserProfileCallCount = 0
    var listenToConversationsCallCount = 0
    
    func listenToConversations(userId: String, onUpdate: @escaping (Result<[Conversation], Error>) -> Void) -> ListenerRegistration {
        listenToConversationsCallCount += 1
        // Simulate immediate response
        onUpdate(.success(mockConversations))
        // Returns a dummy listener
        return DummyListenerRegistration()
    }
    
    func listenToMessages(conversationId: String, onUpdate: @escaping (Result<[Message], Error>) -> Void) -> ListenerRegistration {
        onUpdate(.success(mockMessages.filter { $0.conversationId == conversationId || $0.conversationId == nil }))
        return DummyListenerRegistration()
    }
    
    func sendMessage(conversationId: String, senderId: String, recipientId: String, text: String, imageUrl: String?, documentUrl: String?, documentName: String?, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
    
    func getOrCreateConversation(between userId1: String, and userId2: String, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success("mock_conv_id"))
    }
    
    func markConversationAsRead(conversationId: String, userId: String, completion: @escaping (Error?) -> Void) {
        if let index = mockConversations.firstIndex(where: { $0.id == conversationId }) {
            mockConversations[index].unreadCounts[userId] = 0
        }
        completion(nil)
    }
    
    func deleteConversation(conversationId: String, completion: @escaping (Error?) -> Void) {
        mockConversations.removeAll { $0.id == conversationId }
        completion(nil)
    }
    
    func togglePinConversation(conversationId: String, userId: String, isPinned: Bool, completion: @escaping (Error?) -> Void) {
        if let index = mockConversations.firstIndex(where: { $0.id == conversationId }) {
            if isPinned {
                if !mockConversations[index].pinnedBy.contains(userId) {
                    mockConversations[index].pinnedBy.append(userId)
                }
            } else {
                mockConversations[index].pinnedBy.removeAll { $0 == userId }
            }
        }
        completion(nil)
    }
    
    func fetchUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        fetchUserProfileCallCount += 1
        if let profile = mockUserProfiles[userId] {
            completion(.success(profile))
        } else {
            completion(.failure(NSError(domain: "Test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])))
        }
    }
    
    func unfilterConversation(conversationId: String, completion: @escaping (Error?) -> Void) {
        if let i = mockConversations.firstIndex(where: { $0.id == conversationId }) {
            mockConversations[i].isFiltered = false
            mockConversations[i].filterReason = ""
        }
        completion(nil)
    }

    func sendSystemMessage(conversationId: String, text: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func markAsDelivered(conversationId: String, currentUserId: String) async {}
    func markMessagesAsRead(conversationId: String, currentUserId: String) async {}

    func sendMeetingInviteMessage(conversationId: String, senderId: String, recipientId: String, eventId: String, eventTitle: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func sendMeetingResponseMessage(conversationId: String, senderId: String, recipientId: String, eventId: String, responseType: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func banUser(senderId: String, currentUserId: String, bannedUntil: Date, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}

class DummyListenerRegistration: NSObject, ListenerRegistration {
    func remove() {
        // No-op
    }
}
