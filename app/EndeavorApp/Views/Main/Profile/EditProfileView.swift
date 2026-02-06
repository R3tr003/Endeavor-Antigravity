import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Personal info
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var role: String = ""
    
    // Company info
    @State private var companyName: String = ""
    @State private var website: String = ""
    @State private var hqCountry: String = ""
    @State private var hqCity: String = ""
    
    // Focus info
    @State private var challenges: [String] = []
    @State private var desiredExpertise: [String] = []
    
    @State private var selectedTab: String = "Personal"
    
    // Available options for Focus
    let availableChallenges = ["Hiring", "Fundraising", "Go-to-market", "Ops", "Product", "Intl Expansion"]
    let availableExpertise = ["Scaling", "Product", "Marketing", "Investment", "Strategy", "Operations", "Sales", "Legal"]
    
    // Country/City data
    let availableCountries = [
        "Spain", "Italy", "Germany", "France", "United Kingdom",
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
    
    let citiesByCountry: [String: [String]] = [
        "Italy": ["Milan", "Rome", "Turin", "Florence", "Naples", "Bologna", "Venice", "Genoa", "Verona", "Palermo"],
        "Spain": ["Madrid", "Barcelona", "Valencia", "Seville", "Bilbao", "Malaga", "Zaragoza", "Murcia", "Palma"],
        "Germany": ["Berlin", "Munich", "Frankfurt", "Hamburg", "Cologne", "Düsseldorf", "Stuttgart", "Leipzig", "Dresden", "Nuremberg"],
        "France": ["Paris", "Lyon", "Marseille", "Toulouse", "Nice", "Nantes", "Strasbourg", "Bordeaux", "Lille", "Montpellier"],
        "United Kingdom": ["London", "Manchester", "Birmingham", "Edinburgh", "Glasgow", "Bristol", "Leeds", "Liverpool", "Cambridge", "Oxford"],
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
        "United States": ["New York", "San Francisco", "Los Angeles", "Chicago", "Boston", "Seattle", "Austin", "Miami", "Denver", "Atlanta", "Washington D.C.", "Philadelphia", "San Diego", "Dallas", "Houston"],
        "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa", "Edmonton"],
        "Mexico": ["Mexico City", "Guadalajara", "Monterrey", "Puebla", "Tijuana", "Cancún"],
        "Brazil": ["São Paulo", "Rio de Janeiro", "Brasília", "Belo Horizonte", "Porto Alegre", "Curitiba", "Salvador", "Recife", "Florianópolis"],
        "Argentina": ["Buenos Aires", "Córdoba", "Rosario", "Mendoza", "Mar del Plata"],
        "Chile": ["Santiago", "Valparaíso", "Concepción", "Viña del Mar"],
        "Colombia": ["Bogotá", "Medellín", "Cali", "Barranquilla", "Cartagena"],
        "Peru": ["Lima", "Arequipa", "Cusco", "Trujillo"],
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
        "Australia": ["Sydney", "Melbourne", "Brisbane", "Perth", "Adelaide", "Canberra", "Gold Coast"],
        "New Zealand": ["Auckland", "Wellington", "Christchurch", "Hamilton", "Queenstown"]
    ]
    
    func citiesForCountry(_ country: String) -> [String] {
        return citiesByCountry[country] ?? []
    }
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.branding.cardTitle)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button(action: saveChanges) {
                        Text("Save")
                            .font(.branding.body.weight(.bold))
                            .foregroundColor(.brandPrimary)
                    }
                }
                .padding(24)
                
                // Tabs
                HStack(spacing: 0) {
                    editTab(title: "Personal")
                    editTab(title: "Company")
                    editTab(title: "Focus")
                }
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Color.textSecondary.opacity(0.3)),
                    alignment: .bottom
                )
                
                ScrollView {
                    VStack {
                        if selectedTab == "Personal" {
                            personalEditContent
                        } else if selectedTab == "Company" {
                            companyEditContent
                        } else {
                            focusEditContent
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Load current values
            if let user = appViewModel.currentUser {
                firstName = user.firstName
                lastName = user.lastName
                role = user.role
            }
            if let company = appViewModel.companyProfile {
                companyName = company.name
                website = company.website
                hqCountry = company.hqCountry
                hqCity = company.hqCity
                challenges = company.challenges
                desiredExpertise = company.desiredExpertise
            }
        }
    }
    
    func editTab(title: String) -> some View {
        Button(action: { selectedTab = title }) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.branding.body.weight(selectedTab == title ? .bold : .regular))
                    .foregroundColor(selectedTab == title ? .brandPrimary : .textSecondary)
                
                Rectangle()
                    .fill(selectedTab == title ? Color.brandPrimary : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.background)
    }
    
    var personalEditContent: some View {
        VStack(spacing: 16) {
            CustomTextField(title: "First Name", placeholder: "", text: $firstName, isRequired: true)
            CustomTextField(title: "Last Name", placeholder: "", text: $lastName, isRequired: true)
            CustomTextField(title: "Role/Title", placeholder: "", text: $role, isRequired: true)
            
            // Read only email
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Email")
                    .font(.branding.inputLabel)
                    .foregroundColor(.textSecondary)
                Text(appViewModel.currentUser?.email ?? "alex@endeavor.org")
                    .font(.branding.body)
                    .foregroundColor(.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.inputBackground.opacity(0.5))
                    .cornerRadius(12)
            }
        }
    }
    
    var companyEditContent: some View {
        VStack(spacing: 16) {
            CustomTextField(title: "Company Name", placeholder: "", text: $companyName, isRequired: true)
            CustomTextField(title: "Website", placeholder: "", text: $website, isRequired: true)
            
            // HQ Country Dropdown
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("HQ Country")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                    Text("*")
                        .font(.branding.inputLabel)
                        .foregroundColor(.error)
                }
                
                Menu {
                    ForEach(availableCountries, id: \.self) { country in
                        Button(country) {
                            hqCountry = country
                            hqCity = "" // Reset city when country changes
                        }
                    }
                } label: {
                    HStack {
                        Text(hqCountry.isEmpty ? "Select a country" : hqCountry)
                            .foregroundColor(hqCountry.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(16)
                    .background(Color.inputBackground)
                    .cornerRadius(12)
                }
                .transaction { $0.animation = nil }
            }
            
            // HQ City Dropdown
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("HQ City")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                    Text("*")
                        .font(.branding.inputLabel)
                        .foregroundColor(.error)
                }
                
                Menu {
                    if hqCountry.isEmpty {
                        Button("Select a country first", action: {})
                    } else {
                        ForEach(citiesForCountry(hqCountry), id: \.self) { city in
                            Button(city) {
                                hqCity = city
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(hqCity.isEmpty ? "Select a city" : hqCity)
                            .foregroundColor(hqCity.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(16)
                    .background(Color.inputBackground)
                    .cornerRadius(12)
                }
                .transaction { $0.animation = nil }
                .disabled(hqCountry.isEmpty)
            }
        }
    }
    
    var focusEditContent: some View {
        VStack(spacing: 24) {
            // Challenges
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Text("Your Top 3 Challenges")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                    Text("*")
                        .font(.branding.inputLabel)
                        .foregroundColor(.error)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(availableChallenges, id: \.self) { challenge in
                        SelectablePill(
                            title: challenge,
                            isSelected: challenges.contains(challenge),
                            action: { toggleChallenge(challenge) }
                        )
                    }
                }
            }
            
            // Desired Expertise
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Text("Desired Mentor Expertise")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                    Text("*")
                        .font(.branding.inputLabel)
                        .foregroundColor(.error)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(availableExpertise, id: \.self) { expertise in
                        SelectablePill(
                            title: expertise,
                            isSelected: desiredExpertise.contains(expertise),
                            action: { toggleExpertise(expertise) }
                        )
                    }
                }
            }
        }
    }
    
    func toggleChallenge(_ challenge: String) {
        if challenges.contains(challenge) {
            challenges.removeAll { $0 == challenge }
        } else if challenges.count < 3 {
            challenges.append(challenge)
        }
    }
    
    func toggleExpertise(_ expertise: String) {
        if desiredExpertise.contains(expertise) {
            desiredExpertise.removeAll { $0 == expertise }
        } else {
            desiredExpertise.append(expertise)
        }
    }
    
    func saveChanges() {
        // Save personal info
        appViewModel.currentUser?.firstName = firstName
        appViewModel.currentUser?.lastName = lastName
        appViewModel.currentUser?.role = role
        
        // Save company info
        appViewModel.companyProfile?.name = companyName
        appViewModel.companyProfile?.website = website
        appViewModel.companyProfile?.hqCountry = hqCountry
        appViewModel.companyProfile?.hqCity = hqCity
        appViewModel.companyProfile?.challenges = challenges
        appViewModel.companyProfile?.desiredExpertise = desiredExpertise
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AppViewModel())
    }
}
