import Foundation
import Combine
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var selectedDate: Date = Date()
    @Published var appError: AppError?

    private let repository: CalendarRepositoryProtocol = FirebaseCalendarRepository()

    /// Colori degli eventi per ogni giorno del mese selezionato (max 3 colori per giorno)
    var daysWithEventColors: [Int: [Color]] {
        let cal = Calendar.current
        var result: [Int: [Color]] = [:]
        for event in events {
            guard event.status == .confirmed else { continue }
            guard cal.isDate(event.startDate, equalTo: selectedDate, toGranularity: .month) else { continue }
            let day = cal.component(.day, from: event.startDate)
            let color: Color = {
                switch event.type {
                case .meeting: return .purple
                case .endeavorEvent: return .purple
                case .mentorship: return .orange
                }
            }()
            var colors = result[day, default: []]
            if !colors.contains(where: { $0 == color }) { colors.append(color) }
            result[day] = Array(colors.prefix(3))
        }
        return result
    }

    /// Eventi del giorno selezionato
    var eventsForSelectedDate: [CalendarEvent] {
        events.filter { $0.status == .confirmed && Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Prossimi eventi (oggi in poi), max 5
    var upcomingEvents: [CalendarEvent] {
        events.filter { $0.startDate >= Calendar.current.startOfDay(for: Date()) && $0.status == .confirmed }
            .sorted { $0.startDate < $1.startDate }
    }

    func cancelEvent(eventId: String, declinedBy: String) {
        repository.updateEventStatus(eventId: eventId, status: .cancelled, declinedBy: declinedBy) { [weak self] _ in
            DispatchQueue.main.async {
                self?.events.removeAll { $0.id == eventId }
            }
        }
    }

    func removeEvent(id: String) {
        events.removeAll { $0.id == id }
    }

    func fetchEvents(userId: String) {
        isLoading = true
        repository.fetchEvents(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let events):
                    self?.events = events
                    self?.logCompletedMeetingsIfNeeded(events: events)
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }

    // Fires meeting_completed once per event, using UserDefaults to avoid re-logging.
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
