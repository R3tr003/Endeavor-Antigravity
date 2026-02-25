import SwiftUI

struct CompanyBasicsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isWebsiteValid: Bool = true
    
    @FocusState private var focusName: Bool
    @FocusState private var focusWebsite: Bool
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    focusName = false
                    focusWebsite = false
                }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text("Company Basics")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Tell us about the amazing company you're building.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: DesignSystem.Spacing.standard) {
                CustomTextField(title: "Company Name", placeholder: "Enter company name", text: $viewModel.company.name, isFocused: $focusName, isRequired: true)
                    .submitLabel(.next)
                    .onSubmit {
                        focusWebsite = true
                    }
                
                CustomTextField(title: "Website", placeholder: "https://example.com", text: $viewModel.company.website, isFocused: $focusWebsite, isRequired: false, keyboardType: .URL)
                    .submitLabel(.done)
                    .onSubmit {
                        focusWebsite = false
                        if viewModel.isStep2Valid {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.currentStep += 1
                            }
                        }
                    }
                .onChange(of: viewModel.company.website) { _, newValue in
                    isWebsiteValid = newValue.isEmpty || isValidURL(newValue)
                }
                
                if !isWebsiteValid {
                    HStack {
                        Text("Enter a valid URL starting with https:// or http://")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.top, -8)
                }
                
                // HQ Country Dropdown
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("HQ Country")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    Menu {
                        ForEach(viewModel.availableCountries, id: \.self) { country in
                            Button(country) {
                                viewModel.company.hqCountry = country
                                // Reset city when country changes
                                viewModel.company.hqCity = ""
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.company.hqCountry.isEmpty ? "Select a country" : viewModel.company.hqCountry)
                                .foregroundColor(viewModel.company.hqCountry.isEmpty ? .secondary.opacity(0.5) : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .transaction { $0.animation = nil }
                }
                
                // HQ City Dropdown (filtered by selected country)
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("HQ City")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    Menu {
                        if viewModel.company.hqCountry.isEmpty {
                            Button("Select a country first", action: {})
                        } else {
                            ForEach(viewModel.citiesForCountry(viewModel.company.hqCountry), id: \.self) { city in
                                Button(city) {
                                    viewModel.company.hqCity = city
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.company.hqCity.isEmpty ? "Select a city" : viewModel.company.hqCity)
                                .foregroundColor(viewModel.company.hqCity.isEmpty ? .secondary.opacity(0.5) : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .transaction { $0.animation = nil }
                    .disabled(viewModel.company.hqCountry.isEmpty)
                }
                
                // Industry Multi-Select
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Industry (select up to 3)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    FlowLayout(spacing: DesignSystem.Spacing.xSmall) {
                        ForEach(viewModel.availableIndustries, id: \.self) { industry in
                            SelectablePill(
                                title: industry,
                                isSelected: viewModel.company.industries.contains(industry),
                                action: { viewModel.toggleIndustry(industry) }
                            )
                        }
                    }
                }
                
                // Company Stage Dropdown
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Company Stage")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    Menu {
                        ForEach(viewModel.availableStages, id: \.self) { stage in
                            Button(stage, action: { viewModel.company.stage = stage })
                        }
                    } label: {
                        HStack {
                            Text(viewModel.company.stage.isEmpty ? "Select a stage" : viewModel.company.stage)
                                .foregroundColor(viewModel.company.stage.isEmpty ? .secondary.opacity(0.5) : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .transaction { $0.animation = nil }
                }
                
                // Employee Range Dropdown
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                     HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Number of Employees")
                             .font(.subheadline.weight(.medium))
                             .foregroundColor(.secondary)
                         Text("*")
                             .font(.subheadline.weight(.bold))
                             .foregroundColor(.red)
                    }
                    
                    Menu {
                        ForEach(viewModel.availableEmployeeRanges, id: \.self) { range in
                            Button(range, action: { viewModel.company.employeeRange = range })
                        }
                    } label: {
                        HStack {
                            Text(viewModel.company.employeeRange.isEmpty ? "Select a range" : viewModel.company.employeeRange)
                                .foregroundColor(viewModel.company.employeeRange.isEmpty ? .secondary.opacity(0.5) : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .transaction { $0.animation = nil }
                }
            }
            }
            .padding(.bottom, 20)
        }
    }
    
    /// Validates URL format - requires http:// or https:// prefix
    private func isValidURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Must start with http:// or https://
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else {
            return false
        }
        
        // Must have at least one dot for a domain
        guard trimmed.contains(".") else { return false }
        
        // Check if it can be parsed as URL with valid host
        guard let url = URL(string: trimmed),
              let host = url.host,
              host.contains(".") else {
            return false
        }
        
        // Basic domain validation (at least 2 chars after last dot)
        let parts = host.split(separator: ".")
        if let lastPart = parts.last, lastPart.count < 2 {
            return false
        }
        
        return true
    }
}

struct CompanyBasicsView_Previews: PreviewProvider {
    static var previews: some View {
        CompanyBasicsView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}

