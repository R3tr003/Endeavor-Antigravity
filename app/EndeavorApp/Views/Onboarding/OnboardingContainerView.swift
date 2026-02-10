import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var hasInitialized = false
    @State private var showExitConfirmation = false
    
    var body: some View {
        ZStack {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        if !viewModel.user.profileImageUrl.isEmpty {
                            AsyncImage(url: URL(string: viewModel.user.profileImageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 32, height: 32)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                case .failure:
                                    Image("ProfileIcon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image("ProfileIcon")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                        Text("Profile")
                            .font(.branding.cardTitle)
                            .foregroundColor(.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Progress Bar - animated only for step changes
                    LinearProgressView(
                        progress: Double(viewModel.currentStep) / Double(viewModel.totalSteps),
                        color: .brandPrimary,
                        trackColor: .cardBackground,
                        height: 4
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .animation(.default, value: viewModel.currentStep)
                    
                    // Content - NO animation for scroll content
                    ScrollView(showsIndicators: false) {
                        stepContent
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100) // Space for bottom bar
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .opacity(hasInitialized ? 1 : 0) // Fade in when ready
            .onAppear {
                syncUserData()
                withAnimation(.easeIn(duration: 0.2)) {
                    hasInitialized = true
                }
            }
            .onChange(of: appViewModel.currentUser?.id) { _, _ in
                syncUserData()
            }
            .overlay(alignment: .bottom) {
                // Bottom Navigation
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack {
                        if viewModel.currentStep > 1 {
                            Button(action: {
                                withAnimation(.default) {
                                    viewModel.previousStep()
                                }
                            }) {
                                Text("Back")
                                    .font(.branding.body)
                                    .foregroundColor(.textSecondary)
                                    .padding()
                            }
                        } else {
                            // Exit Button for Step 1
                            Button(action: {
                                withAnimation {
                                    showExitConfirmation = true
                                }
                            }) {
                                Text("Exit")
                                    .font(.branding.body)
                                    .foregroundColor(.error)
                                    .padding()
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if viewModel.currentStep == viewModel.totalSteps {
                                appViewModel.completeOnboarding(user: viewModel.user, company: viewModel.company)
                            } else {
                                if viewModel.currentStep == 1 {
                                    // Explicitly handle Step 1 transition validation logic if needed
                                }
                                withAnimation(.default) {
                                    viewModel.nextStep()
                                }
                            }
                        }) {
                            Text(viewModel.currentStep == viewModel.totalSteps ? "Finish & Enter App" : "Next")
                                .font(.branding.body.weight(.bold))
                                .foregroundColor(.background)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 32)
                                .background(isNextEnabled ? Color.brandPrimary : Color.cardBackground)
                                .cornerRadius(12)
                        }
                        .disabled(!isNextEnabled)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.background.opacity(0.95))
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .alert("Are you sure to Exit the registration process?", isPresented: $showExitConfirmation) {
            Button("Back", role: .cancel) { }
            Button("Exit", role: .destructive) {
                appViewModel.logout()
            }
        }
    }
    
    private func syncUserData() {
        if let currentUser = appViewModel.currentUser {
            // Check if we already have data (implies Social Login or re-entry)
            
            if !currentUser.firstName.isEmpty {
                if viewModel.user.firstName.isEmpty {
                    viewModel.user.firstName = currentUser.firstName
                }
                viewModel.isSocialLogin = true
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
            
            if !currentUser.profileImageUrl.isEmpty {
                if viewModel.user.profileImageUrl.isEmpty {
                    viewModel.user.profileImageUrl = currentUser.profileImageUrl
                }
                viewModel.isSocialLogin = true
            }
        }
    }
    
    // Extracted to separate computed property to prevent animation inheritance
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case 1:
            PersonalInformationView(viewModel: viewModel)
        case 2:
            CompanyBasicsView(viewModel: viewModel)
        case 3:
            FocusView(viewModel: viewModel)
        case 4:
            CompanyBioLogoView(viewModel: viewModel, hideImageUpload: viewModel.isSocialLogin && !viewModel.user.profileImageUrl.isEmpty)
        case 5:
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
        case 4: return viewModel.isStep4Valid
        case 5: return true
        default: return false
        }
    }
}

struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .environmentObject(AppViewModel())
    }
}
