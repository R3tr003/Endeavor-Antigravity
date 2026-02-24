import SwiftUI
import GoogleSignIn
import FirebaseCore
import FirebaseAppCheck

@main
struct EndeavorApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // --- Firebase App Check Setup ---
        // For development/simulator testing, use the DebugProvider.
        // It will print a local debug token in the Xcode console that you must
        // manually register in the Firebase Console under App Check -> Apps -> Manage Debug Tokens.
        
        // Uncomment the line below for PRODUCTION release using Apple's DeviceCheck/AppAttest:
        // AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Initialize Firebase when the app launches
        FirebaseApp.configure()
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
                            .preferredColorScheme(appViewModel.colorScheme)
                    } else {
                        OnboardingContainerView()
                            .environmentObject(appViewModel)
                            .transition(.opacity)
                            .preferredColorScheme(appViewModel.colorScheme)
                    }
                } else {
                    WelcomeView()
                        .environmentObject(appViewModel)
                        .transition(.opacity)
                        .preferredColorScheme(appViewModel.colorScheme)
                }
            }
            .animation(.default, value: appViewModel.isOnboardingComplete)
            .preferredColorScheme(appViewModel.colorScheme)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    print("📱 App moved to background")
                case .active:
                    print("📱 App became active")
                case .inactive:
                    print("📱 App became inactive")
                @unknown default:
                    break
                }
            }
        }
    }
}
