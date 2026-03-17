import Foundation

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var type: EventType
    var status: EventStatus
    var createdBy: String
    var participantIds: [String]
    var conversationId: String?
    var location: String?
    var meetLink: String?
    var createdAt: Date

    enum EventType: String, Codable {
        case meeting = "meeting"
        case endeavorEvent = "endeavor_event"
        case mentorship = "mentorship"

        var displayName: String {
            switch self {
            case .meeting: return "Meeting"
            case .endeavorEvent: return "Event"
            case .mentorship: return "Mentorship"
            }
        }

        var icon: String {
            switch self {
            case .meeting: return "person.2.fill"
            case .endeavorEvent: return "star.fill"
            case .mentorship: return "lightbulb.fill"
            }
        }
    }

    enum EventStatus: String, Codable {
        case confirmed = "confirmed"
        case pending = "pending"
        case cancelled = "cancelled"
    }

    var durationFormatted: String {
        let minutes = Int(endDate.timeIntervalSince(startDate) / 60)
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var isToday: Bool { Calendar.current.isDateInToday(startDate) }
    var isUpcoming: Bool { startDate > Date() }
}
