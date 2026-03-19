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
    
    // For scroll tracking
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                // Ambient Glow
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: 100, y: -200)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("settingsScroll")).minY)
                    }
                    .frame(height: 0)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
                        // Title
                        Text(String(localized: "nav.settings", defaultValue: "Settings"))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(-1)
                            .padding(.top, DesignSystem.Spacing.xxLarge)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        VStack(spacing: DesignSystem.Spacing.large) {
                            profileSection
                            appearanceSection
                            accountSection
                            aboutSection
                            deleteAccountSection
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.bottom, 60)
                    }
                }
                .coordinateSpace(name: "settingsScroll")
                
                // Floating navigation bar on scroll
                if scrollOffset < -40 {
                    HStack {
                        Spacer()
                        Button(String(localized: "common.done", defaultValue: "Done")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.brandPrimary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .ignoresSafeArea(edges: .top)
                } else {
                    HStack {
                        Spacer()
                        Button(String(localized: "common.done", defaultValue: "Done")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.brandPrimary)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(appViewModel)
        }
        .alert(String(localized: "settings.log_out", defaultValue: "Log Out"), isPresented: $showLogoutConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "settings.log_out", defaultValue: "Log Out"), role: .destructive) {
                appViewModel.logout()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text(String(localized: "settings.logout_confirm", defaultValue: "Are you sure you want to log out?"))
        }
        .alert(String(localized: "settings.delete_account", defaultValue: "Delete Account"), isPresented: $showDeleteConfirmation) {
            Button(String(localized: "common.cancel"), role: .cancel) {}
            Button(String(localized: "settings.delete_account", defaultValue: "Delete Account"), role: .destructive) {
                if appViewModel.isGoogleUser {
                    performDeleteAccount(password: nil)
                } else {
                    showPasswordInput = true
                }
            }
        } message: {
            Text(String(localized: "settings.delete_warning", defaultValue: "This action is irreversible. All your data will be permanently deleted."))
        }
        .alert(String(localized: "settings.enter_password", defaultValue: "Enter Password"), isPresented: $showPasswordInput) {
            SecureField(String(localized: "settings.password", defaultValue: "Password"), text: $deletePassword)
            Button(String(localized: "common.cancel"), role: .cancel) {
                deletePassword = ""
            }
            Button(String(localized: "common.delete"), role: .destructive) {
                performDeleteAccount(password: deletePassword)
            }
        } message: {
            Text(String(localized: "settings.enter_password_confirm", defaultValue: "Enter your password to confirm account deletion."))
        }
        .alert(String(localized: "common.error", defaultValue: "Error"), isPresented: $showDeleteError) {
            Button(String(localized: "common.ok"), role: .cancel) {}
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
                let nsError = error as NSError
                if nsError.code == 17014 {
                    deleteErrorMessage = "Session expired. Please log out and back in to delete your account."
                } else if nsError.domain == "FIRAuthErrorDomain" || error.localizedDescription.contains("credential") || error.localizedDescription.contains("password") {
                    deleteErrorMessage = "Incorrect Password. Insert the correct password."
                } else {
                    deleteErrorMessage = error.localizedDescription
                }
                showDeleteError = true
                deletePassword = ""
            }
        }
    }
    
    // MARK: - Reusable Section Builder
    private func settingsSection<Content: View>(title: String, isDestructive: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundColor(isDestructive ? .red.opacity(0.8) : .secondary)
                .padding(.leading, DesignSystem.Spacing.xSmall)
            
            VStack(spacing: 0) {
                content()
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDestructive ? Color.red.opacity(0.2) : Color.borderGlare.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        settingsSection(title: String(localized: "settings.profile", defaultValue: "Profile")) {
            Button(action: { showEditProfile = true }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "person.fill")
                            .foregroundColor(.brandPrimary)
                            .font(.system(size: 16))
                    }
                    
                    Text(String(localized: "settings.edit_profile_data", defaultValue: "Edit Profile Data"))
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(DesignSystem.Spacing.standard)
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        settingsSection(title: String(localized: "settings.appearance", defaultValue: "Appearance")) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                
                Text(String(localized: "settings.theme", defaultValue: "Theme"))
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("", selection: Binding(
                    get: { appViewModel.selectedTheme },
                    set: { appViewModel.setTheme($0) }
                )) {
                    Text(String(localized: "settings.theme.light", defaultValue: "Light")).tag("Light")
                    Text(String(localized: "settings.theme.dark", defaultValue: "Dark")).tag("Dark")
                    Text(String(localized: "settings.theme.system", defaultValue: "System")).tag("System")
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.05), in: Capsule())
            }
            .padding(16)
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        settingsSection(title: String(localized: "settings.account", defaultValue: "Account")) {
            Button(action: { showLogoutConfirmation = true }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                    
                    Text("settings.log_out")
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.standard)
            }
        }
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        settingsSection(title: String(localized: "settings.danger_zone", defaultValue: "Danger Zone"), isDestructive: true) {
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                    
                    Text("settings.delete_account")
                        .font(.body.weight(.bold))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    if appViewModel.isLoading {
                        ProgressView()
                    }
                }
                .padding(DesignSystem.Spacing.standard)
            }
            .disabled(appViewModel.isLoading)
        }
        .padding(.top, DesignSystem.Spacing.large)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        settingsSection(title: String(localized: "settings.about", defaultValue: "About")) {
            HStack {
                Text(String(localized: "settings.version", defaultValue: "Version"))
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("0.1.1")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xxSmall)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }
            .padding(DesignSystem.Spacing.standard)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
}
