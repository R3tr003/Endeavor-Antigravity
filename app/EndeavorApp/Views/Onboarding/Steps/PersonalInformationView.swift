import SwiftUI

struct PersonalInformationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Personal Information")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                if viewModel.isSocialLogin {
                    Text("Welcome, \(viewModel.user.firstName)! Please confirm your role.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Let's start with the basics. This helps others get to know you.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            VStack(spacing: 16) {
                if viewModel.isSocialLogin {
                    // Social Login Mode: Show Profile Pic & Hidden Name Fields
                    if !viewModel.user.profileImageUrl.isEmpty,
                       let url = URL(string: viewModel.user.profileImageUrl) {
                        HStack(spacing: 16) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Color.primary.opacity(0.1)
                                case .success(let image):
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "person.fill")
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                            
                            Text("Using your Google Profile Picture")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    // Regular Mode: Show Name Fields
                    CustomTextField(
                        title: "First Name",
                        placeholder: "",
                        text: $viewModel.user.firstName,
                        isRequired: true
                    )
                    
                    CustomTextField(
                        title: "Last Name",
                        placeholder: "",
                        text: $viewModel.user.lastName,
                        isRequired: true
                    )
                }
                
                CustomTextField(
                    title: "Role / Title",
                    placeholder: "e.g., CEO, Founder, CTO",
                    text: $viewModel.user.role,
                    isRequired: true
                )
            }
            .onAppear {
                // Auto-detect timezone from device
                if viewModel.user.timeZone.isEmpty {
                    viewModel.user.timeZone = TimeZone.current.identifier
                }
            }
        }
    }
}

struct PersonalInformationView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalInformationView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
