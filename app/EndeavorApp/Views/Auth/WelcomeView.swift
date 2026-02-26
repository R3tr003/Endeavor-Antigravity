import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @AppStorage("userEmail") private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showMailError: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    enum Field: Hashable {
        case email, password
    }
    @FocusState private var focusedField: Field?
    
    // 

    var body: some View {
        ZStack {
            // 1. Immersive, edge-to-edge fluid background
            FluidBackgroundView()
                .onTapGesture { focusedField = nil }
            
            VStack {
                Spacer()
                
                // 2. Modern Branding Header
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image("WelcomeLogo") // Ensure you have this in Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.bottom, DesignSystem.Spacing.xSmall)
                    
                    Text("Endeavor")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.brandPrimary) // Teal come richiesto
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Text("Access reserved for authorized Endeavor members and mentors.")
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.85)) // Contrasto per light/dark
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xxLarge)
                }
                .padding(.bottom, DesignSystem.Spacing.xxLarge)
                
                Spacer()
                
                // 3. Floating Liquid Glass Login Panel
                floatingLoginPanel
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.xxLarge)
            }
            .alert("No Mail App Found", isPresented: $showMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The email 'help@endeavor.org' has been copied to your clipboard.")
            }
        }
    }
    
    // MARK: - Floating Liquid Glass Login Panel
    private var floatingLoginPanel: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Email Input
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                TextField("Enter your authorized email", text: $email)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .fill(.ultraThinMaterial)
                            .shadow(color: focusedField == .email ? Color.brandPrimary.opacity(0.15) : .clear, radius: 10, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.2), value: focusedField == .email)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(
                                focusedField == .email ? Color.brandPrimary :
                                (!isValidEmail && !email.isEmpty) ? Color.error.opacity(0.7) :
                                Color.borderGlare.opacity(0.15),
                                lineWidth: focusedField == .email ? 1.5 : 1
                            )
                            .shadow(color: focusedField == .email ? Color.brandPrimary.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.2), value: focusedField == .email)
                    )
                    .foregroundColor(.primary)
                    .accentColor(.brandPrimary)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            focusedField = .password
                        }
                    }
                
                if !isValidEmail && !email.isEmpty && focusedField != .email {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundColor(.error)
                }
            }
            
            if isValidEmail {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    ZStack(alignment: .trailing) {
                        TextField("Password", text: $password)
                            .padding()
                            .padding(.trailing, DesignSystem.Spacing.xxLarge)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: focusedField == .password ? Color.brandPrimary.opacity(0.15) : .clear, radius: 10, x: 0, y: 0)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField == .password)
                            )
                            .foregroundColor(.primary)
                            .accentColor(.brandPrimary)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                                if isValidEmail && passwordErrorMessage.isEmpty {
                                    appViewModel.authenticate(email: email, password: password)
                                }
                            }
                            .opacity(showPassword ? 1 : 0)
                            
                        SecureField("Password", text: $password)
                            .padding()
                            .padding(.trailing, DesignSystem.Spacing.xxLarge)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: focusedField == .password ? Color.brandPrimary.opacity(0.15) : .clear, radius: 10, x: 0, y: 0)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField == .password)
                            )
                            .foregroundColor(.primary)
                            .accentColor(.brandPrimary)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                                if isValidEmail && passwordErrorMessage.isEmpty {
                                    appViewModel.authenticate(email: email, password: password)
                                }
                            }
                            .opacity(showPassword ? 0 : 1)
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.primary.opacity(0.7))
                                .padding(.trailing, DesignSystem.Spacing.standard)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(
                                focusedField == .password ? Color.brandPrimary :
                                !password.isEmpty && !passwordErrorMessage.isEmpty ? Color.error.opacity(0.7) :
                                Color.borderGlare.opacity(0.15),
                                lineWidth: focusedField == .password ? 1.5 : 1
                            )
                            .shadow(color: focusedField == .password ? Color.brandPrimary.opacity(0.5) : .clear, radius: 4, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.2), value: focusedField == .password)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    if !password.isEmpty && !passwordErrorMessage.isEmpty {
                        Text(passwordErrorMessage)
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                    
                    if let appError = appViewModel.appError {
                        Text(appError.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                }
                .animation(.easeInOut, value: passwordErrorMessage)
                .onChange(of: password) { _, _ in
                    appViewModel.appError = nil
                }
                .onChange(of: email) { _, _ in
                    appViewModel.appError = nil
                }
                
                if appViewModel.failedLoginAttempts >= 2 {
                    Button(action: {
                        appViewModel.sendPasswordReset(email: email)
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xxSmall) {
                            Text("Forgot Password?")
                                .foregroundColor(.primary.opacity(0.8))
                            Text("Reset it here")
                                .foregroundColor(.brandPrimary)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, DesignSystem.Spacing.xxSmall)
                    .transition(.opacity)
                }
            }
            
            // Sign In Button
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                if isValidEmail && passwordErrorMessage.isEmpty {
                    appViewModel.authenticate(email: email, password: password)
                }
            }) {
                HStack {
                    if appViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(appViewModel.isLoading ? "Please wait..." : "Sign In")
                        .font(.headline.weight(.bold))
                        .foregroundColor((isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty) ? .textInverted : .primary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Layout.buttonHeight)
                .background((isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty && !appViewModel.isLoading) ? Color.brandPrimary : Color.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .disabled(!isValidEmail || !passwordErrorMessage.isEmpty || password.isEmpty || appViewModel.isLoading)
            .shadow(color: (isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty) ? Color.brandPrimary.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            .animation(.easeInOut(duration: 0.25), value: isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty)
            
            // Social & Terms
            VStack(spacing: DesignSystem.Spacing.standard) {
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    appViewModel.startGoogleSignIn()
                }) {
                    HStack {
                        Image("GoogleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: DesignSystem.IconSize.standard, height: DesignSystem.IconSize.standard)
                        Text("Continue with Google")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Layout.buttonHeight)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                }
                
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Text("By continuing, you agree to our")
                        .foregroundColor(.primary.opacity(0.7))
                    Button("Terms") { showTerms = true }
                        .foregroundColor(.brandPrimary)
                    Text("&")
                        .foregroundColor(.primary.opacity(0.7))
                    Button("Privacy") { showPrivacy = true }
                        .foregroundColor(.brandPrimary)
                }
                .font(.caption2)
            }
            .padding(.top, DesignSystem.Spacing.xSmall)
            
            // Help link
            Button(action: {
                UIPasteboard.general.string = "help@endeavor.org"
                if let mailURL = URL(string: "mailto:help@endeavor.org") {
                    UIApplication.shared.open(mailURL) { success in
                        if !success {
                            showMailError = true
                        }
                    }
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Text("Having troubles?")
                        .foregroundColor(.primary.opacity(0.6))
                    Text("Get Help")
                        .foregroundColor(.brandPrimary)
                }
                .font(.caption)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isValidEmail)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.failedLoginAttempts)
        .padding(DesignSystem.Spacing.large)
        // LIQUID GLASS EFFECT applied to the panel container
        .modifier(LiquidGlassEffect(cornerRadius: DesignSystem.Spacing.xLarge))
        .alert("Reset Email Sent", isPresented: $appViewModel.passwordResetSent) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("If an account exists for \(email), you will receive a password reset link shortly.")
        }
        .sheet(isPresented: $showTerms) {
            PolicyView(title: "Terms & Conditions", content: DummyLegalContent.terms, isPresented: $showTerms)
        }
        .sheet(isPresented: $showPrivacy) {
            PolicyView(title: "Privacy Policy", content: DummyLegalContent.privacy, isPresented: $showPrivacy)
        }
    }
    
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var passwordErrorMessage: String {
        if password.isEmpty { return "" }
        var errors: [String] = []
        if password.count < 8 || password.count > 16 { errors.append("8-16 chars") }
        
        let uppercasePred = NSPredicate(format:"SELF MATCHES %@", ".*[A-Z]+.*")
        if !uppercasePred.evaluate(with: password) { errors.append("1 uppercase") }
        
        let lowercasePred = NSPredicate(format:"SELF MATCHES %@", ".*[a-z]+.*")
        if !lowercasePred.evaluate(with: password) { errors.append("1 lowercase") }
        
        let numberPred = NSPredicate(format:"SELF MATCHES %@", ".*[0-9]+.*")
        if !numberPred.evaluate(with: password) { errors.append("1 number") }
        
        return errors.isEmpty ? "" : "Missing: " + errors.joined(separator: ", ")
    }
}

// MARK: - Custom Liquid Glass Modifier
/// Custom wrapper for the Liquid Glass effect
struct LiquidGlassEffect: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        // We use dynamic checks if `.glassEffect` was an actual API,
        // but since we must provide compiling code, we simulate the futuristic API using Materials.
        // If `.glassEffect` is explicitly available in the user's Xcode via an extension or SDK 26,
        // we use a clean `#if compiler(>=6.0)` macro or just standard materials for safety.
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LinearGradient(
                        colors: [Color.borderGlare.opacity(0.4), .clear, Color.borderGlare.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Legacy / Helper Views (Keep intact to prevent compiler errors)
struct DummyLegalContent {
    static let terms = "Terms and Conditions..."
    static let privacy = "Privacy Policy..."
}

struct PolicyView: View {
    let title: String
    let content: String
    @Binding var isPresented: Bool
    var body: some View {
        NavigationView {
            ScrollView {
                Text(content).padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
        }.colorScheme(.dark)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppViewModel())
    }
}



