import SwiftUI
import SDWebImageSwiftUI
struct PersonalInformationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @FocusState private var focusFirstName: Bool
    @FocusState private var focusLastName: Bool
    @FocusState private var focusRole: Bool
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    focusFirstName = false
                    focusLastName = false
                    focusRole = false
                }
                
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
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
            
            VStack(spacing: DesignSystem.Spacing.standard) {
                if viewModel.isSocialLogin {
                    // Social Login Mode: Show Profile Pic & Hidden Name Fields
                    if !viewModel.user.profileImageUrl.isEmpty,
                       let url = URL(string: viewModel.user.profileImageUrl) {
                        HStack(spacing: DesignSystem.Spacing.standard) {
                            WebImage(url: url) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.fill")
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.brandPrimary, lineWidth: 2))
                            
                            Text("Using your Google Profile Picture")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.bottom, DesignSystem.Spacing.xSmall)
                    }
                } else {
                    // Regular Mode: Show Name Fields
                    CustomTextField(title: "First Name", placeholder: "Enter your first name", text: $viewModel.user.firstName, isFocused: $focusFirstName, isRequired: true)
                        .submitLabel(.next)
                        .onSubmit { focusLastName = true }
                    
                    CustomTextField(title: "Last Name", placeholder: "Enter your last name", text: $viewModel.user.lastName, isFocused: $focusLastName, isRequired: true)
                        .submitLabel(.next)
                        .onSubmit { focusRole = true }
                }
                
                CustomTextField(title: "Role / Title", placeholder: "e.g., CEO, Founder, CTO", text: $viewModel.user.role, isFocused: $focusRole, isRequired: true)
                    .submitLabel(.done)
                    .onSubmit {
                        focusRole = false
                        if viewModel.isStep1Valid {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.currentStep += 1
                            }
                        }
                    }
            }
            .onAppear {
                // Auto-detect timezone from device
                if viewModel.user.timeZone.isEmpty {
                    viewModel.user.timeZone = TimeZone.current.identifier
                }
            }
            }
            .padding(.bottom, 20)
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
