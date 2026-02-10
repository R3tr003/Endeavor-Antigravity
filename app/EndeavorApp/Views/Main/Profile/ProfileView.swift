import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedTab: String = "Personal"
    @State private var showCamera: Bool = false
    @State private var showPhotoLibrary: Bool = false
    @State private var profileImage: UIImage? = nil
    @State private var showSettings: Bool = false
    
    var body: some View {
        StackNavigationView {
            mainContent
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
                appViewModel.updateProfileImage(image)
            }
        }
        .overlay(loadingOverlay)
    }
    
    var profileHeader: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                // Profile Avatar with + button or tap menu
                ZStack(alignment: .bottomTrailing) {
                    if let profileImage = profileImage {
                        // Show locally selected photo
                        Menu {
                            Button(action: { showPhotoLibrary = true }) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                            Button(action: { showCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button(role: .destructive, action: { self.profileImage = nil }) {
                                Label("Remove Photo", systemImage: "trash")
                            }
                        } label: {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                        }
                    } else {
                        if let profileUrl = appViewModel.currentUser?.profileImageUrl, !profileUrl.isEmpty {
                            // Show remote profile image
                            Menu {
                                Button(action: { showPhotoLibrary = true }) {
                                    Label("Change Photo", systemImage: "photo.on.rectangle")
                                }
                                Button(action: { showCamera = true }) {
                                    Label("Take Photo", systemImage: "camera")
                                }
                            } label: {
                                AsyncImage(url: URL(string: profileUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().frame(width: 80, height: 80)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .frame(width: 80, height: 80)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        } else {
                            // Default silhouette
                            Circle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    VStack(spacing: 0) {
                                        Circle()
                                            .fill(Color.textSecondary.opacity(0.5))
                                            .frame(width: 28, height: 28)
                                            .offset(y: 4)
                                        
                                        Ellipse()
                                            .fill(Color.textSecondary.opacity(0.5))
                                            .frame(width: 48, height: 28)
                                            .offset(y: -2)
                                    }
                                )
                                .clipShape(Circle())
                        }
                    }
                    
                    // + Button - only show when no photo (local or remote)
                    if profileImage == nil && (appViewModel.currentUser?.profileImageUrl.isEmpty ?? true) {
                        Menu {
                            Button(action: { showCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button(action: { showPhotoLibrary = true }) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.brandPrimary)
                                    .frame(width: 26, height: 26)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: 2, y: 2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appViewModel.currentUser?.fullName ?? "User Profile")
                        .font(.branding.sectionTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(appViewModel.currentUser?.role ?? "Founder") at \(appViewModel.companyProfile?.name ?? "Endeavor")")
                        .font(.branding.inputLabel)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(24)
            
            // Tabs
            HStack(spacing: 0) {
                profileTab(title: "Personal")
                profileTab(title: "Company")
                profileTab(title: "Focus")
            }
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(Color.textSecondary.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
    
    var mainContent: some View {
        VStack(spacing: 0) {
            profileHeader
            scrollViewContent
        }
    }

    var scrollViewContent: some View {
        ScrollView {
            VStack {
                if selectedTab == "Personal" {
                    personalContent
                } else if selectedTab == "Company" {
                    companyContent
                } else {
                    focusContent
                }
            }
            .padding(24)
            .padding(.bottom, 80)
        }
    }

    var loadingOverlay: some View {
        Group {
            if appViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Uploading...")
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    func profileTab(title: String) -> some View {
        Button(action: { selectedTab = title }) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.branding.body.weight(selectedTab == title ? .bold : .regular))
                    .foregroundColor(selectedTab == title ? .textPrimary : .textSecondary)
                
                Rectangle()
                    .fill(selectedTab == title ? Color.brandPrimary : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var personalContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            profileSection(title: "ABOUT") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appViewModel.currentUser?.personalBio.isEmpty == false 
                         ? appViewModel.currentUser!.personalBio 
                         : "No bio added yet.")
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                }
            }
            
            profileSection(title: "CONTACT") {
                VStack(spacing: 16) {
                    profileInfoRow(icon: "envelope.fill", label: "Email", value: appViewModel.currentUser?.email ?? "No Email")
                }
            }
        }
    }
    
    var companyContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            profileSection(title: "HEADQUARTERS") {
                VStack(spacing: 16) {
                    profileInfoRow(icon: "mappin.circle.fill", label: "Location", value: "\(appViewModel.companyProfile?.hqCity ?? "San Francisco"), \(appViewModel.companyProfile?.hqCountry ?? "USA")")
                    profileInfoRow(icon: "globe", label: "Website", value: appViewModel.companyProfile?.website ?? "endeavor.tech")
                }
            }
            
            profileSection(title: "COMPANY INFO") {
                VStack(spacing: 16) {
                    profileInfoRow(icon: "building.2.fill", label: "Company", value: appViewModel.companyProfile?.name ?? "Endeavor Technologies")
                    profileInfoRow(icon: "briefcase.fill", label: "Industry", value: appViewModel.companyProfile?.industries.first ?? "Technology / AI")
                    profileInfoRow(icon: "person.3.fill", label: "Team Size", value: appViewModel.companyProfile?.employeeRange ?? "25-50 employees")
                    profileInfoRow(icon: "chart.line.uptrend.xyaxis", label: "Stage", value: appViewModel.companyProfile?.stage ?? "Series A")
                }
            }
            
            profileSection(title: "ABOUT COMPANY") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(appViewModel.companyProfile?.companyBio.isEmpty == false 
                         ? appViewModel.companyProfile!.companyBio 
                         : "No company description added yet.")
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                }
            }
        }
    }
    
    var focusContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            profileSection(title: "CURRENT CHALLENGES") {
                VStack(alignment: .leading, spacing: 12) {
                    let challenges = appViewModel.companyProfile?.challenges ?? ["Scaling Operations", "Finding Product-Market Fit", "Building Team Culture"]
                    ForEach(challenges, id: \.self) { challenge in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.brandPrimary)
                                .frame(width: 8, height: 8)
                            
                            Text(challenge)
                                .font(.branding.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer() // Force left alignment
                        }
                    }
                }
            }
            
            profileSection(title: "DESIRED EXPERTISE") {
                VStack(alignment: .leading, spacing: 12) {
                    let expertise = appViewModel.companyProfile?.desiredExpertise ?? ["Growth Strategy", "Fundraising", "Technical Architecture"]
                    ForEach(expertise, id: \.self) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.brandPrimary)
                            
                            Text(item)
                                .font(.branding.body)
                                .foregroundColor(.textPrimary)
                            
                            Spacer() // Force left alignment
                        }
                    }
                }
            }
        }
    }
    
    func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.branding.inputLabel)
                .foregroundColor(.textSecondary)
            
            content()
        }
    }
    
    func profileInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.brandPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.branding.inputLabel)
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(.branding.body)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}
