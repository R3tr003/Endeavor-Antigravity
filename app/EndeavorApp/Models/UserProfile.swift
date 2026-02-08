import Foundation

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var firstName: String = ""
    var lastName: String = ""
    var role: String = ""
    var email: String = "alex@endeavor.org" // Default per spec
    var location: String = ""

    var timeZone: String = ""
    var profileImageUrl: String = "" // Added for Google Sign In
    
    // Formatting helper
    var fullName: String {
        "\(firstName) \(lastName)"
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
    var shortDescription: String = "" // Max 300 chars
    var longDescription: String = "" // Max 1000 chars
    // Logo would typically be a URL or Data, simulating with placeholder logic in UI
}
