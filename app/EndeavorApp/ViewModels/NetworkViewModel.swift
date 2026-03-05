import Foundation
import Combine
import FirebaseFirestore // For DocumentSnapshot pagination cursor
import SDWebImage

class NetworkViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var isLoading = false
    @Published var hasMoreData = true
    
    @Published var companyNames: [String: String] = [:]
    
    private let repository: NetworkRepositoryProtocol
    private var lastDocument: DocumentSnapshot? = nil
    
    init(repository: NetworkRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchUsers(currentUserId: String, isInitial: Bool = false) {
        if isInitial {
            profiles = []
            lastDocument = nil
            hasMoreData = true
            companyNames = [:] // Clear cache on refresh
        }
        
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        repository.fetchAllUsers(limit: 20, currentUserId: currentUserId, lastDocument: lastDocument) { [weak self] newUsers, newLastDoc in
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
                
                self.fetchCompanyNames(for: uniqueNewUsers)
                
                // Prefetch immagini in background — quando la card appare, l'immagine è già in cache
                let urls = uniqueNewUsers
                    .compactMap { URL(string: $0.profileImageUrl) }
                    .filter { !$0.absoluteString.isEmpty }
                
                if !urls.isEmpty {
                    SDWebImagePrefetcher.shared.prefetchURLs(urls)
                }
                
                if uniqueNewUsers.count < 20 {
                    self.hasMoreData = false
                }
            }
        }
    }
    
    private func fetchCompanyNames(for users: [UserProfile]) {
        let db = Firestore.firestore()
        for user in users {
            let userId = user.id.uuidString
            // Skip if already fetched
            guard companyNames[userId] == nil else { continue }
            
            db.collection("companies")
                .whereField("userId", isEqualTo: userId)
                .limit(to: 1)
                .getDocuments { [weak self] snapshot, _ in
                    if let name = snapshot?.documents.first?.data()["name"] as? String {
                        DispatchQueue.main.async {
                            self?.companyNames[userId] = name
                        }
                    }
                }
        }
    }
}
