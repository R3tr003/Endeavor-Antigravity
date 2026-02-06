import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile: Bool = false
    @State private var showLogoutConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    profileSection
                    appearanceSection
                    accountSection
                    aboutSection
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
                
                Text("1.0.0")
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
