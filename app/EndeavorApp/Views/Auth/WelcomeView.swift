import SwiftUI


struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @AppStorage("userEmail") private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showMailError: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    @State private var showResetSentAlert: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo & Title
                VStack(spacing: 16) {
                    // Logo
                    Image("WelcomeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle()) // Made circular as requested
                        .padding(.bottom, 8)
                    
                    Text("Endeavor")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Access reserved for authorized Endeavor members and mentors.")
                        .font(.branding.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)
                
                // Login Form
                VStack(spacing: 24) {
                    // Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter your authorized email", text: $email)
                            .font(.branding.body)
                            .padding()
                            .background(Color.inputBackground)
                            .cornerRadius(8)
                            .focused($isFocused)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        isFocused ? Color.brandPrimary :
                                        (!isValidEmail && !email.isEmpty) ? Color.error :
                                        Color.textSecondary.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundColor(isValidEmail || email.isEmpty || isFocused ? .textPrimary : .error)
                            .tint(.brandPrimary)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        if !isValidEmail && !email.isEmpty && !isFocused {
                            Text("Please enter a valid email address.")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                    }
                    
                // Password Input (Appears only when email is valid)
                if isValidEmail {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .font(.branding.body)
                                    .padding()
                                    .padding(.trailing, 32) // Make room for eye icon
                                    .background(Color.inputBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.textPrimary)
                                    .tint(.brandPrimary)
                            } else {
                                SecureField("Password", text: $password)
                                    .font(.branding.body)
                                    .padding()
                                    .padding(.trailing, 32) // Make room for eye icon
                                    .background(Color.inputBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.textPrimary)
                                    .tint(.brandPrimary)
                            }
                            
                            // Visibility Toggle
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye" : "eye.slash")
                                    .foregroundColor(.textSecondary)
                                    .padding(.trailing, 16)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    !password.isEmpty && !passwordErrorMessage.isEmpty ? Color.error :
                                    Color.textSecondary.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        if !password.isEmpty && !passwordErrorMessage.isEmpty {
                            Text(passwordErrorMessage)
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        }
                        
                        // Login Error Message (e.g., wrong password)
                        if let errorMessage = appViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                    }
                    .animation(.easeInOut, value: passwordErrorMessage) // Smoothly animate layout changes
                    
                    // Forgot Password (appears after 2 failed attempts)
                    if appViewModel.failedLoginAttempts >= 2 {
                        Button(action: {
                            appViewModel.sendPasswordReset(email: email)
                            showResetSentAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Forgot Password? Reset it here")
                            }
                            .font(.branding.inputLabel.weight(.bold))
                            .foregroundColor(.brandPrimary)
                            .shadow(color: .brandPrimary.opacity(0.5), radius: 4, x: 0, y: 0) // Glowing effect
                        }
                        .padding(.top, 4)
                        .transition(.opacity.animation(.easeInOut))
                        .alert("Reset Email Sent", isPresented: $showResetSentAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("If an account exists for \(email), you will receive a password reset link shortly.")
                        }
                    }
                }
                
                // Unified Sign In Button
                Button(action: {
                    if isValidEmail && passwordErrorMessage.isEmpty {
                        appViewModel.authenticate(email: email, password: password)
                    }
                }) {
                    HStack {
                        if appViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .background))
                                .scaleEffect(0.8)
                        }
                        Text(appViewModel.isLoading ? "Please wait..." : "Sign In")
                            .font(.branding.body.weight(.bold))
                            .foregroundColor(.background)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty && !appViewModel.isLoading) ? Color.brandPrimary : Color.textSecondary.opacity(0.3))
                    .cornerRadius(8)
                }
                .disabled(!isValidEmail || !passwordErrorMessage.isEmpty || password.isEmpty || appViewModel.isLoading)
                
                // OR Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(Color.textSecondary.opacity(0.3))
                    Text("OR").font(.branding.inputLabel).foregroundColor(.textSecondary)
                    Rectangle().frame(height: 1).foregroundColor(Color.textSecondary.opacity(0.3))
                }
                .padding(.vertical, 8)
                
                // Social Logins
                VStack(spacing: 12) {

                    
                    // Google Sign In (Placeholder for now, requires GoogleSignIn dependency)
                    Button(action: {
                        appViewModel.startGoogleSignIn()
                    }) {
                        HStack {
                            Image("GoogleLogo") // Classic Colored Google G
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .font(.system(size: 20))
                            Text("Sign in with Google")
                                .font(.branding.body.weight(.medium))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                
                // Terms Disclaimer
                VStack(spacing: 4) {
                    Text("By clicking Sign In, you agree to our")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                    
                    HStack(spacing: 4) {
                        Button(action: { showTerms = true }) {
                            Text("Terms & Conditions")
                                .font(.branding.inputLabel.weight(.medium))
                                .foregroundColor(.brandPrimary)
                        }
                        
                        Text("and")
                            .font(.branding.inputLabel)
                            .foregroundColor(.textSecondary)
                        
                        Button(action: { showPrivacy = true }) {
                            Text("Privacy Policy")
                                .font(.branding.inputLabel.weight(.medium))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
                .padding(.top, 8)
                .sheet(isPresented: $showTerms) {
                    PolicyView(
                        title: "Terms & Conditions",
                        content: DummyLegalContent.terms,
                        isPresented: $showTerms
                    )
                }
                .sheet(isPresented: $showPrivacy) {
                    PolicyView(
                        title: "Privacy Policy",
                        content: DummyLegalContent.privacy,
                        isPresented: $showPrivacy
                    )
                }
                

            }
            .padding(.horizontal, 24)
            .animation(.easeInOut, value: isValidEmail)
            
            Spacer()
                
                // Footer
                Button(action: contactAdmin) {
                    Text("Need help? Contact Admin") // Accessibility label
                }
                .buttonStyle(ContactFooterStyle())
                .padding(.bottom, 24)
            .alert("No Mail App Found", isPresented: $showMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The email 'help@endeavor.org' has been copied to your clipboard.")
            }

            }
        }
    }
    
    var isValidEmail: Bool {
        // Regex strictly requires characters before the dot in domain part
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var passwordErrorMessage: String {
        if password.isEmpty { return "" }
        
        var errors: [String] = []
        
        if password.count < 8 || password.count > 16 {
            errors.append("8-16 characters")
        }
        
        let uppercasePred = NSPredicate(format:"SELF MATCHES %@", ".*[A-Z]+.*")
        if !uppercasePred.evaluate(with: password) {
            errors.append("1 uppercase letter")
        }
        
        let numberPred = NSPredicate(format:"SELF MATCHES %@", ".*[0-9]+.*")
        if !numberPred.evaluate(with: password) {
            errors.append("1 number")
        }
        
        if errors.isEmpty {
            return ""
        } else {
            return "Missing: " + errors.joined(separator: ", ")
        }
    }
                


    // MARK: - Actions
    private func contactAdmin() {
        let email = "help@endeavor.org"
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Copy to clipboard if Mail app is missing (Simulator)
                UIPasteboard.general.string = email
                showMailError = true
            }
        }
    }
}

