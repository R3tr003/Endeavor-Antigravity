import SwiftUI
import GoogleSignIn

@main
struct EndeavorApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    init() {
        // Initialize Firebase when the app launches
        FirebaseService.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                if appViewModel.isCheckingAuth {
                    // Show loading while checking for existing user data
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if appViewModel.isLoggedIn {
                    if appViewModel.isOnboardingComplete {
                        MainTabView()
                            .environmentObject(appViewModel)
                            .transition(.opacity)
                    } else {
                        OnboardingContainerView()
                            .environmentObject(appViewModel)
                            .transition(.opacity)
                    }
                } else {
                    WelcomeView()
                        .environmentObject(appViewModel)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: appViewModel.isOnboardingComplete)
            .preferredColorScheme(appViewModel.colorScheme)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
