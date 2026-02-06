import SwiftUI

struct PersonalInformationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Information")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Let's start with the basics. This helps others get to know you.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(spacing: 16) {
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
                    
                    CustomTextField(
                        title: "Role / Title",
                        placeholder: "e.g., CEO, Founder, CTO",
                        text: $viewModel.user.role,
                        isRequired: true
                    )
                }
                .onAppear {
                    // Auto-detect timezone from device
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
