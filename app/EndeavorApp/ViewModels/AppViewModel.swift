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
    
    // Pending Auth State for Onboarding (account will be created ONLY at the end)
    @Published var isOnboardingAuthPending: Bool = false
    private var pendingEmail: String?
    private var pendingPassword: String?
    private var pendingGoogleIdToken: String?
    private var pendingGoogleAccessToken: String?
    private var pendingGoogleEmail: String?
    private var pendingGooglePhotoUrl: String?
    private var pendingIsGoogle: Bool = false
    
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
    
    
    /// Smart authentication flow:
    /// - Returning users (existing Firestore profile): Firebase Auth only, NO Salesforce call. Fast.
    /// - New users (no Firestore profile): Firebase Auth → Salesforce check → Salesforce data → Onboarding.
    func authenticate(email: String, password: String) {
        router.appError = nil
        router.isLoading = true
        
        Task {
            // STEP 1: Verify if user already exists -> use login() which DOES NOT auto-create account
            let loginResult = await withCheckedContinuation { (continuation: CheckedContinuation<Result<(user: FirebaseAuth.User, email: String, isNewUser: Bool), Error>, Never>) in
                self.authService.login(email: email, password: password) { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch loginResult {
            case .success(let data):
                // User logged in directly (NO salesforce check, VERY FAST)
                await MainActor.run {
                    AnalyticsService.shared.logLogin(method: .email)
                    self.handleAuthSuccess(user: data.user, email: data.email)
                    self.router.isLoading = false
                }
                
            case .failure(let error):
                let nsError = error as NSError
                // If wrong password or other error, show it immediately
                if nsError.code != 17011 && nsError.code != 17004 { // 17011 = userNotFound, 17004 = invalidEmail
                    await MainActor.run {
                        self.router.isLoading = false
                        if nsError.code == 17009 {
                            self.router.appError = .authFailed(reason: "Incorrect password.")
                        } else {
                            self.router.appError = .authFailed(reason: error.localizedDescription)
                        }
                    }
                    return
                }
                
                // If user doesn't exist (17011), they are a NEW user!
                // STEP 2: Salesforce check FIRST for new users
                await MainActor.run { self.isSalesforceChecking = true }
                
                do {
                    let (authResult, salesforceData) = try await salesforceRepo.checkAndFetchContact(email: email)
                    await MainActor.run { self.isSalesforceChecking = false }
                    
                    guard authResult.authorized else {
                        await MainActor.run {
                            self.router.isLoading = false
                            self.router.appError = .notAuthorized
                        }
                        return
                    }
                    
                    // Authorized -> Wait for onboarding to complete before creating Firebase account
                    await MainActor.run {
                        self.pendingEmail = email
                        self.pendingPassword = password
                        self.pendingIsGoogle = false
                        
                        // Prep Onboarding
                        self.prepareOnboardingForNewUser(
                            email: email,
                            salesforceData: salesforceData,
                            firstName: "",
                            lastName: "",
                            photoUrl: ""
                        )
                        
                        self.isOnboardingAuthPending = true
                        self.router.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isSalesforceChecking = false
                        self.router.isLoading = false
                        let err = error as NSError
                        if err.domain == "com.firebase.functions" && err.code == 5 {
                            self.router.appError = .notAuthorized
                        } else {
                            self.router.appError = .salesforceUnavailable
                        }
                    }
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
        router.isLoading = true
        
        authService.startGoogleSignIn { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let credentials):
                let googleEmail = credentials.email.lowercased()
                let idToken = credentials.idToken
                let accessToken = credentials.accessToken
                let googleFirstName = credentials.firstName
                let googleLastName = credentials.lastName
                let googlePhotoUrl = credentials.photoUrl
                
                // Use server-side Cloud Function to check if user exists in Firestore.
                // This bypasses client auth rules (admin SDK) so it works before Firebase Auth sign-in.
                Task { @MainActor in
                    do {
                        let checkResult = try await self.salesforceRepo.checkUserExists(email: googleEmail)
                        
                        if checkResult.exists {
                            // RETURNING USER → sign in with Firebase Auth, then go to home
                            self.authService.signInWithGoogle(idToken: idToken, accessToken: accessToken) { authResult in
                                DispatchQueue.main.async {
                                    switch authResult {
                                    case .success(let data):
                                        AnalyticsService.shared.logLogin(method: .google)
                                        self.handleAuthSuccess(user: data.user, email: data.email)
                                    case .failure(let err):
                                        self.router.appError = .authFailed(reason: err.localizedDescription)
                                    }
                                    self.router.isLoading = false
                                }
                            }
                        } else {
                            // NEW USER → Salesforce check FIRST
                            self.isSalesforceChecking = true
                            let (sfAuthResult, salesforceData) = try await self.salesforceRepo.checkAndFetchContact(email: googleEmail)
                            self.isSalesforceChecking = false
                            
                            guard sfAuthResult.authorized else {
                                self.router.isLoading = false
                                self.router.appError = .notAuthorized
                                return
                            }
                            
                            // Salesforce authorized → prep onboarding (Firebase Auth deferred to "Enter App")
                            self.pendingGoogleIdToken = idToken
                            self.pendingGoogleAccessToken = accessToken
                            self.pendingGoogleEmail = googleEmail
                            self.pendingGooglePhotoUrl = googlePhotoUrl
                            self.pendingIsGoogle = true
                            
                            self.prepareOnboardingForNewUser(
                                email: googleEmail,
                                salesforceData: salesforceData,
                                firstName: googleFirstName,
                                lastName: googleLastName,
                                photoUrl: googlePhotoUrl,
                                isGoogle: true
                            )
                            
                            self.isOnboardingAuthPending = true
                            self.router.isLoading = false
                        }
                    } catch {
                        let wasSalesforceChecking = self.isSalesforceChecking
                        self.isSalesforceChecking = false
                        self.router.isLoading = false
                        let nsError = error as NSError
                        if nsError.domain == "com.firebase.functions" && nsError.code == 5 {
                            self.router.appError = .notAuthorized
                        } else if wasSalesforceChecking {
                            self.router.appError = .salesforceUnavailable
                        } else {
                            self.router.appError = .serviceUnavailable
                        }
                    }
                }
                
            case .failure(let error):
                self.router.isLoading = false
                self.router.appError = .unknown(reason: error.localizedDescription)
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
                        // No complete Firestore profile found (e.g. legacy account with missing data).
                        // Fetch Salesforce data for pre-fill, then show onboarding.
                        let isGoogleUser = user.providerData.map { $0.providerID }.contains("google.com")
                        
                        Task { @MainActor in
                            guard let self = self else { return }
                            self.isSalesforceChecking = true
                            
                            // Check for existing partial users doc to reuse its UUID
                            let existingId: UUID? = await withCheckedContinuation { cont in
                                self.userRepository.findAnyUserDoc(email: email.lowercased()) { id in
                                    cont.resume(returning: id)
                                }
                            }
                            
                            // Fetch Salesforce data for pre-fill
                            var salesforceData: SalesforceContactData? = nil
                            do {
                                let (sfAuth, sfData) = try await self.salesforceRepo.checkAndFetchContact(email: email.lowercased())
                                if sfAuth.authorized { salesforceData = sfData }
                            } catch {
                                print("⚠️ Salesforce pre-fill fetch failed: \(error.localizedDescription)")
                            }
                            self.isSalesforceChecking = false
                            
                            self.prepareOnboardingForNewUser(
                                email: email.lowercased(),
                                salesforceData: salesforceData,
                                firstName: googleFirstName,
                                lastName: googleLastName,
                                photoUrl: googlePhotoUrl,
                                isGoogle: isGoogleUser,
                                existingId: existingId
                            )
                            
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            self.authService.isLoggedIn = true
                            self.router.isLoading = false
                        }
                    }
                }
            }
        } else {
            if email.isEmpty { print("⚠️ No email available") }
            self.authService.isLoggedIn = true 
            self.router.isLoading = false
        }
    }
    
    /// Prepares the onboarding data for a new user WITHOUT authenticating them in Firebase yet.
    /// Pass `existingId` if a partial users doc already exists for this email — it will be reused
    /// so that completing onboarding overwrites the existing doc instead of creating a duplicate.
    private func prepareOnboardingForNewUser(
        email: String,
        salesforceData: SalesforceContactData?,
        firstName: String = "",
        lastName: String = "",
        photoUrl: String = "",
        isGoogle: Bool = false,
        existingId: UUID? = nil
    ) {
        var newUser = UserProfile(
            id: existingId ?? UUID(), // Reuse existing UUID if available to prevent duplicates
            firstName: firstName,
            lastName: lastName,
            role: "",
            email: email.lowercased(),
            location: "",
            timeZone: "",
            profileImageUrl: photoUrl
        )
        newUser.createdAt = Date()
        newUser.lastLoginAt = Date()
        self.userRepo.currentUser = newUser
        
        // Mark as social login before prefill so hideImageUpload works correctly in views
        self.onboardingViewModel.isSocialLogin = isGoogle
        // Clear any stale draft from a previous attempt and reset to step 1
        self.onboardingViewModel.clearDraft()
        self.onboardingViewModel.currentStep = 1
        // Pre-populate the onboarding user with profile data
        self.onboardingViewModel.user.email = email.lowercased()
        self.onboardingViewModel.user.profileImageUrl = photoUrl // Always set (empty for email/password, Google URL for Google)
        if !firstName.isEmpty { self.onboardingViewModel.user.firstName = firstName }
        if !lastName.isEmpty  { self.onboardingViewModel.user.lastName  = lastName  }
        
        if let sfData = salesforceData {
            self.onboardingViewModel.prefillFromSalesforce(sfData)
            // Preserve Google photo even after Salesforce prefill (Salesforce won't provide one)
            if !photoUrl.isEmpty {
                self.onboardingViewModel.user.profileImageUrl = photoUrl
            }
            AnalyticsService.shared.logSalesforcePrefillApplied()
            print("✅ [Salesforce] Pre-filled onboarding for \(sfData.firstName) \(sfData.lastName)")
        }
        
        // Final merge: keep onboarding user's name (Salesforce may have overridden it) 
        let prefilledUser = self.onboardingViewModel.user
        var mergedUser = newUser
        mergedUser.firstName = prefilledUser.firstName
        mergedUser.lastName = prefilledUser.lastName
        mergedUser.profileImageUrl = prefilledUser.profileImageUrl  // preserve photo
        self.userRepo.currentUser = mergedUser
    }
    
    // MARK: - Onboarding & Profile
    
    func completeOnboarding(user: UserProfile, company: CompanyProfile, profileImage: UIImage? = nil) {
        let finishOnboardingSave = { [weak self] in
            guard let self = self else { return }
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
            
            self.userRepo.companyProfile = company
            
            self.router.isLoading = true
            
            let timeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }
                if self?.router.isLoading == true {
                    self?.router.isLoading = false
                    self?.router.appError = .networkUnavailable
                }
            }
            
            let saveToFirestore = { [weak self] (userToSave: UserProfile) in
                guard let self = self else { return }
                self.userRepo.currentUser = userToSave
                
                print("📝 [Firestore] Saving user + company atomically: id=\(userToSave.id.uuidString) email=\(userToSave.email)")
                
                // Atomic batch write — both user and company succeed or both fail.
                // This prevents orphaned user profiles without company docs.
                self.userRepository.saveUserAndCompany(user: userToSave, company: company) { error in
                    timeoutTask.cancel()
                    DispatchQueue.main.async {
                        self.router.isLoading = false
                        if let err = error {
                            let nsErr = err as NSError
                            print("❌ [Firestore] saveUserAndCompany FAILED: domain=\(nsErr.domain) code=\(nsErr.code) msg=\(err.localizedDescription)")
                            self.router.appError = .dataCorrupted
                        } else {
                            print("✅ [Firestore] User + Company saved atomically. Onboarding complete.")
                            
                            self.router.isOnboardingComplete = true
                            UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                            UserDefaults.standard.set(userToSave.id.uuidString, forKey: "userId")
                            UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
                            
                            AnalyticsService.shared.logOnboardingCompleted(
                                userType: userToSave.userType,
                                role: userToSave.role
                            )
                            // Salva mappatura firebaseUid -> uuid per le regole Firestore del messaging
                            if let firebaseUid = Auth.auth().currentUser?.uid {
                                self.messagesRepository.saveUserMapping(
                                    firebaseUid: firebaseUid,
                                    uuid: userToSave.id.uuidString
                                )
                            }
                            // Clear Salesforce pre-fill state after successful onboarding
                            self.onboardingViewModel.isSalesforcePrefilled = false
                        }
                    }
                }
            }
            
            if let image = profileImage, user.profileImageUrl == "pending_upload" {
                guard let firebaseUid = Auth.auth().currentUser?.uid else { return }
                let imagePath = "profile_images/\(firebaseUid).jpg"
                self.storageRepository.uploadImage(image: image, path: imagePath) { result in
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
        
        if self.isOnboardingAuthPending {
            self.router.isLoading = true
            Task { @MainActor in
                if self.pendingIsGoogle, let idToken = self.pendingGoogleIdToken, let accessToken = self.pendingGoogleAccessToken {
                    self.authService.signInWithGoogle(idToken: idToken, accessToken: accessToken) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                AnalyticsService.shared.logSignUp(method: .google)
                                self.finalizeAuthPendingState()
                                finishOnboardingSave()
                            case .failure(let error):
                                self.router.isLoading = false
                                self.router.appError = .authFailed(reason: error.localizedDescription)
                            }
                        }
                    }
                } else if let email = self.pendingEmail, let password = self.pendingPassword {
                    self.authService.signUpNewUser(email: email, password: password) { signUpResult in
                        DispatchQueue.main.async {
                            switch signUpResult {
                            case .success(_):
                                AnalyticsService.shared.logSignUp(method: .email)
                                self.finalizeAuthPendingState()
                                finishOnboardingSave()
                            case .failure(let signupError):
                                self.router.isLoading = false
                                let err = signupError as NSError
                                if err.code == 17007 { self.router.appError = .emailAlreadyInUse }
                                else if err.code == 17026 { self.router.appError = .weakPassword }
                                else { self.router.appError = .authFailed(reason: "Registration failed: \(err.localizedDescription)") }
                            }
                        }
                    }
                } else {
                    finishOnboardingSave()
                }
            }
        } else {
            finishOnboardingSave()
        }
    }
    
    private func finalizeAuthPendingState() {
        self.isOnboardingAuthPending = false
        self.authService.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        
        // Save Email/UID right away
        if let currentUser = Auth.auth().currentUser {
            UserDefaults.standard.set(currentUser.email, forKey: "userEmail")
            UserDefaults.standard.set(currentUser.uid, forKey: "firebaseUid")
        }
        
        self.pendingEmail = nil
        self.pendingPassword = nil
        self.pendingGoogleIdToken = nil
        self.pendingGoogleAccessToken = nil
        self.pendingGoogleEmail = nil
        self.pendingGooglePhotoUrl = nil
        self.pendingIsGoogle = false
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
        
        userRepository.saveUserAndCompany(user: user, company: company) { [weak self] error in
            DispatchQueue.main.async {
                self?.router.isLoading = false
                if let error = error {
                    print("Error saving profile changes: \(error)")
                    self?.router.appError = .unknown(reason: "Failed to save profile changes.")
                    completion?(false)
                } else {
                    AnalyticsService.shared.logProfileEdited()
                    completion?(true)
                }
            }
        }
    }
    
    func updateProfileImage(_ image: UIImage) {
        guard let customUser = userRepo.currentUser else { return }
        router.isLoading = true
        guard let firebaseUid = Auth.auth().currentUser?.uid else { return }
        let path = "profile_images/\(firebaseUid).jpg"
        
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
                    // Attempt to delete the old legacy image if it existed
                    let oldPath = "profile_images/\(customUser.id.uuidString).jpg"
                    Storage.storage().reference().child(oldPath).delete { _ in /* silent */ }
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
        
        // Clear onboarding draft to prevent leaking data to next user on same device
        onboardingViewModel.clearDraft()
        
        // Reset pending onboarding auth state so a subsequent user
        // cannot inherit credentials from an incomplete registration.
        isOnboardingAuthPending = false
        pendingEmail = nil
        pendingPassword = nil
        pendingGoogleIdToken = nil
        pendingGoogleAccessToken = nil
        pendingGoogleEmail = nil
        pendingGooglePhotoUrl = nil
        pendingIsGoogle = false
        
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
        let firebaseUid = Auth.auth().currentUser?.uid
        router.isLoading = true
        
        // STEP 1: Delete Firestore data FIRST while the auth token is still valid.
        // Calling deleteAuthAccount() first invalidates the token immediately,
        // causing all subsequent Firestore writes to fail silently with
        // "Missing or insufficient permissions".
        userRepository.deleteUserData(email: email, userId: userId, firebaseUid: firebaseUid) { [weak self] dataError in
            if let error = dataError {
                DispatchQueue.main.async {
                    self?.router.isLoading = false
                    completion(.failure(error))
                }
                return
            }
            
            // STEP 2: Only delete Firebase Auth account after all Firestore data is gone.
            self?.userRepository.deleteAuthAccount(password: password) { authError in
                DispatchQueue.main.async {
                    self?.router.isLoading = false
                    if let error = authError {
                        completion(.failure(error))
                    } else {
                        self?.clearAllLocalData()
                        completion(.success(()))
                    }
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
