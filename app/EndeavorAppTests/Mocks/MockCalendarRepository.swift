import Foundation
import FirebaseFirestore
@testable import app

class MockCalendarRepository: CalendarRepositoryProtocol {

    var mockEvents: [CalendarEvent] = []
    var savedEvents: [CalendarEvent] = []
    var updatedStatuses: [(eventId: String, status: CalendarEvent.EventStatus)] = []

    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        completion(.success(mockEvents))
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

    func listenToEvent(eventId: String, onUpdate: @escaping (CalendarEvent?) -> Void) -> ListenerRegistration {
        let event = mockEvents.first { $0.id == eventId }
        onUpdate(event)
        return DummyListenerRegistration()
    }
}
