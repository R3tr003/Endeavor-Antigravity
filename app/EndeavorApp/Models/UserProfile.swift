import Foundation

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var role: String = ""
    var email: String = "" // Removed hardcoded default
    var location: String = ""

    var timeZone: String = ""
    var profileImageUrl: String = "" // Added for Google Sign In
    var personalBio: String = "" // "About You" from onboarding
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

struct CompanyProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var website: String = ""
    var hqCountry: String = ""
    var hqCity: String = ""
    var industries: [String] = []
    var stage: String = ""
    var employeeRange: String = ""
    
    // Focus
    var challenges: [String] = [] // Max 3
    var desiredExpertise: [String] = []
    
    // Bio & Logo
    var companyBio: String = "" // Max 1000 chars
    // Logo would typically be a URL or Data, simulating with placeholder logic in UI
}
