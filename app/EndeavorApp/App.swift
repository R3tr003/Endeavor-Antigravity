import SwiftUI

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
                
                if appViewModel.isLoggedIn {
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
        }
    }
}
