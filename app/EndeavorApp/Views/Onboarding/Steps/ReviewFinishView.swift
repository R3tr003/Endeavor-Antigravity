import SwiftUI

struct ReviewFinishView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var isPersonalExpanded: Bool = true
    @State private var isCompanyExpanded: Bool = true
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review & Finish")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Please review your information below. You can edit any section before completing your profile.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 0) {
                    // Personal Information Config
                    VStack(spacing: 0) {
                        Button(action: { withAnimation { isPersonalExpanded.toggle() } }) {
                            HStack {
                                Text("Personal Information")
                                    .font(.system(size: 18, weight: .bold)) // 18pt bold
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(isPersonalExpanded ? "Collapse" : "Expand")
                                    .font(.branding.inputLabel)
                                    .foregroundColor(.brandPrimary)
                            }
                            .padding(.vertical, 12)
                        }
                        
                        if isPersonalExpanded {
                            VStack(alignment: .leading, spacing: 12) {
                                reviewRow(label: "Full Name", value: viewModel.user.fullName)
                                reviewRow(label: "Role", value: viewModel.user.role)
                                reviewRow(label: "Email", value: viewModel.user.email)
                                reviewRow(label: "Location", value: "\(viewModel.company.hqCountry), \(viewModel.company.hqCity)")
                            }
                            .padding(.bottom, 24)
                        }
                    }
                    
                    Divider().background(Color.textSecondary.opacity(0.3))
                    
                    // Company Information Config
                    VStack(spacing: 0) {
                        Button(action: { withAnimation { isCompanyExpanded.toggle() } }) {
                            HStack {
                                Text("Company Information")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Text(isCompanyExpanded ? "Collapse" : "Expand")
                                    .font(.branding.inputLabel)
                                    .foregroundColor(.brandPrimary)
                            }
                            .padding(.vertical, 12)
                        }
                        
                        if isCompanyExpanded {
                            VStack(alignment: .leading, spacing: 12) {
                                reviewRow(label: "Company Name", value: viewModel.company.name)
                                reviewRow(label: "Website", value: viewModel.company.website)
                                reviewRow(label: "Industry", value: viewModel.company.industries.joined(separator: ", "))
                                reviewRow(label: "Stage", value: viewModel.company.stage)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
    }
    
    func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.branding.body)
                .foregroundColor(.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value.isEmpty ? "-" : value)
                .font(.branding.body)
                .foregroundColor(.textPrimary)
            
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