// MARK: - Styles
struct ContactFooterStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            Text("Need help?")
                .foregroundColor(.textSecondary)
            
            Text("Contact Admin")
                .foregroundColor(.brandPrimary)
                .fontWeight(.medium)
                .opacity(configuration.isPressed ? 0.5 : 1.0) // Animate ONLY this part
        }
        .font(.branding.inputLabel)
        .contentShape(Rectangle()) // Make entire area tapable
    }
}

struct DummyLegalContent {
    static let terms = """
    **Terms and Conditions**
    
    Last updated: February 06, 2026
    
    Please read these terms and conditions carefully before using Our Service.
    
    1. **Interpretation and Definitions**
    The words of which the initial letter is capitalized have meanings defined under the following conditions.
    
    2. **Acknowledgment**
    These are the Terms and Conditions governing the use of this Service and the agreement that operates between You and the Company.
    
    3. **User Accounts**
    When You create an account with Us, You must provide Us information that is accurate, complete, and current at all times.
    
    4. **Content**
    Our Service allows You to post Content. You are responsible for the Content that You post to the Service.
    
    5. **Copyright Policy**
    We respect the intellectual property rights of others. It is Our policy to respond to any claim that Content posted on the Service infringes a copyright.
    
    (This is a placeholder for the full Terms & Conditions)
    """
    
    static let privacy = """
    **Privacy Policy**
    
    Last updated: February 06, 2026
    
    This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service.
    
    1. **Collecting and Using Your Personal Data**
    We collect several different types of information for various purposes to provide and improve our Service to you.
    
    2. **Types of Data Collected**
    - Personal Data (Email, First Name, Last Name)
    - Usage Data
    
    3. **Use of Your Personal Data**
    The Company may use Personal Data for the following purposes:
    - To provide and maintain our Service
    - To manage Your Account
    - To contact You
    
    4. **Retention of Your Personal Data**
    The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy.
    
    (This is a placeholder for the full Privacy Policy)
    """
}

struct PolicyView: View {
    let title: String
    let content: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .font(.branding.body)
                    .foregroundColor(.textSecondary)
                    .padding()
            }
            .background(Color.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
        .colorScheme(.dark) // Force dark mode consistent with app
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}


