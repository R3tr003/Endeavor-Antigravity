import Foundation
import FirebaseFirestore

class CalendarRepository {

    private let db = Firestore.firestore()
    private let collection = "events"

    /// Recupera tutti gli eventi dell'utente (come partecipante o creatore)
    func fetchEvents(userId: String, completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
        db.collection(collection)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "startDate", descending: false)
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
                        createdAt: createdAtTs.dateValue()
                    )
                } ?? []
                completion(.success(events))
            }
    }
}
