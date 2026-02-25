import SwiftUI
import PhotosUI
import SDWebImageSwiftUI

struct CompanyBioLogoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    /// If true, hide the image upload section (for Google users with existing profile image)
    var hideImageUpload: Bool = false
    
    // Focus State
    @FocusState private var isFocusedPersonalBio: Bool
    @FocusState private var isFocusedCompanyBio: Bool
    
    // Photo Picker State
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var showPhotoLibrary: Bool = false
    @State private var showCamera: Bool = false
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { 
                    isFocusedPersonalBio = false
                    isFocusedCompanyBio = false
                }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text(hideImageUpload ? "Company Bio & Profile" : "Company Bio & Logo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(hideImageUpload ? "Share your mission and what makes your company unique." : "Bring your company to life. Share your mission and brand.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: DesignSystem.Spacing.large) {
                // Logo Upload or Profile Picture Display
                if !hideImageUpload {
                    VStack(spacing: DesignSystem.Spacing.standard) {
                        // Show selected image or placeholder
                        if let selectedImage = selectedImage {
                            selectedImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(Color.primary.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                )
                        }
                        
                        Menu {
                            Button(action: { showCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button(action: { showPhotoLibrary = true }) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Text("Upload Image")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 160)
                                .padding(.vertical, DesignSystem.Spacing.small)
                                .background(Color.brandPrimary)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        
                        Text("PNG, JPG, SVG up to 5MB.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhoto, matching: .images)
                    .fullScreenCover(isPresented: $showCamera) {
                        ImagePicker(image: $viewModel.selectedProfileImage, sourceType: .camera)
                            .ignoresSafeArea()
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                viewModel.selectedProfileImage = uiImage
                                selectedImage = Image(uiImage: uiImage)
                                viewModel.user.profileImageUrl = "pending_upload"
                            }
                        }
                    }
                    .onChange(of: viewModel.selectedProfileImage) { _, newValue in
                        if let uiImage = newValue {
                            selectedImage = Image(uiImage: uiImage)
                            viewModel.user.profileImageUrl = "pending_upload"
                        }
                    }
                } else {
                    // Show existing Google Profile Image
                    VStack(spacing: DesignSystem.Spacing.standard) {
                        WebImage(url: URL(string: viewModel.user.profileImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                        } placeholder: {
                            ZStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(.gray)
                                ProgressView()
                            }
                        }
                        
                        Text("Using your Google Profile Picture")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                }
                
                // About You (Personal Bio)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("About You")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(isFocusedPersonalBio ? .brandPrimary : .secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $viewModel.user.personalBio)
                            .font(.body)
                            .foregroundColor(.primary)
                            .scrollContentBackground(.hidden) // Needed for custom background in SwiftUI
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .frame(height: 100) // approx 4 lines
                            .focused($isFocusedPersonalBio)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(isFocusedPersonalBio ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("\(viewModel.user.personalBio.count)/300")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(DesignSystem.Spacing.xSmall)
                    }
                    .onChange(of: viewModel.user.personalBio) { _, newValue in
                        if newValue.count > 300 {
                            viewModel.user.personalBio = String(newValue.prefix(300))
                        }
                    }
                }
                
                // About the Company
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("About the Company")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(isFocusedCompanyBio ? .brandPrimary : .secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $viewModel.company.companyBio)
                            .font(.body)
                            .foregroundColor(.primary)
                            .scrollContentBackground(.hidden)
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                            .frame(height: 180) // approx 8 lines
                            .focused($isFocusedCompanyBio)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(isFocusedCompanyBio ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("\(viewModel.company.companyBio.count)/1000")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(DesignSystem.Spacing.xSmall)
                    }
                    .onChange(of: viewModel.company.companyBio) { _, newValue in
                        if newValue.count > 1000 {
                            viewModel.company.companyBio = String(newValue.prefix(1000))
                        }
                    }
                }
            }
            }
            .padding(.bottom, 20)
        }
    }
}

struct CompanyBioLogoView_Previews: PreviewProvider {
    static var previews: some View {
        CompanyBioLogoView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
