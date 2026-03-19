import SwiftUI
import GoogleSignIn
import FirebaseCore
import MSAL
import FirebaseAppCheck
import FirebaseFirestore
import FirebasePerformance
import FirebaseAnalytics
import SDWebImage
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // --- Firebase App Check Setup ---
        #if !DEBUG
        let providerFactory = AppAttestProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        // Initialize Firebase when the app launches.
        FirebaseApp.configure()

        // app_open_source: cold start (Firebase was not initialized before this call)
        AnalyticsService.shared.logAppOpenSource(source: .coldStart)

        // Register for push notifications and set delegate to capture push open source
        UNUserNotificationCenter.current().delegate = self

        // Restore Google Sign-In session
        GIDSignIn.sharedInstance.restorePreviousSignIn { _, _ in }

        // MARK: - Firestore Offline Persistence
        let defaultSettings = FirestoreSettings()
        defaultSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: 100 * 1024 * 1024 as NSNumber
        )
        Firestore.firestore().settings = defaultSettings

        let messagingSettings = FirestoreSettings()
        messagingSettings.cacheSettings = PersistentCacheSettings(
            sizeBytes: 50 * 1024 * 1024 as NSNumber
        )
        Firestore.firestore(database: "messaging").settings = messagingSettings

        #if DEBUG
        Performance.sharedInstance().isDataCollectionEnabled = true
        #endif
        
        // --- SDWebImage Cache Configuration ---
        SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024
        SDImageCache.shared.config.maxDiskAge = 7 * 24 * 60 * 60
        SDWebImageDownloader.shared.config.downloadTimeout = 15
        SDImageCoderHelper.defaultScaleDownLimitBytes = 50 * 1024 * 1024
        
        return true
    }

    // MARK: - Background resume
    // This fires ONLY when the app returns from background — never on cold start.
    // Cold start is already handled in didFinishLaunchingWithOptions above.
    func applicationWillEnterForeground(_ application: UIApplication) {
        AnalyticsService.shared.logAppOpenSource(source: .background)
    }

    // MARK: - Push Notification delegate
    // Called when the user taps a push notification while the app is in background/foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        AnalyticsService.shared.logAppOpenSource(source: .pushNotification)
        completionHandler()
    }

}

@main
struct EndeavorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

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
            .alert(
                String(localized: "common.no_connection_title", defaultValue: "No Internet Connection"),
                isPresented: $appViewModel.isOffline
            ) {
                Button(String(localized: "common.try_again", defaultValue: "Try Again")) {
                    appViewModel.retryConnectivity()
                }
            } message: {
                Text(String(localized: "common.no_connection_body",
                            defaultValue: "Check your connection and try again."))
            }
            .onOpenURL { url in
                MSALPublicClientApplication.handleMSALResponse(url, sourceApplication: nil)
                GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background: print("📱 App moved to background")
                case .active:     print("📱 App became active")
                case .inactive:   print("📱 App became inactive")
                @unknown default: break
                }
            }
        }
    }
}
