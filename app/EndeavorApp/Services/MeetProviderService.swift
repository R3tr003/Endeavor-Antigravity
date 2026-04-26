import Foundation
import FirebaseFunctions
import FirebaseAuth
import GoogleSignIn
import MSAL
import UIKit

class MeetProviderService {

    static let shared = MeetProviderService()
    private let functions = Functions.functions(region: "europe-west1")

    private var msalApplication: MSALPublicClientApplication? = {
        let clientId = "10900c98-1f88-46dd-9802-e4f2db09a327"
        let authority = "https://login.microsoftonline.com/common"
        guard let authorityURL = URL(string: authority),
              let msalAuthority = try? MSALAADAuthority(url: authorityURL) else { return nil }
        let config = MSALPublicClientApplicationConfig(
            clientId: clientId,
            redirectUri: "msauth.com.endeavor.app://auth",
            authority: msalAuthority
        )
        // Use the app's own keychain group instead of the default shared
        // "com.microsoft.adalcache" group, which requires keychain-access-groups
        // entitlement (not present in this app) and causes errSecMissingEntitlement (-34018).
        config.cacheConfig.keychainSharingGroup = Bundle.main.bundleIdentifier ?? "com.endeavor.app"
        return try? MSALPublicClientApplication(configuration: config)
    }()

    private init() {}

    // MARK: - View Controller Helper

