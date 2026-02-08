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
        // IMPORTANT: Set isCheckingAuth FIRST to prevent onboarding from flashing
        self.isCheckingAuth = true
        self.isLoading = false
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "userEmail")
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
                        print("✅ Found complete profile for email: \(email)")
                        self?.currentUser = profile
                        self?.companyProfile = company
                        
                        // Save IDs to UserDefaults for session restoration
                        UserDefaults.standard.set(profile.id.uuidString, forKey: "userId")
                        UserDefaults.standard.set(company.id.uuidString, forKey: "companyId")
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                        
                        self?.isOnboardingComplete = true
                        self?.isLoading = false
                        self?.isCheckingAuth = false
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
                        self?.isLoading = false
                        self?.isCheckingAuth = false
                    }
                }
            }
        } else if email.isEmpty {
            // No email available (shouldn't happen normally)
            print("⚠️ No email available for user")
            self.isLoading = false
            self.isCheckingAuth = false
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
}
