import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
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
                        .fill(Color("TealDark", bundle: nil).opacity(0.15)) // Fallback to safe color if missing
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
                HStack(spacing: 12) {
                    if !viewModel.user.profileImageUrl.isEmpty {
                        AsyncImage(url: URL(string: viewModel.user.profileImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Circle().fill(Color.white.opacity(0.2)).frame(width: 40, height: 40)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 40, height: 40)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                    
                    Text("Setup Profile")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Progress Bar - animated only for step changes
                LinearProgressView(
                    progress: Double(viewModel.currentStep) / Double(viewModel.totalSteps),
                    color: .brandPrimary,
                    trackColor: Color.primary.opacity(0.1),
                    height: 5
                )
                .clipShape(Capsule())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
                
                // Content mapped inside a floating panel
                ScrollView(showsIndicators: false) {
                    VStack {
                        stepContent
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for bottom bar
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
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.previousStep()
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }
                    } else {
                        // Exit Button for Step 1
                        Button(action: {
                            withAnimation {
                                showExitConfirmation = true
                            }
                        }) {
                            Text("Exit")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.red.opacity(0.2), lineWidth: 1))
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
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.nextStep()
                            }
                        }
                    }) {
                        Text(viewModel.currentStep == viewModel.totalSteps ? "Enter App" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .background(isNextEnabled ? Color.brandPrimary : Color.primary.opacity(0.2))
                            .clipShape(Capsule())
                            .shadow(color: isNextEnabled ? Color.brandPrimary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isNextEnabled)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(colors: [.background, .background.opacity(0)], startPoint: .bottom, endPoint: .top)
                        .ignoresSafeArea()
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .alert("Are you sure to Exit the registration process?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                appViewModel.logout()
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