    /// Returns the topmost currently-presented UIViewController so that MSAL
    /// (and GID scope request) can present their WebView on top of any open sheet.
    private func topMostViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMostViewController(from: presented)
        }
        return vc
    }

    private func presentingViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = windowScene.keyWindow?.rootViewController else { return nil }
        return topMostViewController(from: rootVC)
    }

    // MARK: - Meet Link Generation

    func generateMeetLink(
        eventId: String,
        provider: CalendarEvent.MeetProvider,
        userId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard provider != .none else {
            completion(.success(""))
            return
        }

        switch provider {
        case .googleMeet:
            generateGoogleMeetLink(eventId: eventId, userId: userId, completion: completion)
        case .microsoftTeams:
            generateTeamsMeetingLink(eventId: eventId, userId: userId, completion: completion)
        case .none:
            completion(.success(""))
        }
    }

    private func generateGoogleMeetLink(
        eventId: String,
        userId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Controlla se l'utente è loggato con Google
        guard let firebaseUser = Auth.auth().currentUser,
              firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) else {
            // Utente non Google — Meet non disponibile
            completion(.failure(AppError.meetGoogleAccountRequired))
            return
        }

        // Recupera il GIDSignIn currentUser
        guard let gidUser = GIDSignIn.sharedInstance.currentUser else {
            // Non loggato con GIDSignIn — rifai il restore
            completion(.failure(AppError.meetGoogleSignInRequired))
            return
        }

        let calendarScope = "https://www.googleapis.com/auth/calendar.events"
        let hasScope = gidUser.grantedScopes?.contains(calendarScope) ?? false

        if hasScope {
            // Scope già presente — ottieni token fresco e procedi
            refreshAndCall(gidUser: gidUser, eventId: eventId, userId: userId, completion: completion)
        } else {
            // Richiedi scope aggiuntivo — serve la finestra di presentazione
            guard let presentingVC = self.presentingViewController() else {
                completion(.failure(AppError.meetNoPresentingViewController))
                return
            }

            gidUser.addScopes([calendarScope], presenting: presentingVC) { [weak self] signInResult, error in
                guard let self = self else { return }
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let updatedUser = signInResult?.user else {
                    completion(.failure(AppError.meetGoogleSignInRequired))
                    return
                }
                self.refreshAndCall(gidUser: updatedUser, eventId: eventId, userId: userId, completion: completion)
            }
        }
    }

    private func refreshAndCall(
        gidUser: GIDGoogleUser,
        eventId: String,
        userId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Ottieni un access token fresco (gestisce automaticamente il refresh se scaduto)
        gidUser.refreshTokensIfNeeded { user, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let accessToken = user?.accessToken.tokenString ?? ""
            self.callGenerateMeetLink(
                eventId: eventId,
                provider: .googleMeet,
                userId: userId,
                googleAccessToken: accessToken,
                microsoftAccessToken: nil,
                completion: completion
            )
        }
    }

    private func generateTeamsMeetingLink(
        eventId: String,
        userId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let msalApp = msalApplication else {
            completion(.failure(AppError.meetTeamsConfigurationError))
            return
        }

        let scopes = ["https://graph.microsoft.com/OnlineMeetings.ReadWrite"]

        let acquireInteractive = { [weak self] in
            guard let self = self, let presentingVC = self.presentingViewController() else {
                completion(.failure(AppError.meetNoPresentingViewController))
                return
            }
            let webviewParameters = MSALWebviewParameters(authPresentationViewController: presentingVC)
            // Force in-app WKWebView so the OS never redirects to the Authenticator app
            webviewParameters.webviewType = .wkWebView
            let interactiveParameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webviewParameters)
            interactiveParameters.promptType = .selectAccount

            msalApp.acquireToken(with: interactiveParameters) { [weak self] result, error in
                if let error = error {
                    let nsError = error as NSError
                    // MSALErrorDomain code -50002 = user explicitly cancelled the auth flow
                    if nsError.domain == "MSALErrorDomain" && nsError.code == -50002 {
                        completion(.failure(AppError.meetTeamsSignInCancelled))
                    } else {
                        completion(.failure(AppError.meetTeamsSignInRequired))
                    }
                    return
                }
                guard let result = result else {
                    completion(.failure(AppError.meetTeamsSignInRequired))
                    return
                }
                self?.callGenerateMeetLink(
                    eventId: eventId,
                    provider: .microsoftTeams,
                    userId: userId,
                    googleAccessToken: nil,
                    microsoftAccessToken: result.accessToken,
                    completion: completion
                )
            }
        }

        // Prova prima il silent login se esiste un account cached
        if let cachedAccount = try? msalApp.allAccounts().first {
            let silentParameters = MSALSilentTokenParameters(scopes: scopes, account: cachedAccount)
            msalApp.acquireTokenSilent(with: silentParameters) { [weak self] result, _ in
                if let result = result {
                    self?.callGenerateMeetLink(
                        eventId: eventId,
                        provider: .microsoftTeams,
                        userId: userId,
                        googleAccessToken: nil,
                        microsoftAccessToken: result.accessToken,
                        completion: completion
                    )
                } else {
                    acquireInteractive()
                }
            }
        } else {
            acquireInteractive()
        }
    }

    private func callGenerateMeetLink(
        eventId: String,
        provider: CalendarEvent.MeetProvider,
        userId: String,
        googleAccessToken: String?,
        microsoftAccessToken: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var data: [String: Any] = [
            "eventId": eventId,
            "provider": provider.rawValue,
            "userId": userId
        ]
        if let token = googleAccessToken { data["googleAccessToken"] = token }
        if let token = microsoftAccessToken { data["microsoftAccessToken"] = token }

        functions.httpsCallable("generateMeetLink").call(data) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let link = (result?.data as? [String: Any])?["meetLink"] as? String ?? ""
                completion(.success(link))
            }
        }
    }

    // MARK: - Cancel Calendar Event

    /// Cancels the Google Calendar event associated with this meeting.
    /// Silently no-ops if the current user has no Google Sign-In session or the event
    /// has no associated calendar ID. Never surfaces errors to the user.
    func cancelGoogleCalendarEvent(eventId: String) {
        guard let gidUser = GIDSignIn.sharedInstance.currentUser else { return }
        gidUser.refreshTokensIfNeeded { [weak self] user, error in
            guard let self = self, let user = user, error == nil else { return }
            let accessToken = user.accessToken.tokenString
            self.functions.httpsCallable("cancelCalendarEvent").call([
                "eventId": eventId,
                "googleAccessToken": accessToken
            ]) { _, error in
                if let error = error {
                    print("[MeetProviderService] cancelCalendarEvent error (non-fatal): \(error)")
                }
            }
        }
    }

    // MARK: - Open Meeting Link

    func openMeetingLink(_ link: String, provider: CalendarEvent.MeetProvider) {
        guard !link.isEmpty, let url = URL(string: link) else { return }
        AnalyticsService.shared.logMeetingJoinLinkOpened(provider: provider.rawValue)
        UIApplication.shared.open(url)
    }

    // MARK: - AI Recheck

    func triggerAIRecheckIfNeeded(
        conversationId: String,
        filterCheckedAt: Date?,
        completion: @escaping (Bool) -> Void
    ) {
        if let lastCheck = filterCheckedAt,
           Date().timeIntervalSince(lastCheck) < 7 * 24 * 3600 {
            completion(false)
            return
        }
        AnalyticsService.shared.logAIRecheckTriggered()
        functions.httpsCallable("recheckConversation").call(["conversationId": conversationId]) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[MeetProviderService] AI recheck error: \(error)")
                    completion(false)
                    return
                }
                let filtered = (result?.data as? [String: Any])?["filtered"] as? Bool ?? false
                completion(filtered)
            }
        }
    }

}
