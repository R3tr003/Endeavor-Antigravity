import SwiftUI
import SDWebImageSwiftUI
struct OnboardingContainerView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showExitConfirmation = false
    
    

    
    var body: some View {
        ZStack {
            // Immersive Animated Background
            FluidBackgroundView()
            
            
            VStack(spacing: 0) {
                // Modern Header
                HStack(spacing: DesignSystem.Spacing.small) {
                    if !viewModel.user.profileImageUrl.isEmpty {
                        WebImage(url: URL(string: viewModel.user.profileImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.borderGlare.opacity(0.3), lineWidth: 1))
                        } placeholder: {
                            ZStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(Color.borderGlare.opacity(0.5))
                                    .frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                                Circle().fill(Color.borderGlare.opacity(0.2)).frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .foregroundColor(.primary)
                            .frame(width: DesignSystem.IconSize.large, height: DesignSystem.IconSize.large)
                    }
                    
                    Text("Setup Profile")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.top, DesignSystem.Spacing.standard)
                .padding(.bottom, DesignSystem.Spacing.standard)
                
                // Progress Bar - animated only for step changes
                LinearProgressView(
                    progress: Double(viewModel.currentStep) / Double(viewModel.totalSteps),
                    color: .brandPrimary,
                    trackColor: Color.primary.opacity(0.1),
                    height: 5
                )
                .clipShape(Capsule())
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.large)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
                
                // Content mapped inside a floating panel
                ScrollView(showsIndicators: false) {
                    VStack {
                        stepContent
                    }
                    .padding(DesignSystem.Spacing.large)
                    .modifier(LiquidGlassEffect(cornerRadius: DesignSystem.Spacing.xLarge))
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.bottomSafePadding) // Space for bottom bar
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                syncUserData()
            }
            .onChange(of: appViewModel.currentUser?.id) { _, _ in
                syncUserData()
            }
            
            // Floating Bottom Navigation
            VStack {
                Spacer()
                HStack {
                    if viewModel.currentStep > 1 {
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.previousStep()
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }
                    } else {
                        // Exit Button for Step 1
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            AnalyticsService.shared.logOnboardingAbandoned(atStep: viewModel.currentStep)
                            withAnimation {
                                showExitConfirmation = true
                            }
                        }) {
                            Text("Exit")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.red.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if appViewModel.isLoading { return }

                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if viewModel.currentStep == viewModel.totalSteps {
                            viewModel.clearDraft()
                            appViewModel.completeOnboarding(user: viewModel.user, company: viewModel.company, profileImage: viewModel.selectedProfileImage)
                        } else {
                            if viewModel.currentStep == 1 {
                                // Explicitly handle Step 1 transition validation logic if needed
                            }
                            // Track step completion
                            AnalyticsService.shared.logOnboardingStepCompleted(
                                step: viewModel.currentStep,
                                stepName: stepName(for: viewModel.currentStep)
                            )
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.nextStep()
                            }
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.small) {
                            if appViewModel.isLoading && viewModel.currentStep == viewModel.totalSteps {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.currentStep == viewModel.totalSteps ? (appViewModel.isLoading ? "Entering..." : "Enter App") : "Next")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, DesignSystem.Spacing.xLarge)
                        .background(!isNextEnabled || appViewModel.isLoading ? Color.primary.opacity(0.2) : Color.brandPrimary)
                        .clipShape(Capsule())
                        .shadow(color: !isNextEnabled || appViewModel.isLoading ? .clear : Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isNextEnabled || appViewModel.isLoading)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .background(
                    LinearGradient(colors: [.background, .background.opacity(0)], startPoint: .bottom, endPoint: .top)
                        .ignoresSafeArea()
                )
            }
        }
        .alert("Are you sure to Exit the registration process?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                appViewModel.logout()
            }
        }
        .onAppear {
            viewModel.loadDraft()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.saveDraft()
            }
        }
    }
    
    private func syncUserData() {
        if let currentUser = appViewModel.currentUser {
            // Sync fields — but do NOT modify isSocialLogin here.
            // isSocialLogin is set by handleAuthSuccess based on the actual Firebase Auth provider.
            if !currentUser.firstName.isEmpty {
                if viewModel.user.firstName.isEmpty {
                    viewModel.user.firstName = currentUser.firstName
                }
            }
            if !currentUser.lastName.isEmpty {
                if viewModel.user.lastName.isEmpty {
                    viewModel.user.lastName = currentUser.lastName
                }
            }
            if !currentUser.email.isEmpty {
                if viewModel.user.email.isEmpty {
                    viewModel.user.email = currentUser.email
                }
            }
            // Only sync profile image if it belongs to the same user (prevents cross-user leaks)
            if !currentUser.profileImageUrl.isEmpty
                && currentUser.email.lowercased() == viewModel.user.email.lowercased() {
                if viewModel.user.profileImageUrl.isEmpty {
                    viewModel.user.profileImageUrl = currentUser.profileImageUrl
                }
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            PersonalInformationView(viewModel: viewModel)
        case 2:
            CompanyBasicsView(viewModel: viewModel)
        case 3:
            CompanyBioLogoView(viewModel: viewModel, hideImageUpload: viewModel.isSocialLogin && !viewModel.user.profileImageUrl.isEmpty)
        case 4:
            ReviewFinishView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }
    
    var isNextEnabled: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.isStep1Valid
        case 2: return viewModel.isStep2Valid
        case 3: return viewModel.isStep3Valid
        case 4: return true
        default: return false
        }
    }
    
    private func stepName(for step: Int) -> String {
        switch step {
        case 1: return "personal_information"
        case 2: return "company_basics"
        case 3: return "company_bio_logo"
        case 4: return "review_finish"
        default: return "unknown"
        }
    }
}



struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        let appVM = AppViewModel()
        OnboardingContainerView()
            .environmentObject(appVM)
            .environmentObject(appVM.onboardingViewModel)
    }
}
