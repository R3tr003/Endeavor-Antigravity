import SwiftUI

struct CompanyBasicsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Company Basics")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Tell us about the amazing company you're building.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Company Name",
                        placeholder: "",
                        text: $viewModel.company.name,
                        isRequired: true
                    )
                    
                    CustomTextField(
                        title: "Company Website",
                        placeholder: "",
                        text: $viewModel.company.website,
                        isRequired: true,
                        keyboardType: .URL
                    )
                    
                    // HQ Country Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("HQ Country")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
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
                                    .foregroundColor(viewModel.company.hqCountry.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(Color.inputBackground)
                            .cornerRadius(12)
                        }
                        .transaction { $0.animation = nil }
                    }
                    
                    // HQ City Dropdown (filtered by selected country)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("HQ City")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
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
                                    .foregroundColor(viewModel.company.hqCity.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(Color.inputBackground)
                            .cornerRadius(12)
                        }
                        .transaction { $0.animation = nil }
                        .disabled(viewModel.company.hqCountry.isEmpty)
                    }
                    
                    // Industry Multi-Select
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Industry (select up to 3)")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        FlowLayout(spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Company Stage")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        Menu {
                            ForEach(viewModel.availableStages, id: \.self) { stage in
                                Button(stage, action: { viewModel.company.stage = stage })
                            }
                        } label: {
                            HStack {
                                Text(viewModel.company.stage.isEmpty ? "Select a stage" : viewModel.company.stage)
                                    .foregroundColor(viewModel.company.stage.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(Color.inputBackground)
                            .cornerRadius(12)
                        }
                        .transaction { $0.animation = nil }
                    }
                    
                    // Employee Range Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                         HStack(spacing: 4) {
                            Text("Number of Employees")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                             Text("*")
                                 .font(.branding.inputLabel)
                                 .foregroundColor(.error)
                        }
                        
                        Menu {
                            ForEach(viewModel.availableEmployeeRanges, id: \.self) { range in
                                Button(range, action: { viewModel.company.employeeRange = range })
                            }
                        } label: {
                            HStack {
                                Text(viewModel.company.employeeRange.isEmpty ? "Select a range" : viewModel.company.employeeRange)
                                    .foregroundColor(viewModel.company.employeeRange.isEmpty ? .textSecondary.opacity(0.5) : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(16)
                            .background(Color.inputBackground)
                            .cornerRadius(12)
                        }
                        .transaction { $0.animation = nil }
                    }
                }
            }
        }
    }
}

struct CompanyBasicsView_Previews: PreviewProvider {
    static var previews: some View {
        CompanyBasicsView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
