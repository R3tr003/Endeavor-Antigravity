import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showPasswordInput: Bool = false
    @State private var deletePassword: String = ""
    @State private var showDeleteError: Bool = false
    @State private var deleteErrorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    profileSection
                    appearanceSection
                    accountSection
                    aboutSection
                    deleteAccountSection
                }
                .padding(24)
            }
            .background(Color.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(appViewModel)
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                appViewModel.logout()
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                if appViewModel.isGoogleUser {
                    // Google users don't need password
                    performDeleteAccount(password: nil)
                } else {
                    // Email/password users need to enter password
                    showPasswordInput = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is irreversible. All your data will be permanently deleted.")
        }
        .alert("Enter Password", isPresented: $showPasswordInput) {
            SecureField("Password", text: $deletePassword)
            Button("Delete", role: .destructive) {
                performDeleteAccount(password: deletePassword)
            }
            Button("Cancel", role: .cancel) {
                deletePassword = ""
            }
        } message: {
            Text("Enter your password to confirm account deletion.")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .preferredColorScheme(appViewModel.colorScheme)
    }
    
    private func performDeleteAccount(password: String?) {
        appViewModel.deleteAccount(password: password) { result in
            switch result {
            case .success:
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                // Check if it's an authentication error (wrong password)
                let nsError = error as NSError
                if nsError.domain == "FIRAuthErrorDomain" || error.localizedDescription.contains("credential") || error.localizedDescription.contains("password") {
                    deleteErrorMessage = "Incorrect Password. Insert the correct password."
                } else {
                    deleteErrorMessage = error.localizedDescription
                }
                showDeleteError = true
                deletePassword = ""
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE")
                .font(.branding.inputLabel)
                .foregroundColor(.textSecondary)
            
            Button(action: { showEditProfile = true }) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.brandPrimary)
                        .frame(width: 24)
                    
                    Text("Edit Profile")
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
                .background(Color.textSecondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APPEARANCE")
                .font(.branding.inputLabel)
                .foregroundColor(.textSecondary)
            
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.brandPrimary)
                    .frame(width: 24)
                
                Text("Theme")
                    .font(.branding.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Picker("", selection: Binding(
                    get: { appViewModel.selectedTheme },
                    set: { appViewModel.setTheme($0) }
                )) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                    Text("System").tag("System")
                }
                .pickerStyle(.menu)
                .tint(.brandPrimary)
            }
            .padding(16)
            .background(Color.textSecondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCOUNT")
                .font(.branding.inputLabel)
                .foregroundColor(.textSecondary)
            
            Button(action: { showLogoutConfirmation = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Log Out")
                        .font(.branding.body)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.textSecondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DANGER ZONE")
                .font(.branding.inputLabel)
                .foregroundColor(.red.opacity(0.8))
            
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Delete Account")
                        .font(.branding.body)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    if appViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(appViewModel.isLoading)
        }
        .padding(.top, 40) // Extra spacing to push it further down
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(.branding.inputLabel)
                .foregroundColor(.textSecondary)
            
            HStack {
                Text("Version")
                    .font(.branding.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("0.0.1")
                    .font(.branding.body)
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(Color.textSecondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
