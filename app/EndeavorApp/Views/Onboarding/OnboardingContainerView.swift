import SwiftUI
import SDWebImageSwiftUI
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasInitialized = false
    @State private var showExitConfirmation = false
    
    // Ambient animation
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Immersive Background matching WelcomeView
            Color.background.edgesIgnoringSafeArea(.all)
            
            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.3))
                        .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                        .blur(radius: 120)
                        .offset(x: animateBackground ? -100 : 100, y: animateBackground ? -200 : -100)
                    
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.15)) // Fallback to safe color if missing
                        .frame(width: proxy.size.width * 1.2, height: proxy.size.width * 1.2)
                        .blur(radius: 100)
                        .offset(x: animateBackground ? 100 : -50, y: animateBackground ? 200 : 50)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        animateBackground = true
                    }
                }
            }
            .ignoresSafeArea()
            
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
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        } placeholder: {
                            ZStack {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                                Circle().fill(Color.white.opacity(0.2)).frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
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
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.Spacing.xLarge, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Spacing.xLarge, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.bottom, DesignSystem.Spacing.bottomSafePadding) // Space for bottom bar
                    .frame(maxWidth: .infinity)
                }
            }
            .opacity(hasInitialized ? 1 : 0) // Fade in when ready
            .onAppear {
                syncUserData()
                withAnimation(.easeIn(duration: 0.4)) {
                    hasInitialized = true
                }
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
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        if viewModel.currentStep == viewModel.totalSteps {
                            viewModel.clearDraft()
                            appViewModel.completeOnboarding(user: viewModel.user, company: viewModel.company, profileImage: viewModel.selectedProfileImage)
                        } else {
                            if viewModel.currentStep == 1 {
                                // Explicitly handle Step 1 transition validation logic if needed
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.nextStep()
                            }
                        }
                    }) {
                        Text(viewModel.currentStep == viewModel.totalSteps ? "Enter App" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, DesignSystem.Spacing.xLarge)
                            .background(isNextEnabled ? Color.brandPrimary : Color.primary.opacity(0.2))
                            .clipShape(Capsule())
                            .shadow(color: isNextEnabled ? Color.brandPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isNextEnabled)
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
