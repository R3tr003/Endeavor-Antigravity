import Foundation
import SwiftUI

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
    var meetProvider: MeetProvider = .none
    var declinedBy: [String] = []
    var rescheduledBy: [String] = []
    var createdAt: Date

    // Endeavour event fields
    var category: EventCategory = .other
    var coverImageUrl: String?
    var attachmentUrl: String?
    var attachmentName: String?
    var maxParticipants: Int?

    // Fixed UID for the Endeavor system sender used in chat notifications
    static let endeavorSystemUID = "endeavor_system"

    enum MeetProvider: String, Codable {
        case none = "none"
        case googleMeet = "google_meet"
        case microsoftTeams = "microsoft_teams"

        var displayName: String {
            switch self {
            case .none: return String(localized: "event.provider.none", defaultValue: "No video link")
            case .googleMeet: return "Google Meet"
            case .microsoftTeams: return "Microsoft Teams"
            }
        }

        var icon: String {
            switch self {
            case .none: return "calendar"
            case .googleMeet: return "video.fill"
            case .microsoftTeams: return "video.fill"
            }
        }

        var iconAssetName: String? {
            switch self {
            case .none: return nil
            case .googleMeet: return "icon_google_meet"
            case .microsoftTeams: return "icon_microsoft_teams"
            }
        }

        var iconNeedsWhiteChip: Bool { self == .microsoftTeams }

        var shortName: String {
            switch self {
            case .none: return String(localized: "event.provider.short.none", defaultValue: "None")
            case .googleMeet: return "Meet"
            case .microsoftTeams: return "Teams"
            }
        }
    }

    enum EventCategory: String, Codable, CaseIterable {
        case panel       = "panel"
        case gala        = "gala"
        case charity     = "charity"
        case trip        = "trip"
        case workshop    = "workshop"
        case conference  = "conference"
        case networking  = "networking"
        case webinar     = "webinar"
        case other       = "other"

        var displayName: String {
            switch self {
            case .panel:      return String(localized: "event.category.panel",       defaultValue: "Panel")
            case .gala:       return String(localized: "event.category.gala",        defaultValue: "Gala")
            case .charity:    return String(localized: "event.category.charity",     defaultValue: "Charity Event")
            case .trip:       return String(localized: "event.category.trip",        defaultValue: "Trip")
            case .workshop:   return String(localized: "event.category.workshop",    defaultValue: "Workshop")
            case .conference: return String(localized: "event.category.conference",  defaultValue: "Conference")
            case .networking: return String(localized: "event.category.networking",  defaultValue: "Networking")
            case .webinar:    return String(localized: "event.category.webinar",     defaultValue: "Webinar")
            case .other:      return String(localized: "event.category.other",       defaultValue: "Other")
            }
        }

        var icon: String {
            switch self {
            case .panel:      return "person.3.fill"
            case .gala:       return "sparkles"
            case .charity:    return "heart.fill"
            case .trip:       return "airplane"
            case .workshop:   return "hammer.fill"
            case .conference: return "building.columns.fill"
            case .networking: return "network"
            case .webinar:    return "video.fill"
            case .other:      return "star.fill"
            }
        }

        var emoji: String {
            switch self {
            case .panel:      return "🎤"
            case .gala:       return "🥂"
            case .charity:    return "❤️"
            case .trip:       return "✈️"
            case .workshop:   return "🔧"
            case .conference: return "🏛️"
            case .networking: return "🤝"
            case .webinar:    return "💻"
            case .other:      return "⭐"
            }
        }

        var swiftColor: Color {
            switch self {
            case .panel:      return Color(red: 0.0,  green: 0.74, blue: 0.84)  // cyan
            case .gala:       return Color(red: 1.0,  green: 0.80, blue: 0.0)   // gold
            case .charity:    return Color(red: 1.0,  green: 0.27, blue: 0.53)  // pink
            case .trip:       return Color(red: 0.20, green: 0.60, blue: 1.0)   // blue
            case .workshop:   return Color(red: 1.0,  green: 0.55, blue: 0.0)   // orange
            case .conference: return Color(red: 0.63, green: 0.37, blue: 1.0)   // purple
            case .networking: return Color(red: 0.18, green: 0.80, blue: 0.44)  // green
            case .webinar:    return Color(red: 0.0,  green: 0.85, blue: 0.74)  // teal (brandPrimary-ish)
            case .other:      return Color(red: 0.55, green: 0.62, blue: 0.70)  // slate
            }
        }
    }

    enum EventType: String, Codable {
        case meeting      = "meeting"
        case endeavorEvent = "endeavor_event"
        case mentorship   = "mentorship"

        var displayName: String {
            switch self {
            case .meeting:       return String(localized: "event.type.meeting",    defaultValue: "Meeting")
            case .endeavorEvent: return String(localized: "event.type.endeavor",   defaultValue: "Event")
            case .mentorship:    return String(localized: "event.type.mentorship", defaultValue: "Mentorship")
            }
        }

        var icon: String {
            switch self {
            case .meeting:       return "person.2.fill"
            case .endeavorEvent: return "star.fill"
            case .mentorship:    return "lightbulb.fill"
            }
        }
    }

    enum EventStatus: String, Codable {
        case confirmed = "confirmed"
        case pending   = "pending"
        case cancelled = "cancelled"
    }

    var durationFormatted: String {
        let minutes = Int(endDate.timeIntervalSince(startDate) / 60)
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var isToday: Bool    { Calendar.current.isDateInToday(startDate) }
    var isUpcoming: Bool { startDate > Date() }
}
