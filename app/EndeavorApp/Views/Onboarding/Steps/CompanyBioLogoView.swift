import SwiftUI
import PhotosUI

struct CompanyBioLogoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    /// If true, hide the image upload section (for Google users with existing profile image)
    var hideImageUpload: Bool = false
    
    // Focus State
    enum Field {
        case personalBio
        case companyBio
    }
    @FocusState private var focusedField: Field?
    
    // Photo Picker State
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var showPhotoLibrary: Bool = false
    @State private var showCamera: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(hideImageUpload ? "Company Bio & Profile" : "Company Bio & Logo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(hideImageUpload ? "Share your mission and what makes your company unique." : "Bring your company to life. Share your mission and brand.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 24) {
                // Logo Upload or Profile Picture Display
                if !hideImageUpload {
                    VStack(spacing: 16) {
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
                                .padding(.vertical, 12)
                                .background(Color.brandPrimary)
                                .cornerRadius(12)
                        }
                        
                        Text("PNG, JPG, SVG up to 5MB.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedPhoto, matching: .images)
                    .fullScreenCover(isPresented: $showCamera) {
                        ImagePicker(image: $selectedUIImage, sourceType: .camera)
                            .ignoresSafeArea()
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedUIImage = uiImage
                                selectedImage = Image(uiImage: uiImage)
                                viewModel.user.profileImageUrl = "pending_upload"
                            }
                        }
                    }
                    .onChange(of: selectedUIImage) { _, newValue in
                        if let uiImage = newValue {
                            selectedImage = Image(uiImage: uiImage)
                            viewModel.user.profileImageUrl = "pending_upload"
                        }
                    }
                } else {
                    // Show existing Google Profile Image
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: viewModel.user.profileImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 120, height: 120)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 120))
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        Text("Using your Google Profile Picture")
                            .font(.caption)
                            .foregroundColor(.brandPrimary)
                    }
                }
                
                // About You (Personal Bio)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("About You")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(focusedField == .personalBio ? .brandPrimary : .secondary)
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
                            .cornerRadius(12)
                            .frame(height: 100) // approx 4 lines
                            .focused($focusedField, equals: .personalBio)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .personalBio ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("\(viewModel.user.personalBio.count)/300")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                
                // About the Company
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("About the Company")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(focusedField == .companyBio ? .brandPrimary : .secondary)
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
                            .cornerRadius(12)
                            .frame(height: 180) // approx 8 lines
                            .focused($focusedField, equals: .companyBio)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .companyBio ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: 1)
                            )
                        
                        Text("\(viewModel.company.companyBio.count)/1000")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
            }
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
