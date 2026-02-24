import Foundation
import Combine

class UserRepository: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var companyProfile: CompanyProfile?
    
    // Using a reference to NavigationRouter isn't strictly necessary if it's injected 
    // at the app level, but we need some way to set `isLoading`. 
    // For simplicity and decoupling, UserRepository can have its own `isLoading` or 
    // we can pass a completion block. Let's add a local `isFetching` so views can show spinners.
    @Published var isFetching: Bool = false
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository()) {
        self.userRepository = userRepository
    }
    
    func restoreSession(completion: @escaping () -> Void = {}) {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let companyId = UserDefaults.standard.string(forKey: "companyId") else {
            print("⚠️ Invalid session state. Cannot restore.")
            completion()
            return
        }
        
        self.isFetching = true
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        userRepository.fetchUserProfile(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let user) = result {
                    self?.currentUser = user
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        userRepository.fetchCompanyProfile(companyId: companyId) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let company) = result {
                    self?.companyProfile = company
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isFetching = false
            completion()
        }
    }
    
    func clearState() {
        self.currentUser = nil
        self.companyProfile = nil
    }
}
