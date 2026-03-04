import SwiftUI
import GoogleSignIn
import FirebaseCore
import FirebaseAppCheck
import SDWebImage

@main
struct EndeavorApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // --- Firebase App Check Setup ---
        // In DEBUG: skip App Check entirely (debug tokens require manual registration in
        // Firebase Console and silently block ALL Firestore writes if not registered).
        // In RELEASE: use AppAttest for production security.
        #if !DEBUG
        let providerFactory = AppAttestProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        // Initialize Firebase when the app launches
        FirebaseApp.configure()
        
        // --- SDWebImage Cache Configuration ---
        // Memory cache: 100MB — sufficient per ~200 avatar 500x500
        SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024
        
        // Disk cache: 200MB, scadenza 7 giorni
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024
        SDImageCache.shared.config.maxDiskAge = 7 * 24 * 60 * 60
        
        // Download timeout: 15 secondi (default è 15, esplicitarlo per chiarezza)
        SDWebImageDownloader.shared.config.downloadTimeout = 15
        
        // Decompressione immagini in background thread — evita jank sulla main thread
        SDImageCoderHelper.defaultScaleDownLimitBytes = 50 * 1024 * 1024
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
                            .environmentObject(appViewModel.onboardingViewModel)
                            .transition(.opacity)
                            .preferredColorScheme(appViewModel.colorScheme)
                    }
                } else if appViewModel.isOnboardingAuthPending {
                    OnboardingContainerView()
                        .environmentObject(appViewModel)
                        .environmentObject(appViewModel.onboardingViewModel)
                        .transition(.opacity)
                        .preferredColorScheme(appViewModel.colorScheme)
                } else {
                    WelcomeView()
                        .environmentObject(appViewModel)
                        .transition(.opacity)
                        .preferredColorScheme(appViewModel.colorScheme)
                }
            }
            .animation(.default, value: appViewModel.isLoggedIn)
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
