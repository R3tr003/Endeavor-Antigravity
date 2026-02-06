import SwiftUI

struct FocusView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Help us understand your priorities to suggest the best resources.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                VStack(spacing: 24) {
                    // Challenges
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Your Top 3 Challenges")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.availableChallenges, id: \.self) { challenge in
                                SelectablePill(
                                    title: challenge,
                                    isSelected: viewModel.company.challenges.contains(challenge),
                                    action: { viewModel.toggleChallenge(challenge) }
                                )
                            }
                        }
                    }
                    
                    // Desired Expertise
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Desired Mentor Expertise")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("*")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.availableExpertise, id: \.self) { expertise in
                                SelectablePill(
                                    title: expertise,
                                    isSelected: viewModel.company.desiredExpertise.contains(expertise),
                                    action: { viewModel.toggleExpertise(expertise) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FocusView_Previews: PreviewProvider {
    static var previews: some View {
        FocusView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
