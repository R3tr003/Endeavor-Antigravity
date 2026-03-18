import Foundation
import FirebaseFirestore

protocol CalendarRepositoryProtocol {

    /// Recupera tutti gli eventi dell'utente (come partecipante o creatore)
    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void)

    /// Salva un nuovo evento meeting e restituisce il suo ID
    func saveEvent(_ event: CalendarEvent, completion: @escaping (Result<String, Error>) -> Void)

    /// Aggiorna lo status di un evento e opzionalmente meetLink, declinedBy, rescheduledBy
    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        meetLink: String?,
        declinedBy: String?,
        rescheduledBy: String?,
        completion: @escaping (Error?) -> Void
    )

    /// Listener real-time su un singolo evento (per aggiornare la card in chat live)
    func listenToEvent(eventId: String, onUpdate: @escaping (CalendarEvent?) -> Void) -> ListenerRegistration
}

// MARK: - Convenience overloads (parametri parziali)

extension CalendarRepositoryProtocol {

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        completion: @escaping (Error?) -> Void
    ) {
        updateEventStatus(eventId: eventId, status: status, meetLink: nil, declinedBy: nil, rescheduledBy: nil, completion: completion)
    }

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        meetLink: String?,
        completion: @escaping (Error?) -> Void
    ) {
        updateEventStatus(eventId: eventId, status: status, meetLink: meetLink, declinedBy: nil, rescheduledBy: nil, completion: completion)
    }

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        declinedBy: String?,
        completion: @escaping (Error?) -> Void
    ) {
        updateEventStatus(eventId: eventId, status: status, meetLink: nil, declinedBy: declinedBy, rescheduledBy: nil, completion: completion)
    }

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        rescheduledBy: String?,
        completion: @escaping (Error?) -> Void
    ) {
        updateEventStatus(eventId: eventId, status: status, meetLink: nil, declinedBy: nil, rescheduledBy: rescheduledBy, completion: completion)
    }
}
