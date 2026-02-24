import SwiftUI

struct FocusView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text("Focus")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Help us understand your priorities to suggest the best resources.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: DesignSystem.Spacing.large) {
                // Challenges
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Your Top 3 Challenges")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    FlowLayout(spacing: DesignSystem.Spacing.xSmall) {
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
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack(spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Desired Mentor Expertise")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("*")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.red)
                    }
                    
                    FlowLayout(spacing: DesignSystem.Spacing.xSmall) {
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

struct FocusView_Previews: PreviewProvider {
    static var previews: some View {
        FocusView(viewModel: OnboardingViewModel())
            .padding()
            .background(Color.background)
    }
}
