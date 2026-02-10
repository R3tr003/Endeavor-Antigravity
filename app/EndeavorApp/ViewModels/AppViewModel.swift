import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn

class AppViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var isLoading: Bool = false
    @Published var isCheckingAuth: Bool = false  // True while checking if existing user
    @Published var errorMessage: String?
    @Published var emailCollisionDetected: Bool = false
    @Published var selectedTheme: String = "Dark"
    @Published var failedLoginAttempts: Int = 0 // Track failed logins
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil  // System
        }
    }
    
    init() {
        // Load saved theme preference
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        
        // Check auth and onboarding state from UserDefaults
        let savedIsLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let savedIsOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        
        // IMPORTANT: Check for stale Firebase Auth session after app reinstall
        // If UserDefaults says user is NOT logged in, but Firebase Auth has a session,
        // it means the app was reinstalled. We must clear the Firebase session
        // to force proper re-authentication.
        if !savedIsLoggedIn && Auth.auth().currentUser != nil {
            print("⚠️ Stale Firebase session detected (app was reinstalled). Signing out.")
            try? Auth.auth().signOut()
            // Don't set isLoggedIn to true - user must re-authenticate
            self.isLoggedIn = false
            self.isOnboardingComplete = false
            return
        }
        
        self.isLoggedIn = savedIsLoggedIn
        self.isOnboardingComplete = savedIsOnboardingComplete
        
        // Load Real Data if Logged In
        if isLoggedIn && isOnboardingComplete {
            self.restoreSession()
        } else if isLoggedIn {
             // We are logged in but onboarding is not complete.
             // Validate that we actually have a Firebase user, otherwise reset.
             if Auth.auth().currentUser == nil {
                 print("⚠️ Stale session detected (No Firebase User). Logging out.")
                 self.logout()
             }
        }
    }
    
    func restoreSession() {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let companyId = UserDefaults.standard.string(forKey: "companyId") else {
            // If we are logged in but missing IDs (e.g. legacy state), force logout to reset
            print("⚠️ Invalid session state. Logging out.")
            self.logout()
            return
        }
        
        self.isLoading = true
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        FirebaseService.shared.loadUserProfile(userId: userId) { [weak self] user in
            DispatchQueue.main.async {
                self?.currentUser = user
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        FirebaseService.shared.loadCompanyProfile(companyId: companyId) { [weak self] company in
            DispatchQueue.main.async {
                self?.companyProfile = company
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    func login(email: String, password: String) {
        self.isLoading = true
        self.errorMessage = nil // Clear previous errors
        
        // Sign In ONLY - do not auto-create users
        FirebaseService.shared.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    print("✅ Signed in as: \(user.uid)")
                    self?.failedLoginAttempts = 0 // Reset on success
                    self?.handleAuthSuccess(user: user, email: email)
                    
                case .failure(let error):
                    print("❌ Sign in failed: \(error.localizedDescription)")
                    self?.failedLoginAttempts += 1 // Increment failure count
                    
                    // Show user-friendly error message
                    let nsError = error as NSError
                    if nsError.code == 17011 { // User not found
                        self?.errorMessage = "No account found with this email."
                    } else if nsError.code == 17009 { // Wrong password
                        self?.errorMessage = "Incorrect password. Please try again."
                    } else {
                        self?.errorMessage = "Login failed. Please check your credentials."
                    }
                }
            }
        }
    }
    
    func sendPasswordReset(email: String) {
        self.isLoading = true
        FirebaseService.shared.resetPassword(email: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Failed to send reset email: \(error.localizedDescription)"
                } else {
                    // Success is handled by UI alert, but we can clear error
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Unified Authentication
    
    /// Unifies Login and Sign Up into a single flow.
    /// Tries to Log In first.
    /// If user not found (error 17011), it automatically attempts to Sign Up.
    func authenticate(email: String, password: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        self.isLoading = true
        self.errorMessage = nil
        self.emailCollisionDetected = false
        
        // 1. Attempt Login
        FirebaseService.shared.signIn(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    print("✅ Login Successful: \(user.uid)")
                    self?.handleAuthSuccess(user: user, email: email)
                }
                
            case .failure(let error):
                let nsError = error as NSError
                
                // 2. Check if user doesn't exist (Code 17011 = FIRAuthErrorCodeUserNotFound)
                // Note: 17004 is Invalid Credential, sometimes thrown for non-existent users, but also for bad formatting.
                // We STRICTLY want to try Sign Up only if user definitely doesn't exist.
                // 17009 is Wrong Password - definitely do NOT sign up in that case.
                if nsError.code == 17011 || (nsError.code == 17004 && !nsError.localizedDescription.contains("format")) {
                    print("ℹ️ User not found (code \(nsError.code)), attempting Sign Up...")
                    
                    // 3. Attempt Sign Up
                    FirebaseService.shared.signUp(email: email, password: password) { [weak self] signUpResult in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            
                            switch signUpResult {
                            case .success(let newUser):
                                print("✅ Created new account: \(newUser.uid)")
                                self?.handleAuthSuccess(user: newUser, email: email)
                                
                            case .failure(let signUpError):
                                print("❌ Sign Up failed: \(signUpError.localizedDescription)")
                                let signUpNsError = signUpError as NSError
                                
                                if signUpNsError.code == 17007 {
                                    // This means account exists (so login should have worked if password was right)
                                    // BUT login failed with "User Not Found" (17011) previously.
                                    // This confirms the user EXISTS but the PASSWORD was WRONG.
                                    // Firebase obfuscates this for security, but we can deduce it here.
                                    self?.errorMessage = "Incorrect Password"
                                    self?.failedLoginAttempts += 1
                                    print("⚠️ Deduced Wrong Password from collision. Failed attempts: \(self?.failedLoginAttempts ?? 0)")
                                } else if signUpNsError.code == 17026 {
                                    self?.errorMessage = "Password is too weak. Use at least 6 characters."
                                } else {
                                    self?.errorMessage = "Registration failed: \(signUpError.localizedDescription)"
                                }
                            }
                        }
                    }
                } else {
                    // 4. Other Login Errors (e.g. Wrong Password for existing user)
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        print("❌ Login Failed: \(error.localizedDescription) (Code: \(nsError.code))")
                        
                        // Check for Wrong Password (17009) or any other credential issue
                        if nsError.code == 17009 || error.localizedDescription.contains("password") {
                            self?.errorMessage = "Incorrect Password"
                            self?.failedLoginAttempts += 1
                            print("⚠️ Failed attempts: \(self?.failedLoginAttempts ?? 0)")
                        } else {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Registration (New Users Only)
    
    func signUpNewUser(email: String, password: String) {
        self.isLoading = true
        self.errorMessage = nil
        
        // Sign Up - create new user only
        FirebaseService.shared.signUp(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let newUser):
                    print("✅ Created new account: \(newUser.uid)")
                    self?.handleAuthSuccess(user: newUser, email: email)
                    
                case .failure(let error):
                    print("❌ Sign Up failed: \(error.localizedDescription)")
                    let nsError = error as NSError
                    if nsError.code == 17007 { // Email already in use
                        self?.errorMessage = "This email is already registered. Please login instead."
                        self?.emailCollisionDetected = true
                    } else if nsError.code == 17026 { // Weak password
                        self?.errorMessage = "Password is too weak. Use at least 6 characters."
                    } else {
                        self?.errorMessage = "Registration failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Social Login
    
    func startGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Root View Controller not found for Google Sign In")
            self.errorMessage = "Could not start Google Sign In"
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("❌ Google Sign In Error: \(error.localizedDescription)")
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Invalid Google User Data")
                self?.errorMessage = "Invalid Google User Data"
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            // Relay to Firebase
            self?.signInWithGoogle(idToken: idToken, accessToken: accessToken)
        }
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) {
        self.isLoading = true
        FirebaseService.shared.signInWithGoogle(idToken: idToken, accessToken: accessToken) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSocialAuthResult(result)
            }
        }
    }
    
    private func handleSocialAuthResult(_ result: Result<FirebaseAuth.User, Error>) {
        switch result {
        case .success(let user):
            print("✅ Social Login Successful: \(user.uid)")
            // Use email if available, otherwise fallback or empty
            let email = user.email ?? ""
            self.handleAuthSuccess(user: user, email: email)
            
        case .failure(let error):
            self.isLoading = false
            print("❌ Social Login Failed: \(error.localizedDescription)")
            self.errorMessage = "Social login failed: \(error.localizedDescription)"
        }
    }
    
    private func handleAuthSuccess(user: FirebaseAuth.User, email: String) {
        // Keep isLoading true to show button spinner (User Request)
        self.isLoading = true
        self.failedLoginAttempts = 0 // Reset on success
        
        // Save basics (but don't set isLoggedIn=true until data is loaded, to prevent premature transition)
        // Actually, saving isLoggedIn=true now is safe because if we crash, restoreSession fails and logs out.
        // But for UI, we keep self.isLoggedIn = false to keep WelcomeView visible.
        
        UserDefaults.standard.set(email, forKey: "userEmail")
        print("💾 Saved email to UserDefaults: \(email)")
        UserDefaults.standard.set(user.uid, forKey: "firebaseUid") // Save Auth ID for reference
        
        // Extract Google Data if available
        var googleFirstName = ""
        var googleLastName = ""
        if let displayName = user.displayName {
            let components = displayName.components(separatedBy: " ")
            if let first = components.first {
                googleFirstName = first
            }
            if components.count > 1 {
                googleLastName = components.dropFirst().joined(separator: " ")
            }
        }
        let googlePhotoUrl = user.photoURL?.absoluteString ?? ""
        
        // Check if we need to load existing profile or start fresh
        if self.currentUser == nil && !email.isEmpty {
            // Check if profile exists in Firestore by EMAIL (not Firebase UID)
            // Use the new method that finds a complete profile (with company)
            FirebaseService.shared.findCompleteUserProfile(email: email) { [weak self] result in
                DispatchQueue.main.async {
                    if let (profile, company) = result {
                        self?.currentUser = profile
                        self?.companyProfile = company
                        
                        // Save IDs to UserDefaults for session restoration
                        UserDefaults.standard.set(profile.id.uuidString, forKey: "userId")
                        UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        
                        self?.isOnboardingComplete = true
                        self?.isLoggedIn = true // Now transition to MainTabView
                        self?.isLoading = false
                    } else {
                        // No complete profile found, start onboarding with Google Data
                        print("ℹ️ No complete profile - starting onboarding for: \(email)")
                        self?.currentUser = UserProfile(
                            id: UUID(), // New random UUID for new user
                            firstName: googleFirstName,
                            lastName: googleLastName,
                            role: "",
                            email: email,
                            location: "",
                            timeZone: "",
                            profileImageUrl: googlePhotoUrl
                        )
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        self?.isLoggedIn = true // Transition to Onboarding
                        self?.isLoading = false
                    }
                }
            }
        } else if email.isEmpty {
            // No email available (shouldn't happen normally)
            print("⚠️ No email available for user")
            self.isLoading = false
        }
    }
    
    func completeOnboarding(user: UserProfile, company: CompanyProfile) {
        self.currentUser = user
        self.companyProfile = company
        self.isOnboardingComplete = true
        
        // Persist Flags & IDs
        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
        UserDefaults.standard.set(user.id.uuidString, forKey: "userId")
        UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
        
        // Save to Firestore
        FirebaseService.shared.saveUserProfile(user) { error in
            if let error = error {
                print("❌ Failed to save user to Firestore: \(error)")
            }
        }
        FirebaseService.shared.saveCompanyProfile(company, userId: user.id.uuidString) { error in
            if let error = error {
                print("❌ Failed to save company to Firestore: \(error)")
            }
        }
    }
    
    func logout() {
        self.isLoggedIn = false
        self.isOnboardingComplete = false
        self.currentUser = nil
        self.companyProfile = nil
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "isOnboardingComplete")
    }
    
    func setTheme(_ theme: String) {
        self.selectedTheme = theme
        UserDefaults.standard.set(theme, forKey: "selectedTheme")
    }
    func updateProfileImage(_ image: UIImage) {
        guard let currentUser = currentUser else { return }
        
        self.isLoading = true
        let path = "profile_images/\(currentUser.id.uuidString).jpg"
        
        FirebaseService.shared.uploadImage(image: image, path: path) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let url):
                    print("✅ Profile image updated: \(url)")
                    self?.currentUser?.profileImageUrl = url
                    // Save to Firestore
                    if let updatedUser = self?.currentUser {
                        FirebaseService.shared.saveUserProfile(updatedUser) { error in
                            if let error = error {
                                print("❌ Failed to save profile url to Firestore: \(error)")
                                self?.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                            }
                        }
                    }
                case .failure(let error):
                    print("❌ Failed to upload profile image: \(error)")
                    self?.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveProfileChanges() {
        guard let user = currentUser else { return }
        
        self.isLoading = true
        
        let dispatchGroup = DispatchGroup()
        
        // Save User
        dispatchGroup.enter()
        FirebaseService.shared.saveUserProfile(user) { [weak self] error in
            if let error = error {
                print("❌ Failed to save user profile: \(error)")
                self?.errorMessage = "Failed to save profile changes."
            }
            dispatchGroup.leave()
        }
        
        // Save Company (if exists)
        if let company = companyProfile {
            dispatchGroup.enter()
            FirebaseService.shared.saveCompanyProfile(company, userId: user.id.uuidString) { [weak self] error in
                if let error = error {
                    print("❌ Failed to save company profile: \(error)")
                    self?.errorMessage = "Failed to save company changes."
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            print("✅ Profile changes saved successfully.")
        }
    }
    
    /// Helper to check if user is using Google authentication
    var isGoogleUser: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        return user.providerData.contains { $0.providerID == "google.com" }
    }
    
    /// Delete account: removes all Firestore data and Firebase Auth account
    /// For email/password accounts, password is required for re-authentication
    /// For Google accounts, Google Sign-In re-auth is handled separately
    /// IMPORTANT: Auth is deleted FIRST - if password is wrong, nothing is deleted
    func deleteAccount(password: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let email = currentUser?.email, !email.isEmpty else {
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user email found"])))
            return
        }
        
        let userId = currentUser?.id.uuidString ?? ""
        
        self.isLoading = true
        
        // Step 1: Delete Firebase Auth account FIRST (requires correct password)
        // If this fails, nothing else is deleted - safe rollback
        FirebaseService.shared.deleteAuthAccount(password: password) { [weak self] authError in
            if let error = authError {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    completion(.failure(error))
                }
                return
            }
            
            // Step 2: Auth deleted successfully, now delete Firestore data
            FirebaseService.shared.deleteUserData(email: email, userId: userId) { dataError in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = dataError {
                        // Auth is already deleted, just log the Firestore error
                        print("⚠️ Auth deleted but Firestore cleanup failed: \(error.localizedDescription)")
                        // Don't fail the whole operation since Auth is gone
                    }
                    
                    // Step 3: Clear all local state
                    self?.clearAllLocalData()
                    
                    print("✅ Account fully deleted")
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Clears all local app data (UserDefaults, state)
    private func clearAllLocalData() {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Reset state
        self.currentUser = nil
        self.companyProfile = nil
        self.isLoggedIn = false
        self.isOnboardingComplete = false
        self.failedLoginAttempts = 0
        self.selectedTheme = "Dark"
        self.errorMessage = nil
    }
}
