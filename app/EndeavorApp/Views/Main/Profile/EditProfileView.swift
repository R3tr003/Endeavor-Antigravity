import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Personal info
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var role: String = ""
    @State private var personalBio: String = "" // About You
    
    // Company info
    @State private var companyName: String = ""
    @State private var website: String = ""
    @State private var hqCountry: String = ""
    @State private var hqCity: String = ""
    @State private var companyBio: String = "" // About Company
    
    // Focus info
    @State private var challenges: [String] = []
    @State private var desiredExpertise: [String] = []
    
    @State private var selectedTab: String = "Personal"
    
    // Alert state
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Background animation
    @State private var animateGlow = false
    
    // Email change state
    @State private var showEmailChange = false
    @State private var newEmail = ""
    @State private var emailChangePassword = ""
    @State private var showEmailChangeSuccess = false
    @State private var showEmailChangeError = false
    @State private var emailChangeErrorMessage = ""
    @FocusState private var newEmailFocused: Bool
    @FocusState private var passwordFocused: Bool
    
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
            // Immersive background
            Color.background.edgesIgnoringSafeArea(.all)
            
            // Ambient glow
            Circle()
                .fill(Color.brandPrimary.opacity(0.12))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(y: animateGlow ? -280 : -250)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Floating Glass Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: saveChanges) {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)
                
                // MARK: - Glass Pill Tabs
                HStack(spacing: 12) {
                    ForEach(["Personal", "Company", "Focus"], id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab)
                                .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : .primary)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(
                                    ZStack {
                                        if selectedTab == tab {
                                            Capsule().fill(Color.brandPrimary)
                                        } else {
                                            Capsule().fill(.ultraThinMaterial)
                                        }
                                    }
                                )
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // MARK: - Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if selectedTab == "Personal" {
                            personalEditContent
                        } else if selectedTab == "Company" {
                            companyEditContent
                        } else {
                            focusEditContent
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
        }
        .onAppear {
            // Load current values
            if let user = appViewModel.currentUser {
                firstName = user.firstName
                lastName = user.lastName
                role = user.role
                personalBio = user.personalBio
            }
            if let company = appViewModel.companyProfile {
                companyName = company.name
                website = company.website
                hqCountry = company.hqCountry
                hqCity = company.hqCity
                companyBio = company.companyBio
                challenges = company.challenges
                desiredExpertise = company.desiredExpertise
            }
            
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGlow.toggle()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Missing Information"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Verification Email Sent", isPresented: $showEmailChangeSuccess) {
            Button("OK", role: .cancel) {
                withAnimation {
                    showEmailChange = false
                    newEmail = ""
                    emailChangePassword = ""
                }
            }
        } message: {
            Text("A verification link has been sent to your new email. Please check your inbox and click the link to complete the change.")
        }
        .alert("Email Change Failed", isPresented: $showEmailChangeError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(emailChangeErrorMessage)
        }
    }
    
    // MARK: - Glass Input Helper
    func glassTextField(title: String, placeholder: String, text: Binding<String>, isRequired: Bool = false) -> some View {
        GlassTextFieldView(title: title, placeholder: placeholder, text: text, isRequired: isRequired)
    }
    
    func glassTextEditor(title: String, placeholder: String, text: Binding<String>, charLimit: Int, isRequired: Bool = false) -> some View {
        GlassTextEditorView(title: title, placeholder: placeholder, text: text, charLimit: charLimit, isRequired: isRequired)
    }
    
    func glassDropdown(title: String, selection: String, placeholder: String, isRequired: Bool = false, @ViewBuilder menuContent: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                if isRequired {
                    Text("*")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            Menu {
                menuContent()
            } label: {
                HStack {
                    Text(selection.isEmpty ? placeholder : selection)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(selection.isEmpty ? .secondary.opacity(0.5) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .transaction { $0.animation = nil }
        }
    }
    
    // MARK: - Sections wrapped in glass card
    func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundColor(.primary.opacity(0.7))
                .kerning(1)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                content()
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Personal Tab
    var personalEditContent: some View {
        VStack(spacing: 24) {
            glassSection(title: "Identity") {
                glassTextField(title: "First Name", placeholder: "Enter your first name", text: $firstName, isRequired: true)
                glassTextField(title: "Last Name", placeholder: "Enter your last name", text: $lastName, isRequired: true)
                glassTextField(title: "Role/Title", placeholder: "e.g. CEO, CTO", text: $role, isRequired: true)
            }
            
            glassSection(title: "About You") {
                glassTextEditor(title: "Bio", placeholder: "Tell us a bit about yourself...", text: $personalBio, charLimit: 300, isRequired: true)
            }
            
            glassSection(title: "Contact") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Work Email")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(appViewModel.currentUser?.email ?? "No Email")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showEmailChange.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Do you want to change the email?")
                                .foregroundColor(.brandPrimary)
                            Image(systemName: showEmailChange ? "chevron.up" : "chevron.down")
                                .foregroundColor(.brandPrimary)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 13, design: .rounded))
                    }
                    
                    if showEmailChange {
                        VStack(spacing: 16) {
                            // New Email field with focus glow
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                    Text("New Email")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary.opacity(0.8))
                                    Text("*")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                                
                                TextField("Enter your new email", text: $newEmail)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(.primary)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .focused($newEmailFocused)
                                    .padding(16)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                newEmailFocused ? Color.brandPrimary :
                                                Color.white.opacity(0.15),
                                                lineWidth: newEmailFocused ? 1.5 : 1
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: newEmailFocused)
                            }
                            
                            if !appViewModel.isGoogleUser {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Password")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary.opacity(0.8))
                                    
                                    SecureField("Enter your current password", text: $emailChangePassword)
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(.primary)
                                        .focused($passwordFocused)
                                        .disabled(!isNewEmailValid)
                                        .padding(16)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    passwordFocused ? Color.brandPrimary :
                                                    Color.white.opacity(isNewEmailValid ? 0.15 : 0.05),
                                                    lineWidth: passwordFocused ? 1.5 : 1
                                                )
                                        )
                                        .opacity(isNewEmailValid ? 1.0 : 0.4)
                                        .animation(.easeInOut(duration: 0.25), value: isNewEmailValid)
                                        .animation(.easeInOut(duration: 0.2), value: passwordFocused)
                                }
                            }
                            
                            Text("A verification link will be sent to the new email. Your email will only be updated after you verify it.")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Button(action: sendEmailChange) {
                                HStack {
                                    if appViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    Text("Send Verification Email")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isEmailChangeValid ? Color.brandPrimary : Color.primary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!isEmailChangeValid || appViewModel.isLoading)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    // MARK: - Company Tab
    var companyEditContent: some View {
        VStack(spacing: 24) {
            glassSection(title: "Company Info") {
                glassTextField(title: "Company Name", placeholder: "Enter company name", text: $companyName, isRequired: true)
                glassTextField(title: "Website", placeholder: "https://example.com", text: $website, isRequired: true)
            }
            
            glassSection(title: "Headquarters") {
                glassDropdown(title: "HQ Country", selection: hqCountry, placeholder: "Select a country", isRequired: true) {
                    ForEach(availableCountries, id: \.self) { country in
                        Button(country) {
                            hqCountry = country
                            hqCity = ""
                        }
                    }
                }
                
                glassDropdown(title: "HQ City", selection: hqCity, placeholder: hqCountry.isEmpty ? "Select a country first" : "Select a city", isRequired: true) {
                    if hqCountry.isEmpty {
                        Button("Select a country first", action: {})
                    } else {
                        ForEach(citiesForCountry(hqCountry), id: \.self) { city in
                            Button(city) {
                                hqCity = city
                            }
                        }
                    }
                }
                .disabled(hqCountry.isEmpty)
            }
            
            glassSection(title: "About Company") {
                glassTextEditor(title: "Company Bio", placeholder: "Describe your company mission and goals...", text: $companyBio, charLimit: 1000, isRequired: true)
            }
        }
    }
    
    // MARK: - Focus Tab
    var focusEditContent: some View {
        VStack(spacing: 24) {
            glassSection(title: "Your Top 3 Challenges") {
                FlowLayout(spacing: 8) {
                    ForEach(availableChallenges, id: \.self) { challenge in
                        Button(action: { toggleChallenge(challenge) }) {
                            Text(challenge)
                                .font(.system(size: 14, weight: challenges.contains(challenge) ? .bold : .medium, design: .rounded))
                                .foregroundColor(challenges.contains(challenge) ? .white : .primary)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    challenges.contains(challenge)
                                    ? AnyShapeStyle(Color.brandPrimary)
                                    : AnyShapeStyle(.ultraThinMaterial),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(
                                        challenges.contains(challenge) ? Color.brandPrimary.opacity(0.5) : Color.white.opacity(0.15),
                                        lineWidth: 1
                                    )
                                )
                        }
                    }
                }
            }
            
            glassSection(title: "Desired Mentor Expertise") {
                FlowLayout(spacing: 8) {
                    ForEach(availableExpertise, id: \.self) { expertise in
                        Button(action: { toggleExpertise(expertise) }) {
                            Text(expertise)
                                .font(.system(size: 14, weight: desiredExpertise.contains(expertise) ? .bold : .medium, design: .rounded))
                                .foregroundColor(desiredExpertise.contains(expertise) ? .white : .primary)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    desiredExpertise.contains(expertise)
                                    ? AnyShapeStyle(Color.brandPrimary)
                                    : AnyShapeStyle(.ultraThinMaterial),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(
                                        desiredExpertise.contains(expertise) ? Color.brandPrimary.opacity(0.5) : Color.white.opacity(0.15),
                                        lineWidth: 1
                                    )
                                )
                        }
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
        // Validation
        let personalBioClean = personalBio.trimmingCharacters(in: .whitespacesAndNewlines)
        let companyBioClean = companyBio.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if personalBioClean.isEmpty {
            alertMessage = "Please enter 'About You' information."
            showingAlert = true
            return
        }
        
        if companyBioClean.isEmpty {
             alertMessage = "Please enter 'About Company' information."
             showingAlert = true
             return
        }
        
        // Save personal info
        appViewModel.currentUser?.firstName = firstName
        appViewModel.currentUser?.lastName = lastName
        appViewModel.currentUser?.role = role
        appViewModel.currentUser?.personalBio = personalBio
        
        // Save company info
        appViewModel.companyProfile?.name = companyName
        appViewModel.companyProfile?.website = website
        appViewModel.companyProfile?.hqCountry = hqCountry
        appViewModel.companyProfile?.hqCity = hqCity
        appViewModel.companyProfile?.companyBio = companyBio
        appViewModel.companyProfile?.challenges = challenges
        appViewModel.companyProfile?.desiredExpertise = desiredExpertise
        
        // Persist to Firestore
        appViewModel.saveProfileChanges()
        
        presentationMode.wrappedValue.dismiss()
    }
    
    var isEmailChangeValid: Bool {
        let hasPassword = appViewModel.isGoogleUser || !emailChangePassword.isEmpty
        return isNewEmailValid && hasPassword
    }
    
    var isNewEmailValid: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: newEmail)
    }
    
    func sendEmailChange() {
        let password = appViewModel.isGoogleUser ? nil : emailChangePassword
        appViewModel.changeEmail(newEmail: newEmail.lowercased(), password: password) { result in
            switch result {
            case .success:
                showEmailChangeSuccess = true
            case .failure(let error):
                let nsError = error as NSError
                let desc = error.localizedDescription
                // Firebase error code 17007 = email already in use
                if nsError.code == 17007 || desc.contains("email-already-in-use") || desc.contains("EMAIL_ALREADY_IN_USE") || desc.contains("already in use") {
                    emailChangeErrorMessage = "This email is already associated with another account. Please enter a different email."
                } else if nsError.code == 17004 || nsError.code == 17009 || desc.contains("INVALID_LOGIN_CREDENTIALS") || desc.contains("credential") || desc.contains("wrong-password") {
                    emailChangeErrorMessage = "Incorrect password. Please try again."
                } else if desc.contains("email") || nsError.code == 17008 {
                    emailChangeErrorMessage = "Invalid email address. Please check and try again."
                } else {
                    emailChangeErrorMessage = desc
                }
                showEmailChangeError = true
            }
        }
    }
}

// MARK: - Glass TextField with Focus Glow
struct GlassTextFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                if isRequired {
                    Text("*")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
                .focused($isFocused)
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ? Color.brandPrimary : Color.white.opacity(0.15),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Glass TextEditor with Focus Glow
struct GlassTextEditorView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var charLimit: Int
    var isRequired: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.8))
                if isRequired {
                    Text("*")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.primary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, maxHeight: 160)
                    .padding(12)
                    .focused($isFocused)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFocused ? Color.brandPrimary : Color.white.opacity(0.15),
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Spacer()
                Text("\(text.count)/\(charLimit)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(text.count > charLimit ? .red : .secondary)
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(AppViewModel())
    }
}
