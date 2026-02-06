import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email: String = ""
    
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
                    
                    // Login Button
                    Button(action: {
                        if isValidEmail {
                            appViewModel.login(email: email)
                        }
                    }) {
                        Text("Login")
                            .font(.branding.body.weight(.bold))
                            .foregroundColor(.background)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidEmail ? Color.brandPrimary : Color.textSecondary.opacity(0.3))
                            .cornerRadius(8)
                    }
                    .disabled(!isValidEmail)
                    
                    // Terms Disclaimer
                    Text("By clicking Login, you agree to our Terms & Conditions and Privacy Policy.")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                Button(action: {
                    // Contact Admin action
                }) {
                    HStack(spacing: 0) {
                        Text("Having trouble? ")
                            .foregroundColor(.textSecondary)
                        Text("Contact Admin")
                            .foregroundColor(.brandPrimary)
                    }
                }
                .font(.branding.inputLabel)
                .padding(.bottom, 24)
            }
        }
    }
    var isValidEmail: Bool {
        // Regex strictly requires characters before the dot in domain part
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
