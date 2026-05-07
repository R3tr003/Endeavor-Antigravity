import Foundation
import FirebaseFirestore

class FirebaseCalendarRepository: CalendarRepositoryProtocol {

    private let db = Firestore.firestore()
    private let collection = "events"

    // MARK: - Fetch user events

    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        db.collection(collection)
            .whereField("participantIds", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let error = error { completion(.failure(error)); return }
                let events = snapshot?.documents.compactMap { Self.parseEvent($0.documentID, $0.data()) } ?? []
                completion(.success(events))
            }
    }

    // MARK: - Fetch all Endeavour events (public)

    func fetchEndeavourEvents(completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        db.collection(collection)
            .whereField("type", isEqualTo: CalendarEvent.EventType.endeavorEvent.rawValue)
            .whereField("status", isNotEqualTo: CalendarEvent.EventStatus.cancelled.rawValue)
            .order(by: "status")
            .order(by: "startDate")
            .getDocuments { snapshot, error in
                if let error = error { completion(.failure(error)); return }
                let events = (snapshot?.documents ?? [])
                    .compactMap { Self.parseEvent($0.documentID, $0.data()) }
                completion(.success(events))
            }
    }

    // MARK: - Fetch single Endeavour event (for fresh participant list)

    func fetchEndeavourEvent(eventId: String, completion: @escaping (Result<CalendarEvent, Error>) -> Void) {
        db.collection(collection).document(eventId).getDocument { snapshot, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = snapshot?.data(),
                  let event = Self.parseEvent(eventId, data) else {
                completion(.failure(AppError.unknown(reason: "Event not found")))
                return
            }
            DispatchQueue.main.async { completion(.success(event)) }
        }
    }

    // MARK: - Save event

    func saveEvent(_ event: CalendarEvent, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = db.collection(collection).document()
        var data: [String: Any] = [
            "title": event.title,
            "description": event.description,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "type": event.type.rawValue,
            "status": event.status.rawValue,
            "createdBy": event.createdBy,
            "participantIds": event.participantIds,
            "conversationId": event.conversationId as Any,
            "location": event.location as Any,
            "meetLink": event.meetLink as Any,
            "meetProvider": event.meetProvider.rawValue,
            "declinedBy": event.declinedBy,
            "rescheduledBy": event.rescheduledBy,
            "createdAt": Timestamp(date: event.createdAt),
            "category": event.category.rawValue
        ]
        if let coverUrl = event.coverImageUrl  { data["coverImageUrl"]  = coverUrl }
        if let attUrl   = event.attachmentUrl  { data["attachmentUrl"]  = attUrl }
        if let attName  = event.attachmentName { data["attachmentName"] = attName }
        if let maxP     = event.maxParticipants { data["maxParticipants"] = maxP }

        ref.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(ref.documentID)) }
            }
        }
    }

    // MARK: - Update event status

    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        meetLink: String? = nil,
        declinedBy: String? = nil,
        rescheduledBy: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        var update: [String: Any] = ["status": status.rawValue]
        if let link      = meetLink     { update["meetLink"]      = link }
        if let declined  = declinedBy  { update["declinedBy"]    = FieldValue.arrayUnion([declined]) }
        if let rescheduled = rescheduledBy { update["rescheduledBy"] = FieldValue.arrayUnion([rescheduled]) }
        db.collection(collection).document(eventId).updateData(update) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - Update Endeavour event fields (Staff only)

    func updateEndeavourEvent(eventId: String, fields: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(eventId).updateData(fields) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - RSVP

    func rsvpEvent(eventId: String, userId: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(eventId).updateData([
            "participantIds": FieldValue.arrayUnion([userId])
        ]) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func removeParticipantFromEvent(eventId: String, userId: String, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(eventId).updateData([
            "participantIds": FieldValue.arrayRemove([userId])
        ]) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    // MARK: - Real-time listener

    func listenToEvent(
        eventId: String,
        onUpdate: @escaping (CalendarEvent?) -> Void
    ) -> ListenerRegistration {
        return db.collection(collection).document(eventId).addSnapshotListener { snap, _ in
            guard let d = snap?.data() else { onUpdate(nil); return }
            onUpdate(Self.parseEvent(snap!.documentID, d))
        }
    }

    // MARK: - Parse helper

    static func parseEvent(_ id: String, _ d: [String: Any]) -> CalendarEvent? {
        guard
            let title       = d["title"]       as? String,
            let startTs     = d["startDate"]   as? Timestamp,
            let endTs       = d["endDate"]     as? Timestamp,
            let typeRaw     = d["type"]        as? String,
            let type        = CalendarEvent.EventType(rawValue: typeRaw),
            let statusRaw   = d["status"]      as? String,
            let status      = CalendarEvent.EventStatus(rawValue: statusRaw),
            let createdBy   = d["createdBy"]   as? String,
            let participantIds = d["participantIds"] as? [String],
            let createdAtTs = d["createdAt"]   as? Timestamp
        else { return nil }

        var event = CalendarEvent(
            id: id,
            title: title,
            description: d["description"]  as? String ?? "",
            startDate: startTs.dateValue(),
            endDate: endTs.dateValue(),
            type: type,
            status: status,
            createdBy: createdBy,
            participantIds: participantIds,
            conversationId: d["conversationId"] as? String,
            location: d["location"]    as? String,
            meetLink: d["meetLink"]    as? String,
            meetProvider: CalendarEvent.MeetProvider(rawValue: d["meetProvider"] as? String ?? "none") ?? .none,
            declinedBy:   d["declinedBy"]   as? [String] ?? [],
            rescheduledBy: d["rescheduledBy"] as? [String] ?? [],
            createdAt: createdAtTs.dateValue()
        )
        event.category        = CalendarEvent.EventCategory(rawValue: d["category"] as? String ?? "") ?? .other
        event.coverImageUrl   = d["coverImageUrl"]  as? String
        event.attachmentUrl   = d["attachmentUrl"]  as? String
        event.attachmentName  = d["attachmentName"] as? String
        event.maxParticipants = d["maxParticipants"] as? Int
        return event
    }
}
