import SwiftUI

struct ReviewFinishView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var isPersonalExpanded: Bool = true
    @State private var isCompanyExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text(String(localized: "onboarding.review_finish", defaultValue: "Review & Finish"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(String(localized: "onboarding.review_desc", defaultValue: "Please review your information below. You can edit any section before completing your profile."))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 0) {
                // Personal Information Config
                VStack(spacing: 0) {
                    Button(action: { withAnimation { isPersonalExpanded.toggle() } }) {
                        HStack {
                            Text(String(localized: "onboarding.personal_info", defaultValue: "Personal Information"))
                                .font(.system(size: 18, weight: .bold)) // 18pt bold
                                .foregroundColor(.primary)
                            Spacer()
                            Text(isPersonalExpanded ? String(localized: "common.collapse", defaultValue: "Collapse") : String(localized: "common.expand", defaultValue: "Expand"))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.brandPrimary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.small)
                    }
                    
                    if isPersonalExpanded {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            reviewRow(label: String(localized: "profile.full_name", defaultValue: "Full Name"), value: viewModel.user.fullName)
                            reviewRow(label: String(localized: "profile.role", defaultValue: "Role"), value: viewModel.user.role)
                            reviewRow(label: String(localized: "profile.email", defaultValue: "Email"), value: viewModel.user.email)
                            reviewRow(label: String(localized: "profile.location", defaultValue: "Location"), value: "\(viewModel.company.hqCountry), \(viewModel.company.hqCity)")
                        }
                        .padding(.bottom, DesignSystem.Spacing.large)
                    }
                }
                
                Divider().background(Color.secondary.opacity(0.3))
                
                // Company Information Config
                VStack(spacing: 0) {
                    Button(action: { withAnimation { isCompanyExpanded.toggle() } }) {
                        HStack {
                            Text(String(localized: "profile.company_info", defaultValue: "Company Information"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(isCompanyExpanded ? String(localized: "common.collapse", defaultValue: "Collapse") : String(localized: "common.expand", defaultValue: "Expand"))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.brandPrimary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.small)
                    }
                    
                    if isCompanyExpanded {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            reviewRow(label: String(localized: "profile.company_name", defaultValue: "Company Name"), value: viewModel.company.name)
                            reviewRow(label: String(localized: "profile.website", defaultValue: "Website"), value: viewModel.company.website)
                            reviewRow(label: String(localized: "profile.industry", defaultValue: "Industry"), value: viewModel.company.industries.joined(separator: ", "))
                            reviewRow(label: String(localized: "profile.stage", defaultValue: "Stage"), value: viewModel.company.stage)
                        }
                        .padding(.bottom, DesignSystem.Spacing.large)
                    }
                }
            }
        }
    }
    
    func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value.isEmpty ? "-" : value)
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ReviewFinishView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = OnboardingViewModel()
        // vm.user.firstName = "Alex" // REMOVED: Do not overwrite user input
        vm.user.lastName = "Chen"
        vm.company.name = "Endeavor"
        vm.company.website = "https://endeavor.org"
        return ReviewFinishView(viewModel: vm)
            .padding()
            .background(Color.background)
    }
}
