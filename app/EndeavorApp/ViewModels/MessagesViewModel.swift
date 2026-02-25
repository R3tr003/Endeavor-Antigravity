import Foundation
import Combine

class MessagesViewModel: ObservableObject {
    @Published var messageMetrics: MessageMetrics?
    @Published var isLoading = false
    @Published var appError: AppError?
    
    private let repository: MessagesRepositoryProtocol
    
    init(repository: MessagesRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchMessages(userId: String) {
        guard !isLoading else { return }
        isLoading = true
        appError = nil
        
        repository.fetchMessages(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    self?.messageMetrics = data
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
}
