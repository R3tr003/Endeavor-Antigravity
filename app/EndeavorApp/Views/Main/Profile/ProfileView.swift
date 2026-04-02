import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab: String = "Personal"
    @State private var showCamera: Bool = false
    @State private var showPhotoLibrary: Bool = false
    @State private var profileImage: UIImage? = nil
    @State private var showSettings: Bool = false
    @State private var loadingMessage: String = "Uploading..."
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                // Ambient Top Glow
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 500, height: 500)
                    .blur(radius: 100)
                    .offset(y: -250)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Settings button row
                        HStack {
                            Spacer()
                            Button(action: { showSettings = true }) {
                                ZStack {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                                    
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.top, DesignSystem.Spacing.xSmall)
                        
                        profileHeader
                            .padding(.top, DesignSystem.Spacing.xSmall)
                        
                        glassTabs
                            .padding(.vertical, DesignSystem.Spacing.large)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        scrollViewContent
                    }
                    .containerRelativeFrame(.horizontal)
                    .clipped()
                }
                
                // Status bar blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $profileImage, sourceType: .camera)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePicker(image: $profileImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appViewModel)
            }
            .onChange(of: profileImage) { _, newImage in
                if let image = newImage {
                    loadingMessage = String(localized: "common.uploading", defaultValue: "Uploading...")
                    appViewModel.updateProfileImage(image)
                }
            }
            .overlay(loadingOverlay)
        }
    }
    
    var profileHeader: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // Profile Avatar Floating
            ZStack(alignment: .bottomTrailing) {
                avatarImage
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.borderGlare.opacity(0.3), lineWidth: 4))
                    .shadow(color: Color.brandPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // + Button overlay
                Menu {
                    Button(action: { showCamera = true }) {
                        Label(String(localized: "profile.take_photo", defaultValue: "Take Photo"), systemImage: "camera")
                    }
                    Button(action: { showPhotoLibrary = true }) {
                        Label(String(localized: "profile.choose_from_library", defaultValue: "Choose from Library"), systemImage: "photo.on.rectangle")
                    }
                    if profileImage != nil || !(appViewModel.currentUser?.profileImageUrl.isEmpty ?? true) {
                        Button(role: .destructive, action: {
                            loadingMessage = String(localized: "common.removing", defaultValue: "Removing...")
                            profileImage = nil
                            appViewModel.removeProfileImage()
                        }) {
                            Label(String(localized: "profile.remove_photo", defaultValue: "Remove Photo"), systemImage: "trash")
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
                .offset(x: -4, y: -4)
            }
            
            VStack(spacing: DesignSystem.Spacing.xxSmall) {
                Text(appViewModel.currentUser?.fullName ?? String(localized: "profile.user_profile", defaultValue: "User Profile"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text("\(appViewModel.currentUser?.role ?? "Founder") at \(appViewModel.companyProfile?.name ?? "Endeavor")")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
        }
    }
    
    @ViewBuilder
    var avatarImage: some View {
        if let profileImage = profileImage {
            // Show locally selected photo
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
        } else if let profileUrl = appViewModel.currentUser?.profileImageUrl, !profileUrl.isEmpty {
            // Show remote profile image
            WebImage(url: URL(string: profileUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                    ProgressView()
                }
            }
        } else {
            // Default elegant silhouette
            ZStack {
                Color.textSecondary.opacity(0.1)
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(Color.textSecondary.opacity(0.3))
            }
        }
    }
    
    // Modern Pills replacing underline tabs
    var glassTabs: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            ForEach(["Personal", "Company"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab)
                        .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, DesignSystem.Spacing.standard)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    Capsule().fill(Color.brandPrimary)
                                } else {
                                    Capsule().fill(.regularMaterial)
                                }
                            }
                        )
                        .overlay(
                            Capsule().stroke(Color.borderGlare.opacity(0.15), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var scrollViewContent: some View {
        VStack {
            if selectedTab == "Personal" {
                personalContent
            } else if selectedTab == "Company" {
                companyContent
            }
            Spacer(minLength: DesignSystem.Spacing.bottomSafePadding) // Tab bar clearance
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .transition(.opacity.combined(with: .slide))
    }
    
    var loadingOverlay: some View {
        Group {
            if appViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView(loadingMessage)
                        .padding(DesignSystem.Spacing.large)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                }
            }
        }
    }
    
    // Extracted Section UI
    func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            Text(title)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .padding(.horizontal, DesignSystem.Spacing.xxSmall)
            
            VStack(spacing: 0) {
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
    
    func profileInfoRow(icon: String, label: String, value: String, showDivider: Bool = true) -> some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.standard) {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(.brandPrimary)
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            if showDivider {
                Divider().padding(.leading, 56)
            }
        }
    }
    
    var personalContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            profileSection(title: String(localized: "profile.about", defaultValue: "About")) {
                Text(appViewModel.currentUser?.personalBio.isEmpty == false 
                     ? appViewModel.currentUser!.personalBio 
                     : String(localized: "profile.no_bio_yet", defaultValue: "No bio added yet. Tell the network about yourself."))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            profileSection(title: String(localized: "profile.contact", defaultValue: "Contact")) {
                profileInfoRow(icon: "envelope.fill", label: String(localized: "profile.email", defaultValue: "Email"), value: appViewModel.currentUser?.email ?? String(localized: "profile.no_email", defaultValue: "No Email"), showDivider: false)
            }
        }
    }
    
    var companyContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            profileSection(title: String(localized: "profile.about_company", defaultValue: "About Company")) {
                Text(appViewModel.companyProfile?.companyBio.isEmpty == false
                     ? appViewModel.companyProfile!.companyBio
                     : String(localized: "profile.no_company_description", defaultValue: "No company description added yet."))
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            profileSection(title: String(localized: "profile.headquarters", defaultValue: "Headquarters")) {
                profileInfoRow(icon: "mappin.and.ellipse", label: String(localized: "profile.location", defaultValue: "Location"), value: "\(appViewModel.companyProfile?.hqCity ?? "San Francisco"), \(appViewModel.companyProfile?.hqCountry ?? "USA")")
                profileInfoRow(icon: "globe", label: String(localized: "profile.website", defaultValue: "Website"), value: appViewModel.companyProfile?.website ?? "endeavor.tech", showDivider: false)
            }

            profileSection(title: String(localized: "profile.details", defaultValue: "Details")) {
                profileInfoRow(icon: "building.2.fill", label: String(localized: "profile.company", defaultValue: "Company"), value: appViewModel.companyProfile?.name ?? "Endeavor Technologies")
                profileInfoRow(icon: "briefcase.fill", label: String(localized: "profile.industry", defaultValue: "Industry"), value: appViewModel.companyProfile?.industries.first ?? "Technology / AI")
                profileInfoRow(icon: "person.3.fill", label: String(localized: "profile.team_size", defaultValue: "Team Size"), value: appViewModel.companyProfile?.employeeRange ?? "25-50 employees")
                profileInfoRow(icon: "chart.line.uptrend.xyaxis", label: String(localized: "profile.stage", defaultValue: "Stage"), value: appViewModel.companyProfile?.stage ?? "Series A", showDivider: false)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}
