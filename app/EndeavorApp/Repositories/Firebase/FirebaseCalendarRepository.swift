import Foundation
import FirebaseFirestore

class FirebaseCalendarRepository: CalendarRepositoryProtocol {

    private let db = Firestore.firestore()
    private let collection = "events"

    /// Recupera tutti gli eventi dell'utente (come partecipante o creatore)
    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        db.collection(collection)
            .whereField("participantIds", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let events = snapshot?.documents.compactMap { doc -> CalendarEvent? in
                    let d = doc.data()
                    guard
                        let title = d["title"] as? String,
                        let startTs = d["startDate"] as? Timestamp,
                        let endTs = d["endDate"] as? Timestamp,
                        let typeRaw = d["type"] as? String,
                        let type = CalendarEvent.EventType(rawValue: typeRaw),
                        let statusRaw = d["status"] as? String,
                        let status = CalendarEvent.EventStatus(rawValue: statusRaw),
                        let createdBy = d["createdBy"] as? String,
                        let participantIds = d["participantIds"] as? [String],
                        let createdAtTs = d["createdAt"] as? Timestamp
                    else { return nil }

                    return CalendarEvent(
                        id: doc.documentID,
                        title: title,
                        description: d["description"] as? String ?? "",
                        startDate: startTs.dateValue(),
                        endDate: endTs.dateValue(),
                        type: type,
                        status: status,
                        createdBy: createdBy,
                        participantIds: participantIds,
                        conversationId: d["conversationId"] as? String,
                        location: d["location"] as? String,
                        meetLink: d["meetLink"] as? String,
                        meetProvider: CalendarEvent.MeetProvider(rawValue: d["meetProvider"] as? String ?? "none") ?? .none,
                        declinedBy: d["declinedBy"] as? [String] ?? [],
                        rescheduledBy: d["rescheduledBy"] as? [String] ?? [],
                        createdAt: createdAtTs.dateValue()
                    )
                } ?? []
                completion(.success(events))
            }
    }

    /// Salva un nuovo evento meeting e restituisce il suo ID
    func saveEvent(_ event: CalendarEvent, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = db.collection(collection).document()
        let data: [String: Any] = [
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
            "createdAt": Timestamp(date: event.createdAt)
        ]
        ref.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)) }
                else { completion(.success(ref.documentID)) }
            }
        }
    }

    /// Aggiorna lo status di un evento e opzionalmente meetLink, declinedBy, rescheduledBy
    func updateEventStatus(
        eventId: String,
        status: CalendarEvent.EventStatus,
        meetLink: String? = nil,
        declinedBy: String? = nil,
        rescheduledBy: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        var update: [String: Any] = ["status": status.rawValue]
        if let link = meetLink { update["meetLink"] = link }
        if let declined = declinedBy { update["declinedBy"] = FieldValue.arrayUnion([declined]) }
        if let rescheduled = rescheduledBy { update["rescheduledBy"] = FieldValue.arrayUnion([rescheduled]) }
        db.collection(collection).document(eventId).updateData(update) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    /// Listener real-time su un singolo evento (per aggiornare la card in chat live)
    func listenToEvent(
        eventId: String,
        onUpdate: @escaping (CalendarEvent?) -> Void
    ) -> ListenerRegistration {
        return db.collection(collection).document(eventId).addSnapshotListener { snap, _ in
            guard let d = snap?.data() else { onUpdate(nil); return }
            guard
                let title = d["title"] as? String,
                let startTs = d["startDate"] as? Timestamp,
                let endTs = d["endDate"] as? Timestamp,
                let typeRaw = d["type"] as? String,
                let type = CalendarEvent.EventType(rawValue: typeRaw),
                let statusRaw = d["status"] as? String,
                let status = CalendarEvent.EventStatus(rawValue: statusRaw),
                let createdBy = d["createdBy"] as? String,
                let participantIds = d["participantIds"] as? [String],
                let createdAtTs = d["createdAt"] as? Timestamp
            else { onUpdate(nil); return }

            let event = CalendarEvent(
                id: snap!.documentID,
                title: title,
                description: d["description"] as? String ?? "",
                startDate: startTs.dateValue(),
                endDate: endTs.dateValue(),
                type: type,
                status: status,
                createdBy: createdBy,
                participantIds: participantIds,
                conversationId: d["conversationId"] as? String,
                location: d["location"] as? String,
                meetLink: d["meetLink"] as? String,
                meetProvider: CalendarEvent.MeetProvider(rawValue: d["meetProvider"] as? String ?? "none") ?? .none,
                declinedBy: d["declinedBy"] as? [String] ?? [],
                rescheduledBy: d["rescheduledBy"] as? [String] ?? [],
                createdAt: createdAtTs.dateValue()
            )
            onUpdate(event)
        }
    }
}
