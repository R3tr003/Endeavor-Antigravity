import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    // Data being collected
    @Published var user = UserProfile()
    @Published var company = CompanyProfile()
    
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
        !user.firstName.isEmpty && !user.lastName.isEmpty && !user.role.isEmpty
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
        // Old Step 5 (Bio)
        !company.shortDescription.isEmpty && !company.longDescription.isEmpty
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
    
    // Countries (Top 5 prioritized, then alphabetical order)
    let availableCountries = [
        // Top 5 Priority
        "Spain", "Italy", "Germany", "France", "United Kingdom",
        // Rest alphabetically
        "Argentina", "Australia", "Austria", "Bahrain", "Belgium", "Brazil",
        "Canada", "Chile", "China", "Colombia", "Czech Republic", "Denmark",
        "Egypt", "Finland", "Greece", "Hong Kong", "Hungary", "India",
        "Indonesia", "Ireland", "Israel", "Japan", "Jordan", "Kuwait",
        "Lebanon", "Malaysia", "Mexico", "Morocco", "Netherlands", "New Zealand",
        "Norway", "Oman", "Peru", "Philippines", "Poland", "Portugal",
        "Qatar", "Romania", "Saudi Arabia", "Singapore", "South Korea", "Sweden",
        "Switzerland", "Taiwan", "Thailand", "Tunisia", "Turkey",
        "United Arab Emirates", "United States", "Vietnam"
    ]
    
    // Cities by country (5-15 major cities each)
    let citiesByCountry: [String: [String]] = [
        // Europe - Priority
        "Italy": ["Milan", "Rome", "Turin", "Florence", "Naples", "Bologna", "Venice", "Genoa", "Verona", "Palermo"],
        "Spain": ["Madrid", "Barcelona", "Valencia", "Seville", "Bilbao", "Malaga", "Zaragoza", "Murcia", "Palma"],
        "Germany": ["Berlin", "Munich", "Frankfurt", "Hamburg", "Cologne", "Düsseldorf", "Stuttgart", "Leipzig", "Dresden", "Nuremberg"],
        "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Bordeaux", "Lille", "Montpellier"],
        "United Kingdom": ["London", "Manchester", "Birmingham", "Edinburgh", "Glasgow", "Bristol", "Leeds", "Liverpool", "Cambridge", "Oxford"],
        // Europe - Other
        "Netherlands": ["Amsterdam", "Rotterdam", "The Hague", "Utrecht", "Eindhoven"],
        "Belgium": ["Brussels", "Antwerp", "Ghent", "Bruges", "Leuven"],
        "Switzerland": ["Zurich", "Geneva", "Basel", "Bern", "Lausanne"],
        "Austria": ["Vienna", "Salzburg", "Innsbruck", "Graz", "Linz"],
        "Portugal": ["Lisbon", "Porto", "Braga", "Coimbra", "Faro"],
        "Poland": ["Warsaw", "Krakow", "Wroclaw", "Gdansk", "Poznan"],
        "Sweden": ["Stockholm", "Gothenburg", "Malmö", "Uppsala", "Lund"],
        "Norway": ["Oslo", "Bergen", "Trondheim", "Stavanger"],
        "Denmark": ["Copenhagen", "Aarhus", "Odense", "Aalborg"],
        "Finland": ["Helsinki", "Espoo", "Tampere", "Turku", "Oulu"],
        "Ireland": ["Dublin", "Cork", "Galway", "Limerick"],
        "Greece": ["Athens", "Thessaloniki", "Patras", "Heraklion"],
        "Czech Republic": ["Prague", "Brno", "Ostrava", "Pilsen"],
        "Romania": ["Bucharest", "Cluj-Napoca", "Timisoara", "Iasi"],
        "Hungary": ["Budapest", "Debrecen", "Szeged", "Miskolc", "Pécs"],
        // Americas
        "United States": ["New York", "San Francisco", "Los Angeles", "Chicago", "Boston", "Seattle", "Austin", "Miami", "Denver", "Atlanta", "Washington D.C.", "Philadelphia", "San Diego", "Dallas", "Houston"],
        "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa", "Edmonton"],
        "Mexico": ["Mexico City", "Guadalajara", "Monterrey", "Puebla", "Tijuana", "Cancún"],
        "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília", "Belo Horizonte", "Porto Alegre", "Curitiba", "Salvador", "Recife", "Florianópolis"],
        "Argentina": ["Buenos Aires", "Córdoba", "Rosario", "Mendoza", "Mar del Plata"],
        "Chile": ["Santiago", "Valparaíso", "Concepción", "Viña del Mar"],
        "Colombia": ["Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena"],
        "Peru": ["Lima", "Arequipa", "Cusco", "Trujillo"],
        // Asia
        "Japan": ["Tokyo", "Osaka", "Kyoto", "Yokohama", "Nagoya", "Fukuoka", "Sapporo", "Kobe"],
        "South Korea": ["Seoul", "Busan", "Incheon", "Daegu", "Daejeon"],
        "China": ["Shanghai", "Beijing", "Shenzhen", "Guangzhou", "Hangzhou", "Chengdu", "Nanjing", "Wuhan", "Xi'an", "Suzhou"],
        "India": ["Mumbai", "Bangalore", "Delhi", "Hyderabad", "Chennai", "Pune", "Kolkata", "Ahmedabad", "Gurgaon", "Noida"],
        "Singapore": ["Singapore"],
        "Hong Kong": ["Hong Kong"],
        "Taiwan": ["Taipei", "Kaohsiung", "Taichung", "Tainan", "Hsinchu"],
        "Indonesia": ["Jakarta", "Surabaya", "Bandung", "Bali", "Medan"],
        "Thailand": ["Bangkok", "Chiang Mai", "Phuket", "Pattaya"],
        "Vietnam": ["Ho Chi Minh City", "Hanoi", "Da Nang", "Hai Phong"],
        "Malaysia": ["Kuala Lumpur", "Penang", "Johor Bahru", "Melaka"],
        "Philippines": ["Manila", "Cebu", "Davao", "Quezon City"],
        "United Arab Emirates": ["Dubai", "Abu Dhabi", "Sharjah"],
        "Israel": ["Tel Aviv", "Jerusalem", "Haifa", "Herzliya"],
        "Saudi Arabia": ["Riyadh", "Jeddah", "Dammam", "Mecca", "Medina"],
        // Middle East - Additional
        "Bahrain": ["Manama", "Riffa", "Muharraq"],
        "Egypt": ["Cairo", "Alexandria", "Giza", "Sharm El Sheikh", "Luxor"],
        "Jordan": ["Amman", "Aqaba", "Irbid", "Zarqa"],
        "Kuwait": ["Kuwait City", "Hawalli", "Salmiya"],
        "Lebanon": ["Beirut", "Tripoli", "Sidon", "Byblos"],
        "Morocco": ["Casablanca", "Marrakech", "Rabat", "Fez", "Tangier"],
        "Oman": ["Muscat", "Salalah", "Sohar", "Nizwa"],
        "Qatar": ["Doha", "Al Wakrah", "Al Khor"],
        "Tunisia": ["Tunis", "Sfax", "Sousse", "Kairouan"],
        "Turkey": ["Istanbul", "Ankara", "Izmir", "Antalya", "Bursa", "Adana"],
        // Oceania
        "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide", "Canberra", "Gold Coast"],
        "New Zealand": ["Auckland", "Wellington", "Christchurch", "Hamilton", "Queenstown"]
    ]
    
    func citiesForCountry(_ country: String) -> [String] {
        return citiesByCountry[country] ?? []
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
}
