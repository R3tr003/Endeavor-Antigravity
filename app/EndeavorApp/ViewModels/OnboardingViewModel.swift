import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    // Data being collected
    @Published var user = UserProfile()
    @Published var company = CompanyProfile()
    @Published var selectedProfileImage: UIImage? = nil
    
    // Navigation State
    @Published var currentStep: Int = 1
    @Published var totalSteps: Int = 5 // Reduced from 6
    @Published var isSocialLogin: Bool = false // Tracks if user came from Google/Apple
    
    // Consent - IMPLICIT on Login now
    // Removed explicit properties
    
    // Validation
    init() {
        // Load persisted email if available
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            self.user.email = email
        }
    }

    var isStep1Valid: Bool {
        isSocialLogin ? (!user.role.isEmpty) : (!user.firstName.isEmpty && !user.lastName.isEmpty && !user.role.isEmpty)
    }
    
    var isStep2Valid: Bool {
        // Combined validation for Company Basics (old steps 2 & 3)
        !company.name.isEmpty && !company.website.isEmpty && !company.hqCountry.isEmpty && !company.hqCity.isEmpty && !company.industries.isEmpty && !company.stage.isEmpty && !company.employeeRange.isEmpty
    }
    
    var isStep3Valid: Bool {
        // Old Step 4 (Focus)
        !company.challenges.isEmpty && !company.desiredExpertise.isEmpty
    }
    
    var isStep4Valid: Bool {
        // Bio step - About You (personal) and About the Company (long description)
        !user.personalBio.isEmpty && !company.companyBio.isEmpty
    }
    
    var isStep5Valid: Bool {
        // Old Step 7 (Review) - Now Step 5
        true
    }
    
    // Actions
    func nextStep() {
        if currentStep < totalSteps {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
    
    // Options for dropdowns/pills
    let availableIndustries = ["FinTech", "SaaS", "E-commerce", "HealthTech", "VC", "Mobile", "AI/ML", "Marketplace"]
    let availableStages = ["Idea", "Seed", "Series A", "Series B", "Growth", "Public"]
    let availableEmployeeRanges = ["1-10", "11-50", "51-200", "201-500", "500+"]
    let availableChallenges = ["Hiring", "Fundraising", "Go-to-market", "Ops", "Product", "Intl Expansion"]
    let availableExpertise = ["Scaling", "Product", "Marketing", "Investment", "Strategy", "Operations", "Sales", "Legal"]
    
    var availableCountries: [String] { LocationData.shared.availableCountries }
    
    func citiesForCountry(_ country: String) -> [String] {
        return LocationData.shared.citiesForCountry(country)
    }
    
    func toggleIndustry(_ industry: String) {
        if company.industries.contains(industry) {
            company.industries.removeAll { $0 == industry }
        } else {
            if company.industries.count < 3 {
                company.industries.append(industry)
            }
        }
    }
    
    func toggleChallenge(_ challenge: String) {
        if company.challenges.contains(challenge) {
            company.challenges.removeAll { $0 == challenge }
        } else {
            if company.challenges.count < 3 {
                company.challenges.append(challenge)
            }
        }
    }
    
    func toggleExpertise(_ expertise: String) {
        if company.desiredExpertise.contains(expertise) {
            company.desiredExpertise.removeAll { $0 == expertise }
        } else {
            company.desiredExpertise.append(expertise)
        }
    }
    
    // MARK: - Draft Persistence (App Lifecycle)
    
    private static let draftKey = "onboarding_draft"
    
    /// Saves the current onboarding state to UserDefaults so it survives app backgrounding
    func saveDraft() {
        let draft: [String: Any] = [
            "currentStep": currentStep,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "role": user.role,
            "email": user.email,
            "timeZone": user.timeZone,
            "personalBio": user.personalBio,
            "companyName": company.name,
            "companyWebsite": company.website,
            "hqCountry": company.hqCountry,
            "hqCity": company.hqCity,
            "industries": company.industries,
            "stage": company.stage,
            "employeeRange": company.employeeRange,
            "companyBio": company.companyBio,
            "challenges": company.challenges,
            "desiredExpertise": company.desiredExpertise,
            "isSocialLogin": isSocialLogin
        ]
        UserDefaults.standard.set(draft, forKey: Self.draftKey)
        print("📝 Onboarding draft saved at step \(currentStep)")
    }
    
    /// Restores onboarding state from a previously saved draft
    func loadDraft() {
        guard let draft = UserDefaults.standard.dictionary(forKey: Self.draftKey) else { return }
        
        currentStep = draft["currentStep"] as? Int ?? 1
        user.firstName = draft["firstName"] as? String ?? ""
        user.lastName = draft["lastName"] as? String ?? ""
        user.role = draft["role"] as? String ?? ""
        user.email = draft["email"] as? String ?? ""
        user.timeZone = draft["timeZone"] as? String ?? ""
        user.personalBio = draft["personalBio"] as? String ?? ""
        company.name = draft["companyName"] as? String ?? ""
        company.website = draft["companyWebsite"] as? String ?? ""
        company.hqCountry = draft["hqCountry"] as? String ?? ""
        company.hqCity = draft["hqCity"] as? String ?? ""
        company.industries = draft["industries"] as? [String] ?? []
        company.stage = draft["stage"] as? String ?? ""
        company.employeeRange = draft["employeeRange"] as? String ?? ""
        company.companyBio = draft["companyBio"] as? String ?? ""
        company.challenges = draft["challenges"] as? [String] ?? []
        company.desiredExpertise = draft["desiredExpertise"] as? [String] ?? []
        isSocialLogin = draft["isSocialLogin"] as? Bool ?? false
        
        print("📋 Onboarding draft restored at step \(currentStep)")
    }
    
    /// Clears the saved draft (call after successful onboarding completion)
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
        print("🗑️ Onboarding draft cleared")
    }
    
    /// Whether a saved draft exists
    static var hasDraft: Bool {
        UserDefaults.standard.dictionary(forKey: draftKey) != nil
    }
}
