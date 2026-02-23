import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @AppStorage("userEmail") private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showMailError: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    
    @FocusState private var isFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    // Animation states for the fluid background
    @State private var animateGradient1 = false
    @State private var animateGradient2 = false
    @State private var animateGradient3 = false

    var body: some View {
        ZStack {
            // 1. Immersive, edge-to-edge fluid background
            backgroundMesh
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // 2. Modern Branding Header
                VStack(spacing: 8) {
                    Image("WelcomeLogo") // Ensure you have this in Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 8)
                    
                    Text("Endeavor")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Text("Access reserved for authorized Endeavor members and mentors.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // 3. Floating Liquid Glass Login Panel
                floatingLoginPanel
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
            .alert("No Mail App Found", isPresented: $showMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The email 'help@endeavor.org' has been copied to your clipboard.")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animateGradient1.toggle()
            }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(1.0)) {
                animateGradient2.toggle()
            }
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true).delay(2.0)) {
                animateGradient3.toggle()
            }
        }
    }
    
    // MARK: - Fluid Background
    private var backgroundMesh: some View {
        ZStack {
            Color.background // Base color
            
            // Teal dynamic blobs
            Circle()
                .fill(Color.brandPrimary.opacity(0.6))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(x: animateGradient1 ? -100 : 100, y: animateGradient1 ? -150 : 50)
            
            Circle()
                .fill(Color(hex: "00D9C5").opacity(0.5)) // Slightly different teal
                .blur(radius: 80)
                .frame(width: 400, height: 400)
                .offset(x: animateGradient2 ? 150 : -50, y: animateGradient2 ? 200 : -200)
                
            Circle()
                .fill(Color.chartAccent.opacity(0.3)) // Subtle purple accent
                .blur(radius: 90)
                .frame(width: 250, height: 250)
                .offset(x: animateGradient3 ? -50 : 150, y: animateGradient3 ? 300 : 0)
        }
    }
    
    // MARK: - Floating Liquid Glass Login Panel
    private var floatingLoginPanel: some View {
        VStack(spacing: 20) {
            // Email Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter your authorized email", text: $email)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFocused ? Color.brandPrimary :
                                (!isValidEmail && !email.isEmpty) ? Color.error.opacity(0.7) :
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                    .foregroundColor(.white)
                    .accentColor(.brandPrimary)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($isFocused)
                
                if !isValidEmail && !email.isEmpty && !isFocused {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundColor(.error)
                }
            }
            
            // Password Input
            if isValidEmail {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            TextField("Password", text: $password)
                                .padding()
                                .padding(.trailing, 40)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .accentColor(.brandPrimary)
                                .focused($isPasswordFocused)
                        } else {
                            SecureField("Password", text: $password)
                                .padding()
                                .padding(.trailing, 40)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                                .accentColor(.brandPrimary)
                                .focused($isPasswordFocused)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.trailing, 16)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isPasswordFocused ? Color.brandPrimary :
                                !password.isEmpty && !passwordErrorMessage.isEmpty ? Color.error.opacity(0.7) :
                                Color.white.opacity(0.2),
                                lineWidth: isPasswordFocused ? 1.5 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isPasswordFocused)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    if !password.isEmpty && !passwordErrorMessage.isEmpty {
                        Text(passwordErrorMessage)
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                    
                    if let errorMessage = appViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.error)
                    }
                }
                .animation(.easeInOut, value: passwordErrorMessage)
                
                if appViewModel.failedLoginAttempts >= 2 {
                    Button(action: {
                        appViewModel.sendPasswordReset(email: email)
                    }) {
                        HStack(spacing: 4) {
                            Text("Forgot Password?")
                                .foregroundColor(.white.opacity(0.8))
                            Text("Reset it here")
                                .foregroundColor(.brandPrimary)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
            
            // Sign In Button
            Button(action: {
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
                        .foregroundColor((isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty) ? .textInverted : .white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background((isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty && !appViewModel.isLoading) ? Color.brandPrimary : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .disabled(!isValidEmail || !passwordErrorMessage.isEmpty || password.isEmpty || appViewModel.isLoading)
            .shadow(color: (isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty) ? Color.brandPrimary.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
            .animation(.easeInOut(duration: 0.25), value: isValidEmail && passwordErrorMessage.isEmpty && !password.isEmpty)
            
            // Social & Terms
            VStack(spacing: 16) {
                Button(action: {
                    appViewModel.startGoogleSignIn()
                }) {
                    HStack {
                        Image("GoogleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                HStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .foregroundColor(.white.opacity(0.7))
                    Button("Terms") { showTerms = true }
                        .foregroundColor(.brandPrimary)
                    Text("&")
                        .foregroundColor(.white.opacity(0.7))
                    Button("Privacy") { showPrivacy = true }
                        .foregroundColor(.brandPrimary)
                }
                .font(.caption2)
            }
            .padding(.top, 8)
            
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
                HStack(spacing: 4) {
                    Text("Having troubles?")
                        .foregroundColor(.white.opacity(0.6))
                    Text("Get Help")
                        .foregroundColor(.brandPrimary)
                }
                .font(.caption)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isValidEmail)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.failedLoginAttempts)
        .padding(24)
        // LIQUID GLASS EFFECT applied to the panel container
        .modifier(LiquidGlassEffect(cornerRadius: 32))
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
                        colors: [.white.opacity(0.4), .clear, .white.opacity(0.2)],
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



