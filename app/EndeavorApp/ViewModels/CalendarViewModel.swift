import Foundation
import Combine
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var endeavourEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var selectedDate: Date = Date()
    @Published var appError: AppError?

    private let repository: CalendarRepositoryProtocol = FirebaseCalendarRepository()

    // MARK: - Computed views

    /// Dots per day: meeting=purple, endeavorEvent=brandPrimary, mentorship=orange
    var daysWithEventColors: [Int: [Color]] {
        let cal = Calendar.current
        var result: [Int: [Color]] = [:]
        let all = events + endeavourEvents
        for event in all {
            guard event.status == .confirmed else { continue }
            guard cal.isDate(event.startDate, equalTo: selectedDate, toGranularity: .month) else { continue }
            let day = cal.component(.day, from: event.startDate)
            let color: Color = {
                switch event.type {
                case .meeting:       return .purple
                case .endeavorEvent: return event.category.swiftColor
                case .mentorship:    return .orange
                }
            }()
            var colors = result[day, default: []]
            if !colors.contains(where: { $0 == color }) { colors.append(color) }
            result[day] = Array(colors.prefix(3))
        }
        return result
    }

    /// Personal events for the selected day (meetings only — Endeavour events handled separately)
    var eventsForSelectedDate: [CalendarEvent] {
        events
            .filter { $0.type != .endeavorEvent && $0.status == .confirmed && Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// All Endeavour events for the selected day
    var endeavourEventsForSelectedDate: [CalendarEvent] {
        endeavourEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Personal upcoming events (today onward, confirmed, meetings only)
    var upcomingPersonalEvents: [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        return events
            .filter { $0.type != .endeavorEvent && $0.startDate >= today && $0.status == .confirmed }
            .sorted { $0.startDate < $1.startDate }
    }

    /// All upcoming Endeavour events (today onward, not cancelled)
    var upcomingEndeavourEvents: [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        return endeavourEvents
            .filter { $0.startDate >= today && $0.status != .cancelled }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Legacy — used by existing HomeView code before restructure
    var upcomingEvents: [CalendarEvent] { upcomingPersonalEvents }

    // MARK: - Fetch

    func fetchEvents(userId: String) {
        isLoading = true
        repository.fetchEvents(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fetched):
                    self?.events = fetched
                    self?.logCompletedMeetingsIfNeeded(events: fetched)
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }

    func fetchEndeavourEvents() {
        repository.fetchEndeavourEvents { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetched):
                    self?.endeavourEvents = fetched
                case .failure(let error):
                    print("[CalendarVM] fetchEndeavourEvents failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Actions

    func cancelEvent(eventId: String, declinedBy: String) {
        repository.updateEventStatus(eventId: eventId, status: .cancelled, declinedBy: declinedBy) { [weak self] _ in
            DispatchQueue.main.async {
                self?.events.removeAll { $0.id == eventId }
            }
        }
    }

    func removeEvent(id: String) {
        events.removeAll { $0.id == id }
        endeavourEvents.removeAll { $0.id == id }
    }

    func rsvpEndeavourEvent(eventId: String, userId: String) {
        repository.rsvpEvent(eventId: eventId, userId: userId) { [weak self] error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                // Reflect locally: add userId to participantIds
                if let idx = self?.endeavourEvents.firstIndex(where: { $0.id == eventId }) {
                    self?.endeavourEvents[idx].participantIds.append(userId)
                }
            }
        }
    }

    func cancelRsvpEndeavourEvent(eventId: String, userId: String) {
        repository.removeParticipantFromEvent(eventId: eventId, userId: userId) { [weak self] error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                if let idx = self?.endeavourEvents.firstIndex(where: { $0.id == eventId }) {
                    self?.endeavourEvents[idx].participantIds.removeAll { $0 == userId }
                }
            }
        }
    }

    // MARK: - Analytics

    private func logCompletedMeetingsIfNeeded(events: [CalendarEvent]) {
        let key = "loggedCompletedMeetingIds"
        var logged = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
        let now = Date()
        var changed = false
        for event in events {
            guard event.status == .confirmed,
                  event.endDate < now,
                  !logged.contains(event.id) else { continue }
            let minutes = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
            AnalyticsService.shared.logMeetingCompleted(
                provider: event.meetProvider.rawValue,
                durationMinutes: minutes
            )
            logged.insert(event.id)
            changed = true
        }
        if changed { UserDefaults.standard.set(Array(logged), forKey: key) }
    }
}
