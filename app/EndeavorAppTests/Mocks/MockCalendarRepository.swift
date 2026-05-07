import Foundation
import FirebaseFirestore
@testable import app

class MockCalendarRepository: CalendarRepositoryProtocol {

    var mockEvents: [CalendarEvent] = []
    var mockEndeavourEvents: [CalendarEvent] = []
    var savedEvents: [CalendarEvent] = []
    var updatedStatuses: [(eventId: String, status: CalendarEvent.EventStatus)] = []

    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        completion(.success(mockEvents))
    }

    func fetchEndeavourEvents(completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        completion(.success(mockEndeavourEvents))
    }

    func saveEvent(_ event: CalendarEvent, completion: @escaping (Result<String, Error>) -> Void) {
        savedEvents.append(event)
        completion(.success(UUID().uuidString))
    }

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        meetLink: String?,
        declinedBy: String?,
        rescheduledBy: String?,
        completion: @escaping (Error?) -> Void
    ) {
        updatedStatuses.append((eventId: eventId, status: status))
        completion(nil)
    }

    func fetchEndeavourEvent(eventId: String, completion: @escaping (Result<CalendarEvent, Error>) -> Void) {
        if let event = mockEndeavourEvents.first(where: { $0.id == eventId }) {
            completion(.success(event))
        } else {
            completion(.failure(NSError(domain: "Mock", code: 404, userInfo: nil)))
        }
    }

    func updateEndeavourEvent(eventId: String, fields: [String: Any], completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func rsvpEvent(eventId: String, userId: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func removeParticipantFromEvent(eventId: String, userId: String, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }

    func listenToEvent(eventId: String, onUpdate: @escaping (CalendarEvent?) -> Void) -> ListenerRegistration {
        let event = mockEvents.first { $0.id == eventId }
        onUpdate(event)
        return DummyListenerRegistration()
    }
}
