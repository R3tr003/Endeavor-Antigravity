import Foundation
import Combine

class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var appError: AppError?
    
    private let repository: MessagesRepositoryProtocol
    
    init(repository: MessagesRepositoryProtocol = FirebaseMessagesRepository()) {
        self.repository = repository
    }
    
    func fetchConversations(userId: String) {
        guard !isLoading else { return }
        isLoading = true
        appError = nil
        
        repository.fetchConversations(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    self?.conversations = data
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
}
