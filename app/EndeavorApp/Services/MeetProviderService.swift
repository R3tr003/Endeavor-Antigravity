import Foundation
import FirebaseFunctions
import UIKit

/// Gestisce la generazione dei link per video meeting (Google Meet, Teams)
/// e l'apertura delle app native sul dispositivo.
class MeetProviderService {

    static let shared = MeetProviderService()
    private let functions = Functions.functions(region: "europe-west1")
    private init() {}

    /// Genera il meet link per un evento dopo l'accept e lo salva in Firestore tramite Cloud Function
    func generateMeetLink(
        eventId: String,
        provider: CalendarEvent.MeetProvider,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard provider != .none else {
            completion(.success(""))
            return
        }

        let data: [String: Any] = [
            "eventId": eventId,
            "provider": provider.rawValue
        ]

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

    /// Apre l'app nativa (Google Meet o Teams) se installata, altrimenti Safari
    func openMeetingLink(_ link: String, provider: CalendarEvent.MeetProvider) {
        guard !link.isEmpty else { return }
        AnalyticsService.shared.logMeetingJoinLinkOpened(provider: provider.rawValue)

        switch provider {
        case .googleMeet:
            // Prova ad aprire l'app Google Meet nativa
            let meetAppScheme = "com.google.meet://"
            if let appUrl = URL(string: meetAppScheme),
               UIApplication.shared.canOpenURL(appUrl) {
                UIApplication.shared.open(appUrl)
            } else if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }

        case .microsoftTeams:
            if let url = URL(string: link) {
                UIApplication.shared.open(url)
            }

        case .none:
            break
        }
    }

    /// Lancia l'AI recheck in background (fire and forget)
    func triggerAIRecheckIfNeeded(
        conversationId: String,
        filterCheckedAt: Date?,
        completion: @escaping (Bool) -> Void
    ) {
        // Recheck solo se non è stato fatto negli ultimi 7 giorni
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
