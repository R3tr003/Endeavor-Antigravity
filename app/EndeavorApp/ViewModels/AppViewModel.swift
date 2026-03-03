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
    let salesforceRepo: SalesforceRepositoryProtocol
    private let messagesRepository = FirebaseMessagesRepository()
    
    // Shared OnboardingViewModel instance (to allow Salesforce pre-fill before navigation)
    let onboardingViewModel = OnboardingViewModel()

    private var cancellables = Set<AnyCancellable>()
    
    // Salesforce data cache — pre-fills onboarding when no Firestore profile exists
    private var pendingSalesforceData: SalesforceContactData?
    
    // MARK: - Exposed State (Facade)
    @Published var currentUser: UserProfile?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var isLoading: Bool = false
    @Published var isCheckingAuth: Bool = false
    @Published var isSalesforceChecking: Bool = false  // Dedicated Salesforce verification state
    @Published var appError: AppError?
    @Published var emailCollisionDetected: Bool = false
    @Published var selectedTheme: String = "Dark"
    @Published var failedLoginAttempts: Int = 0
    @Published var passwordResetSent: Bool = false
    
    var colorScheme: ColorScheme? {
        router.colorScheme
    }
    
    init(userRepository: UserRepositoryProtocol = FirebaseUserRepository(),
         storageRepository: StorageRepositoryProtocol = FirebaseStorageRepository(),
         salesforceRepo: SalesforceRepositoryProtocol = SalesforceRepository()) {
        self.userRepository = userRepository
        self.storageRepository = storageRepository
        self.salesforceRepo = salesforceRepo
        
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
            } else if let firebaseUid = Auth.auth().currentUser?.uid,
                      let uuid = self?.currentUser?.id.uuidString {
                // Assicura che la mappatura firebaseUid -> uuid esista nel database messaging
                self?.messagesRepository.saveUserMapping(firebaseUid: firebaseUid, uuid: uuid)
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
    
    /// Smart authentication flow:
    /// - Returning users (existing Firestore profile): Firebase Auth only, NO Salesforce call. Fast.
    /// - New users (no Firestore profile): Firebase Auth → Salesforce check → Salesforce data → Onboarding.
    func authenticate(email: String, password: String) {
        router.appError = nil
        // Show spinner immediately — before any async work
        router.isLoading = true

        Task {
            do {
                // STEP 1: Firebase Auth first (fast — local cache + Firebase SDK)
                let firebaseResult = await withCheckedContinuation { (continuation: CheckedContinuation<Result<(user: FirebaseAuth.User, email: String, isNewUser: Bool), Error>, Never>) in
                    self.authService.authenticate(email: email, password: password) { result in
                        continuation.resume(returning: result)
                    }
                }

                switch firebaseResult {
                case .failure(let error):
                    await MainActor.run {
                        self.router.isLoading = false
                        let nsError = error as NSError
                        if nsError.code == 17009 || error.localizedDescription.lowercased().contains("password"){
                            self.router.appError = .authFailed(reason: "Incorrect Password")
                        } else {
                            self.router.appError = .authFailed(reason: "Incorrect Password")
                        }
                    }
                    return

                case .success(let data):
                    // STEP 2: Check if user already has a Firestore profile (returning user)
                    let hasProfile = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                        self.userRepository.findCompleteUserProfile(email: email.lowercased()) { result in
                            if case .success = result { continuation.resume(returning: true) }
                            else { continuation.resume(returning: false) }
                        }
                    }

                    if hasProfile {
                        // FAST PATH: Returning user — skip Salesforce entirely
                        await MainActor.run {
                            self.router.isLoading = false
                            AnalyticsService.shared.logLogin(method: .email)
                            self.handleAuthSuccess(user: data.user, email: data.email)
                        }
                    } else {
                        // SLOW PATH: New user — Salesforce check + data fetch
                        await MainActor.run { self.isSalesforceChecking = true }
                        do {
                            let authResult = try await salesforceRepo.checkAuthorization(email: email)
                            guard authResult.authorized, let contactId = authResult.contactId else {
                                await MainActor.run {
                                    self.isSalesforceChecking = false
                                    self.router.isLoading = false
                                    self.router.appError = .notAuthorized
                                }
                                return
                            }
                            let salesforceData = try await salesforceRepo.getContactData(contactId: contactId)
                            await MainActor.run {
                                self.isSalesforceChecking = false
                                self.pendingSalesforceData = salesforceData
                                AnalyticsService.shared.logLogin(method: .email)
                                self.handleAuthSuccess(user: data.user, email: data.email)
                            }
                        } catch {
                            await MainActor.run {
                                self.isSalesforceChecking = false
                                self.router.isLoading = false
                                let nsError = error as NSError
                                if nsError.domain == "com.firebase.functions" && nsError.code == 5 {
                                    self.router.appError = .notAuthorized
                                } else {
                                    self.router.appError = .salesforceUnavailable
                                }
                            }
                        }
                    }
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
                AnalyticsService.shared.logSignUp(method: .email)
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
    
    /// Google Sign In with Salesforce authorization gate.
    func startGoogleSignIn() {
        router.appError = nil
        authService.startGoogleSignIn { [weak self] result in
            switch result {
            case .success(let data):
                let googleEmail = data.email
                // Salesforce check for Google sign-in email
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isSalesforceChecking = true
                    do {
                        let authResult = try await self.salesforceRepo.checkAuthorization(email: googleEmail)
                        self.isSalesforceChecking = false
                        guard authResult.authorized else {
                            self.router.appError = .notAuthorized
                            return
                        }
                        // Authorized — log Google login and proceed
                        AnalyticsService.shared.logLogin(method: .google)
                        self.handleAuthSuccess(user: data.user, email: googleEmail)
                    } catch {
                        self.isSalesforceChecking = false
                        self.router.appError = .salesforceUnavailable
                    }
                }
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

                        // Salva mappatura firebaseUid -> uuid per le regole Firestore del messaging
                        self?.messagesRepository.saveUserMapping(
                            firebaseUid: user.uid,
                            uuid: profile.id.uuidString
                        )

                        self?.router.isOnboardingComplete = true
                        self?.authService.isLoggedIn = true
                        self?.router.isLoading = false
                    } else {
                        // No Firestore profile found → show onboarding
                        // Pre-fill with Salesforce data if available (regardless of isNewUser)
                        let isGoogleUser = user.providerData.map { $0.providerID }.contains("google.com")
                        if let sfData = self?.pendingSalesforceData {
                            self?.onboardingViewModel.prefillFromSalesforce(sfData)
                            self?.pendingSalesforceData = nil
                            AnalyticsService.shared.logSalesforcePrefillApplied()
                            print("✅ [Salesforce] Pre-filled onboarding for \(sfData.firstName) \(sfData.lastName)")
                        }
                        self?.onboardingViewModel.isSocialLogin = isGoogleUser
                        
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
        
        // Always ensure email is set — email is not editable during onboarding,
        // so take it from Firebase Auth first, then fall back to existingUser.
        if finalUser.email.isEmpty {
            if let authEmail = Auth.auth().currentUser?.email, !authEmail.isEmpty {
                finalUser.email = authEmail.lowercased()
            } else if let existingEmail = self.userRepo.currentUser?.email, !existingEmail.isEmpty {
                finalUser.email = existingEmail
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
            
            print("📝 [Firestore] Saving user: id=\(userToSave.id.uuidString) email=\(userToSave.email) fields=13+")
            
            // Chain saves to avoid race conditions with Firestore rules
            // Company rules depend on get(user).email == request.auth.token.email
            self?.userRepository.saveUserProfile(userToSave) { error in
                if let err = error {
                    let nsErr = err as NSError
                    print("❌ [Firestore] saveUserProfile FAILED: domain=\(nsErr.domain) code=\(nsErr.code) msg=\(err.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.router.appError = .dataCorrupted
                        self?.router.isLoading = false
                    }
                    return
                }
                
                print("✅ [Firestore] User saved. Saving company: id=\(company.id.uuidString)")
                
                self?.userRepository.saveCompanyProfile(company, userId: userToSave.id.uuidString) { companyError in
                    DispatchQueue.main.async {
                        self?.router.isLoading = false
                        if let cErr = companyError {
                            let nsErr = cErr as NSError
                            print("❌ [Firestore] saveCompanyProfile FAILED: domain=\(nsErr.domain) code=\(nsErr.code) msg=\(cErr.localizedDescription)")
                            self?.router.appError = .dataCorrupted
                        } else {
                            print("✅ [Firestore] Company saved. Onboarding complete.")
                            AnalyticsService.shared.logOnboardingCompleted(
                                userType: userToSave.userType,
                                role: userToSave.role
                            )
                            // Salva mappatura firebaseUid -> uuid per le regole Firestore del messaging
                            if let firebaseUid = Auth.auth().currentUser?.uid {
                                self?.messagesRepository.saveUserMapping(
                                    firebaseUid: firebaseUid,
                                    uuid: userToSave.id.uuidString
                                )
                            }
                            // Clear Salesforce pre-fill state after successful onboarding
                            self?.onboardingViewModel.isSalesforcePrefilled = false
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
            if !hasError {
                AnalyticsService.shared.logProfileEdited()
            }
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
                    AnalyticsService.shared.logProfileImageUploaded()
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
    
    // MARK: - Messaging Setup

    /// Assicura che la mappatura firebaseUid -> uuid esista nel database messaging.
    /// Da chiamare prima di iniziare a ascoltare le conversazioni.
    func ensureMessagingMappingExists(completion: (() -> Void)? = nil) {
        guard let firebaseUid = Auth.auth().currentUser?.uid,
              let uuid = currentUser?.id.uuidString else {
            completion?()
            return
        }
        messagesRepository.saveUserMapping(firebaseUid: firebaseUid, uuid: uuid) { _ in
            completion?()
        }
    }

    // MARK: - Settings & Logout

    func setTheme(_ theme: String) {
        router.setTheme(theme)
    }
    
    func logout() {
        AnalyticsService.shared.logLogout()
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
