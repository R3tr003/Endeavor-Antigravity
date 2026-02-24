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
                        Text("Settings")
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
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.standard)
                                .padding(.vertical, DesignSystem.Spacing.xSmall)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)), alignment: .bottom)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .ignoresSafeArea(edges: .top)
                } else {
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                    .padding()
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
                    performDeleteAccount(password: nil)
                } else {
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
                    .stroke(isDestructive ? Color.red.opacity(0.2) : Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        settingsSection(title: "Profile") {
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
                    
                    Text("Edit Profile Data")
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
        settingsSection(title: "Appearance") {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                }
                
                Text("Theme")
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
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
        settingsSection(title: "Account") {
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
                    
                    Text("Log Out")
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
        settingsSection(title: "Danger Zone", isDestructive: true) {
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
                    
                    Text("Delete Account")
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
        settingsSection(title: "About") {
            HStack {
                Text("Version")
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
