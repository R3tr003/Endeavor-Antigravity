import SwiftUI

struct CompanyBioLogoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
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
                    Text("Company Bio & Logo")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Bring your company to life. Share your mission and brand.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 24) {
                    // Logo Upload
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
                            Text("Upload Logo")
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
