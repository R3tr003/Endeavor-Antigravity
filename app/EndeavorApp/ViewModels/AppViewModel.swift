import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn

/// `AppViewModel` acts as a Facade Coordinator. 
/// It maintains the exact same `@Published` API to avoid breaking existing views,
/// but delegates all business logic to `AuthService`, `UserRepository`, and `NavigationRouter`.
class AppViewModel: ObservableObject {
    // Core Services
    let authService = AuthService()
    let userRepo = UserRepository()
    let router = NavigationRouter()
    
    let userRepository: UserRepositoryProtocol
    let storageRepository: StorageRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Exposed State (Facade)
    @Published var currentUser: UserProfile?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var isLoading: Bool = false
    @Published var isCheckingAuth: Bool = false
    @Published var appError: AppError?
    @Published var emailCollisionDetected: Bool = false
    @Published var selectedTheme: String = "Dark"
    @Published var failedLoginAttempts: Int = 0
    @Published var passwordResetSent: Bool = false
    
    var colorScheme: ColorScheme? {
        router.colorScheme
    }
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         storageRepository: StorageRepositoryProtocol = FirebaseStorageRepository()) {
        self.userRepository = userRepository
        self.storageRepository = storageRepository
        
        bindServices()
        checkInitialAuthState()
    }
    
    // MARK: - Binding
    private func bindServices() {
        // Auth Bindings
        authService.$isLoggedIn.assign(to: &$isLoggedIn)
        authService.$failedLoginAttempts.assign(to: &$failedLoginAttempts)
        authService.$passwordResetSent.assign(to: &$passwordResetSent)
        authService.$emailCollisionDetected.assign(to: &$emailCollisionDetected)
        
        // UserRepo Bindings
        userRepo.$currentUser.assign(to: &$currentUser)
        userRepo.$companyProfile.assign(to: &$companyProfile)
        
        // Router Bindings
        router.$isOnboardingComplete.assign(to: &$isOnboardingComplete)
        router.$selectedTheme.assign(to: &$selectedTheme)
        
        // Combine all isLoading states
        Publishers.CombineLatest(userRepo.$isFetching, router.$isLoading)
            .map { $0 || $1 }
            .assign(to: &$isLoading)
            
        // Combine error messages
        router.$appError.assign(to: &$appError)
    }
    
    // MARK: - Initialization
    private func checkInitialAuthState() {
        self.isCheckingAuth = true
        let savedIsLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        
        // Stale Firebase Session Check
        if !savedIsLoggedIn && Auth.auth().currentUser != nil {
            print("⚠️ Stale Firebase session detected. Signing out.")
            authService.logout()
            router.clearState()
            self.isCheckingAuth = false
            return
        }
        
        authService.isLoggedIn = savedIsLoggedIn
        
        if authService.isLoggedIn && router.isOnboardingComplete {
            restoreSession()
        } else if authService.isLoggedIn {
            if Auth.auth().currentUser == nil {
                print("⚠️ Stale session detected (No Firebase User). Logging out.")
                logout()
            }
            self.isCheckingAuth = false
        } else {
            self.isCheckingAuth = false
        }
    }
    
    // MARK: - Orchestration Logic
    
    func restoreSession() {
        userRepo.restoreSession { [weak self] in
            if self?.currentUser == nil {
                print("⚠️ Invalid session state. Logging out.")
                self?.logout()
            }
            self?.isCheckingAuth = false
        }
    }
    
    // MARK: Auth Forwarding
    
    func login(email: String, password: String) {
        router.isLoading = true
        router.appError = nil
        
        authService.login(email: email, password: password) { [weak self] result in
            self?.router.isLoading = false
            switch result {
            case .success(let data):
                print("✅ Signed in as: \(data.user.uid)")
                self?.handleAuthSuccess(user: data.user, email: data.email)
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == 17011 {
                    self?.router.appError = .userNotFound
                } else if nsError.code == 17009 {
                    self?.router.appError = .authFailed(reason: "Incorrect password. Please try again.")
                } else {
                    self?.router.appError = .authFailed(reason: "Login failed. Please check your credentials.")
                }
            }
        }
    }
    
    func authenticate(email: String, password: String) {
        router.isLoading = true
        router.appError = nil
        
        authService.authenticate(email: email, password: password) { [weak self] result in
            self?.router.isLoading = false
            switch result {
            case .success(let data):
                self?.handleAuthSuccess(user: data.user, email: data.email)
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == 17009 || error.localizedDescription.lowercased().contains("password") {
                    self?.router.appError = .authFailed(reason: "Incorrect Password")
                } else {
                    self?.router.appError = .authFailed(reason: "Incorrect Password")
                }
            }
        }
    }
    
    func signUpNewUser(email: String, password: String) {
        router.isLoading = true
        router.appError = nil
        
        authService.signUpNewUser(email: email, password: password) { [weak self] result in
            self?.router.isLoading = false
            switch result {
            case .success(let data):
                self?.handleAuthSuccess(user: data.user, email: data.email)
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == 17007 {
                    self?.router.appError = .emailAlreadyInUse
                } else if nsError.code == 17026 {
                    self?.router.appError = .weakPassword
                } else {
                    self?.router.appError = .authFailed(reason: "Registration failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendPasswordReset(email: String) {
        router.isLoading = true
        authService.sendPasswordReset(email: email) { [weak self] error in
            self?.router.isLoading = false
            if let error = error {
                let nsError = error as NSError
                if nsError.code == 17011 {
                    self?.router.appError = .userNotFound
                } else {
                    self?.router.appError = .unknown(reason: "Failed to send reset email: \(error.localizedDescription)")
                }
            } else {
                self?.router.appError = nil
            }
        }
    }
    
    func startGoogleSignIn() {
        router.appError = nil
        authService.startGoogleSignIn { [weak self] result in
            switch result {
            case .success(let data):
                self?.handleAuthSuccess(user: data.user, email: data.email)
            case .failure(let error):
                self?.router.isLoading = false
                self?.router.appError = .unknown(reason: error.localizedDescription)
            }
        }
    }
    
    private func handleAuthSuccess(user: FirebaseAuth.User, email: String) {
        router.isLoading = true
        
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(user.uid, forKey: "firebaseUid")
        
        var googleFirstName = ""
        var googleLastName = ""
        if let displayName = user.displayName {
            let components = displayName.components(separatedBy: " ")
            if let first = components.first { googleFirstName = first }
            if components.count > 1 { googleLastName = components.dropFirst().joined(separator: " ") }
        }
        let googlePhotoUrl = user.photoURL?.absoluteString ?? ""
        
        if self.currentUser == nil && !email.isEmpty {
            userRepository.findCompleteUserProfile(email: email.lowercased()) { [weak self] result in
                DispatchQueue.main.async {
                    if case .success(let (profile, company)) = result {
                        var updatedProfile = profile
                        updatedProfile.lastLoginAt = Date()
                        self?.userRepo.currentUser = updatedProfile
                        self?.userRepo.companyProfile = company
                        
                        // Update last login in Firestore silently
                        self?.userRepository.saveUserProfile(updatedProfile) { _ in }
                        
                        UserDefaults.standard.set(profile.id.uuidString, forKey: "userId")
                        UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        
                        self?.router.isOnboardingComplete = true
                        self?.authService.isLoggedIn = true
                        self?.router.isLoading = false
                    } else {
                        var newUser = UserProfile(
                            id: UUID(),
                            firstName: googleFirstName,
                            lastName: googleLastName,
                            role: "",
                            email: email.lowercased(),
                            location: "",
                            timeZone: "",
                            profileImageUrl: googlePhotoUrl
                        )
                        newUser.createdAt = Date()
                        newUser.lastLoginAt = Date()
                        
                        self?.userRepo.currentUser = newUser
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        self?.authService.isLoggedIn = true
                        self?.router.isLoading = false
                    }
                }
            }
        } else {
            if email.isEmpty { print("⚠️ No email available") }
            self.authService.isLoggedIn = true 
            self.router.isLoading = false
        }
    }
    
    // MARK: - Onboarding & Profile
    
    func completeOnboarding(user: UserProfile, company: CompanyProfile, profileImage: UIImage? = nil) {
        var finalUser = user
        
        // Preserve tracking fields and ID from existing auth user
        if let existingUser = self.userRepo.currentUser {
            finalUser.id = existingUser.id
            finalUser.createdAt = existingUser.createdAt
            finalUser.lastLoginAt = existingUser.lastLoginAt
            if finalUser.profileImageUrl.isEmpty || finalUser.profileImageUrl == "pending_upload" {
                // Keep the google image if available and no new image was uploaded
                if profileImage == nil {
                    finalUser.profileImageUrl = existingUser.profileImageUrl
                }
            }
        }
        
        userRepo.companyProfile = company
        router.isOnboardingComplete = true
        
        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
        UserDefaults.standard.set(user.id.uuidString, forKey: "userId")
        UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
        
        router.isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            if self?.router.isLoading == true {
                self?.router.isLoading = false
                self?.router.appError = .networkUnavailable
            }
        }
        
        let saveToFirestore = { [weak self] (userToSave: UserProfile) in
            self?.userRepo.currentUser = userToSave
            
            // Chain saves to avoid race conditions with Firestore rules
            // Company rules depend on get(user).email == request.auth.token.email
            self?.userRepository.saveUserProfile(userToSave) { error in
                if let err = error {
                    DispatchQueue.main.async {
                        self?.router.appError = .dataCorrupted
                        self?.router.isLoading = false
                    }
                    print("Error saving user: \(err)")
                    return
                }
                
                self?.userRepository.saveCompanyProfile(company, userId: userToSave.id.uuidString) { companyError in
                    DispatchQueue.main.async {
                        self?.router.isLoading = false
                        if let cErr = companyError {
                            self?.router.appError = .dataCorrupted
                            print("Error saving company: \(cErr)")
                        } else {
                            print("✅ Onboarding completed and saved.")
                        }
                    }
                }
            }
        }
        
        if let image = profileImage, user.profileImageUrl == "pending_upload" {
            let imagePath = "profile_images/\(user.id.uuidString).jpg"
            storageRepository.uploadImage(image: image, path: imagePath) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let url): finalUser.profileImageUrl = url
                    case .failure: finalUser.profileImageUrl = ""
                    }
                    saveToFirestore(finalUser)
                }
            }
        } else {
            saveToFirestore(finalUser)
        }
    }
    
    func saveProfileChanges(completion: ((Bool) -> Void)? = nil) {
        guard let user = self.currentUser, let company = self.companyProfile else { 
            completion?(false)
            return 
        }
        
        // Sync the changes back to the underlying repository state
        self.userRepo.currentUser = user
        self.userRepo.companyProfile = company
        
        router.isLoading = true
        
        let dispatchGroup = DispatchGroup()
        var hasError = false
        
        dispatchGroup.enter()
        userRepository.saveUserProfile(user) { [weak self] error in 
            if let error = error {
                hasError = true
                print("Error saving user profile: \(error)")
                DispatchQueue.main.async { self?.router.appError = .unknown(reason: "Failed to save user profile.") }
            }
            dispatchGroup.leave() 
        }
        
        dispatchGroup.enter()
        userRepository.saveCompanyProfile(company, userId: user.id.uuidString) { [weak self] error in 
            if let error = error {
                hasError = true
                print("Error saving company profile: \(error)")
                DispatchQueue.main.async { self?.router.appError = .unknown(reason: "Failed to save company profile.") }
            }
            dispatchGroup.leave() 
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.router.isLoading = false
            completion?(!hasError)
        }
    }
    
    func updateProfileImage(_ image: UIImage) {
        guard let customUser = userRepo.currentUser else { return }
        router.isLoading = true
        let path = "profile_images/\(customUser.id.uuidString).jpg"
        
        storageRepository.uploadImage(image: image, path: path) { [weak self] result in
            DispatchQueue.main.async {
                self?.router.isLoading = false
                switch result {
                case .success(let url):
                    self?.userRepo.currentUser?.profileImageUrl = url
                    if let user = self?.userRepo.currentUser {
                        self?.userRepository.saveUserProfile(user) { _ in }
                    }
                case .failure(let error):
                    self?.router.appError = .unknown(reason: "Failed to upload image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Helper to check if user is using Google authentication
    var isGoogleUser: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        return user.providerData.contains { $0.providerID == "google.com" }
    }
    
    func removeProfileImage() {
        guard userRepo.currentUser != nil else { return }
        router.isLoading = true
        
        self.userRepo.currentUser?.profileImageUrl = ""
        
        if let user = self.userRepo.currentUser {
            userRepository.saveUserProfile(user) { [weak self] error in
                DispatchQueue.main.async {
                    self?.router.isLoading = false
                    if let error = error {
                        self?.router.appError = .unknown(reason: "Failed to remove image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Settings & Logout
    
    func setTheme(_ theme: String) {
        router.setTheme(theme)
    }
    
    func logout() {
        authService.logout()
        userRepo.clearState()
        router.clearState()
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isOnboardingComplete")
    }
    
    func changeEmail(newEmail: String, password: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        router.isLoading = true
        userRepository.changeUserEmail(newEmail: newEmail, password: password) { [weak self] error in
            DispatchQueue.main.async {
                self?.router.isLoading = false
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func deleteAccount(password: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let email = userRepo.currentUser?.email, !email.isEmpty else {
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user email found"])))
            return
        }
        
        let userId = userRepo.currentUser?.id.uuidString ?? ""
        router.isLoading = true
        
        userRepository.deleteAuthAccount(password: password) { [weak self] authError in
            if let error = authError {
                DispatchQueue.main.async {
                    self?.router.isLoading = false
                    self?.router.appError = .unknown(reason: "Failed to delete account: \(error.localizedDescription)")
                    completion(.failure(error))
                }
                return
            }
            
            self?.userRepository.deleteUserData(email: email, userId: userId) { dataError in
                DispatchQueue.main.async {
                    self?.router.isLoading = false
                    self?.clearAllLocalData()
                    completion(.success(()))
                }
            }
        }
    }
    
    private func clearAllLocalData() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
        authService.logout()
        userRepo.clearState()
        router.clearState()
    }
}
