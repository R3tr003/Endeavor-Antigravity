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
    
    @FocusState private var focusFirstName: Bool
    @FocusState private var focusLastName: Bool
    @FocusState private var focusRole: Bool
    @FocusState private var focusPersonalBio: Bool
    @FocusState private var focusCompanyName: Bool
    @FocusState private var focusWebsite: Bool
    @FocusState private var focusCompanyBio: Bool
    @FocusState private var focusNewEmail: Bool
    @FocusState private var focusPassword: Bool
    
    // Available options for Focus
    let availableChallenges = ["Hiring", "Fundraising", "Go-to-market", "Ops", "Product", "Intl Expansion"]
    let availableExpertise = ["Scaling", "Product", "Marketing", "Investment", "Strategy", "Operations", "Sales", "Legal"]
    
    // Country/City data
    var availableCountries: [String] { LocationData.shared.availableCountries }
    
    func citiesForCountry(_ country: String) -> [String] {
        return LocationData.shared.citiesForCountry(country)
    }
    
    var body: some View {
        ZStack {
            // Immersive background
            Color.background.edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    focusFirstName = false
                    focusLastName = false
                    focusRole = false
                    focusPersonalBio = false
                    focusCompanyName = false
                    focusWebsite = false
                    focusCompanyBio = false
                    focusNewEmail = false
                    focusPassword = false
                }
            
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
                            .padding(.horizontal, DesignSystem.Spacing.standard)
                            .padding(.vertical, DesignSystem.Spacing.xSmall)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.standard)
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
                                .padding(.horizontal, DesignSystem.Spacing.medium)
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
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.standard)
                
                // MARK: - Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        if selectedTab == "Personal" {
                            personalEditContent
                        } else if selectedTab == "Company" {
                            companyEditContent
                        } else {
                            focusEditContent
                        }
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .padding(.bottom, DesignSystem.Spacing.xxLarge)
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
        }
        .onAppear {
            loadCurrentData()
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
    func glassTextField(title: String, placeholder: String, text: Binding<String>, isFocused: FocusState<Bool>.Binding, isRequired: Bool = false) -> some View {
        GlassTextFieldView(title: title, placeholder: placeholder, text: text, isFocused: isFocused, isRequired: isRequired)
    }
    
    func glassTextEditor(title: String, placeholder: String, text: Binding<String>, charLimit: Int, isHighlighted: Bool, isRequired: Bool = false) -> some View {
        GlassTextEditorView(title: title, placeholder: placeholder, text: text, charLimit: charLimit, isHighlighted: isHighlighted, isRequired: isRequired)
    }
    
    func glassDropdown(title: String, selection: String, placeholder: String, isRequired: Bool = false, @ViewBuilder menuContent: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            HStack(spacing: DesignSystem.Spacing.xxSmall) {
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
                .padding(DesignSystem.Spacing.standard)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .transaction { $0.animation = nil }
        }
    }
    
    // MARK: - Sections wrapped in glass card
    func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .foregroundColor(.primary.opacity(0.7))
                .kerning(1)
                .padding(.horizontal, DesignSystem.Spacing.xxSmall)
            
            VStack(spacing: DesignSystem.Spacing.standard) {
                content()
            }
            .padding(DesignSystem.Spacing.medium)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous)
                    .stroke(Color.brandPrimary.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.brandPrimary.opacity(0.15), radius: 15, x: 0, y: 8)
        }
    }
    
    // MARK: - Personal Tab
    var personalEditContent: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            glassSection(title: "Personal Information") {
                glassTextField(title: "First Name", placeholder: "Enter your first name", text: $firstName, isFocused: $focusFirstName, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit { focusLastName = true }
                
                glassTextField(title: "Last Name", placeholder: "Enter your last name", text: $lastName, isFocused: $focusLastName, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit { focusRole = true }
                
                glassTextField(title: "Role/Title", placeholder: "e.g. CEO, CTO", text: $role, isFocused: $focusRole, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit { focusPersonalBio = true }
            }
            
            glassSection(title: "About You") {
                glassTextEditor(title: "Bio", placeholder: "Tell us a bit about yourself...", text: $personalBio, charLimit: 300, isHighlighted: focusPersonalBio, isRequired: true)
                    .focused($focusPersonalBio)
            }
            
            glassSection(title: "Contact") {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Work Email")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Text(appViewModel.currentUser?.email ?? "No Email")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(DesignSystem.Spacing.standard)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showEmailChange.toggle()
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xxSmall) {
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
                                HStack(spacing: DesignSystem.Spacing.xxSmall) {
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
                                    .focused($focusNewEmail)
                                    .submitLabel(.next)
                                    .onSubmit { focusPassword = true }
                                    .padding(DesignSystem.Spacing.standard)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                            .stroke(
                                                focusNewEmail ? Color.brandPrimary :
                                                Color.white.opacity(0.15),
                                                lineWidth: focusNewEmail ? 1.5 : 1
                                            )
                                            .animation(.easeInOut(duration: 0.2), value: focusNewEmail)
                                    )
                            }
                            
                            if !appViewModel.isGoogleUser {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current Password")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary.opacity(0.8))
                                    
                                    SecureField("Enter your current password", text: $emailChangePassword)
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(.primary)
                                        .focused($focusPassword)
                                        .submitLabel(.done)
                                        .onSubmit { sendEmailChange() }
                                        .disabled(!isNewEmailValid)
                                        .padding(DesignSystem.Spacing.standard)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                                .stroke(
                                                    focusPassword ? Color.brandPrimary :
                                                    Color.white.opacity(isNewEmailValid ? 0.15 : 0.05),
                                                    lineWidth: focusPassword ? 1.5 : 1
                                                )
                                                .animation(.easeInOut(duration: 0.2), value: focusPassword)
                                        )
                                        .opacity(isNewEmailValid ? 1.0 : 0.4)
                                        .animation(.easeInOut(duration: 0.25), value: isNewEmailValid)
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
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.Spacing.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Spacing.medium)
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
        VStack(spacing: DesignSystem.Spacing.large) {
            glassSection(title: "Company Info") {
                glassTextField(title: "Company Name", placeholder: "Enter company name", text: $companyName, isFocused: $focusCompanyName, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit { focusWebsite = true }
                
                glassTextField(title: "Website", placeholder: "https://example.com", text: $website, isFocused: $focusWebsite, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit { focusCompanyBio = true }
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
                glassTextEditor(title: "Company Bio", placeholder: "Describe your company mission and goals...", text: $companyBio, charLimit: 1000, isHighlighted: focusCompanyBio, isRequired: true)
                    .focused($focusCompanyBio)
            }
        }
    }
    
    // MARK: - Focus Tab
    var focusEditContent: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            glassSection(title: "Your Top 3 Challenges") {
                FlowLayout(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(availableChallenges, id: \.self) { challenge in
                        Button(action: { toggleChallenge(challenge) }) {
                            Text(challenge)
                                .font(.system(size: 14, weight: challenges.contains(challenge) ? .bold : .medium, design: .rounded))
                                .foregroundColor(challenges.contains(challenge) ? .white : .primary)
                                .padding(.vertical, 10)
                                .padding(.horizontal, DesignSystem.Spacing.standard)
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
                FlowLayout(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(availableExpertise, id: \.self) { expertise in
                        Button(action: { toggleExpertise(expertise) }) {
                            Text(expertise)
                                .font(.system(size: 14, weight: desiredExpertise.contains(expertise) ? .bold : .medium, design: .rounded))
                                .foregroundColor(desiredExpertise.contains(expertise) ? .white : .primary)
                                .padding(.vertical, 10)
                                .padding(.horizontal, DesignSystem.Spacing.standard)
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
        } else if desiredExpertise.count < 3 {
            desiredExpertise.append(expertise)
        }
    }
    
    func saveChanges() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        // Validation
        let firstNameClean = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastNameClean = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let roleClean = role.trimmingCharacters(in: .whitespacesAndNewlines)
        let personalBioClean = personalBio.trimmingCharacters(in: .whitespacesAndNewlines)
        let companyBioClean = companyBio.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if firstNameClean.isEmpty {
            alertMessage = "Please enter your first name."
            showingAlert = true
            return
        }
        
        if lastNameClean.isEmpty {
            alertMessage = "Please enter your last name."
            showingAlert = true
            return
        }
        
        if roleClean.isEmpty {
            alertMessage = "Please enter your role."
            showingAlert = true
            return
        }
        
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
        appViewModel.saveProfileChanges { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
    
    // MARK: - Helper Methods
    
    private func loadCurrentData() {
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
        
        // Ensure animation happens only once or is handled correctly
        if !animateGlow {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
}

// MARK: - Glass TextField with Focus Glow
struct GlassTextFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isRequired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            HStack(spacing: DesignSystem.Spacing.xxSmall) {
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
                .padding(DesignSystem.Spacing.standard)
                .focused($isFocused)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(
                            isFocused ? Color.brandPrimary : Color.borderGlare.opacity(0.15),
                            lineWidth: isFocused ? 1.5 : 1
                        )
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                )
        }
    }
}

// MARK: - Glass TextEditor with Focus Glow
struct GlassTextEditorView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var charLimit: Int
    var isHighlighted: Bool
    var isRequired: Bool = false
    
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
                    .padding(DesignSystem.Spacing.small)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(
                                isHighlighted ? Color.brandPrimary : Color.borderGlare.opacity(0.15),
                                lineWidth: isHighlighted ? 1.5 : 1
                            )
                            .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                    )
                
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, DesignSystem.Spacing.standard)
                        .padding(.vertical, DesignSystem.Spacing.medium)
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
