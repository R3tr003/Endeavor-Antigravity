import XCTest
@testable import app

final class ConversationsViewModelTests: XCTestCase {
    
    var viewModel: ConversationsViewModel!
    var mockRepository: MockMessagesRepository!
    
    override func setUp() {
        super.setUp()
        // Save a mock user ID in UserDefaults so the ViewModel knows who the "current user" is
        UserDefaults.standard.set("test_user_id", forKey: "userId")
        
        mockRepository = MockMessagesRepository()
        viewModel = ConversationsViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "userId")
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testTotalUnreadCount_SumsCorectly() {
        // Given
        let conv1 = Conversation(
            id: "chat_1",
            participantIds: ["test_user_id", "other_user_1"],
            lastMessage: "Hello",
            lastMessageAt: Date(),
            lastSenderId: "other_user_1",
            unreadCounts: ["test_user_id": 2, "other_user_1": 0]
        )
        
        let conv2 = Conversation(
            id: "chat_2",
            participantIds: ["test_user_id", "other_user_2"],
            lastMessage: "How are you?",
            lastMessageAt: Date(),
            lastSenderId: "other_user_2",
            unreadCounts: ["test_user_id": 5, "other_user_2": 0]
        )
        
        let conv3 = Conversation(
            id: "chat_3",
            participantIds: ["test_user_id", "other_user_3"],
            lastMessage: "Bye",
            lastMessageAt: Date(),
            lastSenderId: "test_user_id",
            unreadCounts: ["test_user_id": 0, "other_user_3": 1] // The other user has unreads, not us
        )
        
        mockRepository.mockConversations = [conv1, conv2, conv3]
        
        // When
        viewModel.startListening()
        
        // Then
        // The unread count for "test_user_id" should be 2 + 5 + 0 = 7
        XCTAssertEqual(viewModel.totalUnreadCount, 7, "The total unread count should be correctly summed from all conversations")
    }
    
    func testHasConversation_ReturnsTrueIfExists() {
        // Given
        let conv = Conversation(
            id: "chat_1",
            participantIds: ["test_user_id", "target_user_id"],
            lastMessage: "Hi",
            lastMessageAt: Date(),
            lastSenderId: "test_user_id",
            unreadCounts: [:]
        )
        
        mockRepository.mockConversations = [conv]
        viewModel.startListening()
        
        // When
        let hasConversation = viewModel.hasConversation(with: "target_user_id")
        let hasMissingConversation = viewModel.hasConversation(with: "unknown_user_id")
        
        // Then
        XCTAssertTrue(hasConversation)
        XCTAssertFalse(hasMissingConversation)
    }
}
