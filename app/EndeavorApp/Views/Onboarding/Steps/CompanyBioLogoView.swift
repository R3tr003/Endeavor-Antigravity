import SwiftUI

struct CompanyBioLogoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    /// If true, hide the image upload section (for Google users with existing profile image)
    var hideImageUpload: Bool = false
    
    // Focus State
    enum Field {
        case shortDescription
        case longDescription
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(hideImageUpload ? "Company Bio & Profile" : "Company Bio & Logo")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text(hideImageUpload ? "Share your mission and what makes your company unique." : "Bring your company to life. Share your mission and brand.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 24) {
                    // Logo Upload or Profile Picture Display
                    if !hideImageUpload {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.inputBackground)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textSecondary)
                                )
                            
                            Button(action: {
                                // Placeholder upload action
                            }) {
                                Text("Upload Image")
                                    .font(.branding.inputLabel.weight(.bold))
                                    .foregroundColor(.background)
                                    .frame(width: 160)
                                    .padding(.vertical, 12)
                                    .background(Color.brandPrimary)
                                    .cornerRadius(12)
                            }
                            
                            Text("PNG, JPG, SVG up to 5MB.")
                                .font(.branding.caption)
                                .foregroundColor(.textSecondary)
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
                                .font(.branding.caption)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                    
                    // Short Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Short Description (Elevator Pitch)")
                                .font(.branding.inputLabel)
                                .foregroundColor(focusedField == .shortDescription ? .brandPrimary : .textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        ZStack(alignment: .bottomTrailing) {
                            TextEditor(text: $viewModel.company.shortDescription)
                                .font(.branding.body)
                                .foregroundColor(.textPrimary)
                                .scrollContentBackground(.hidden) // Needed for custom background in SwiftUI
                                .background(Color.inputBackground)
                                .cornerRadius(12)
                                .frame(height: 100) // approx 4 lines
                                .focused($focusedField, equals: .shortDescription)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .shortDescription ? Color.brandPrimary : Color.clear, lineWidth: 1)
                                )
                            
                            Text("\(viewModel.company.shortDescription.count)/300")
                                .font(.branding.caption)
                                .foregroundColor(.textSecondary)
                                .padding(8)
                        }
                    }
                    
                    // Long Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Long Description")
                                .font(.branding.inputLabel)
                                .foregroundColor(focusedField == .longDescription ? .brandPrimary : .textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        ZStack(alignment: .bottomTrailing) {
                            TextEditor(text: $viewModel.company.longDescription)
                                .font(.branding.body)
                                .foregroundColor(.textPrimary)
                                .scrollContentBackground(.hidden)
                                .background(Color.inputBackground)
                                .cornerRadius(12)
                                .frame(height: 180) // approx 8 lines
                                .focused($focusedField, equals: .longDescription)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .longDescription ? Color.brandPrimary : Color.clear, lineWidth: 1)
                                )
                            
                            Text("\(viewModel.company.longDescription.count)/1000")
                                .font(.branding.caption)
                                .foregroundColor(.textSecondary)
                                .padding(8)
                        }
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
