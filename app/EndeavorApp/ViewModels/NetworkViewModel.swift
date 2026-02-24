import Foundation
import Combine
import FirebaseFirestore // For DocumentSnapshot pagination cursor

class NetworkViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var isLoading = false
    @Published var hasMoreData = true
    
    private let repository: NetworkRepositoryProtocol
    private var lastDocument: DocumentSnapshot? = nil
    
    init(repository: NetworkRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchUsers(isInitial: Bool = false) {
        if isInitial {
            profiles = []
            lastDocument = nil
            hasMoreData = true
        }
        
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        repository.fetchAllUsers(limit: 20, lastDocument: lastDocument) { [weak self] newUsers, newLastDoc in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if newUsers.isEmpty {
                    self.hasMoreData = false
                    return
                }
                
                // Filter duplicates
                let existingIds = Set(self.profiles.map { $0.id })
                let uniqueNewUsers = newUsers.filter { !existingIds.contains($0.id) }
                
                self.profiles.append(contentsOf: uniqueNewUsers)
                self.lastDocument = newLastDoc
                
                if uniqueNewUsers.count < 20 {
                    self.hasMoreData = false
                }
            }
        }
    }
}
