import SwiftUI
import Combine

class AppViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var companyProfile: CompanyProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var selectedTheme: String = "Dark"
    
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
        
        // Check auth and onboarding state
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
        
        if isLoggedIn && isOnboardingComplete {
            // Load dummy data for "Alex" if already onboarding
            self.currentUser = UserProfile(firstName: "Alex", lastName: "Chen", role: "Founder", location: "New York, USA")
            self.companyProfile = CompanyProfile(name: "Endeavor", industries: ["FinTech", "SaaS"])
        }
    }
    
    func login(email: String) {
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "userEmail") // Persist email
        
        // Initialize incomplete user profile with email for onboarding
        if self.currentUser == nil {
            self.currentUser = UserProfile(firstName: "", lastName: "", role: "", email: email, location: "")
        }
    }
    
    func completeOnboarding(user: UserProfile, company: CompanyProfile) {
        self.currentUser = user
        self.companyProfile = company
        self.isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
        
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
}
