import Foundation
import Combine
import SwiftUI

@MainActor
class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var selectedDate: Date = Date()
    @Published var appError: AppError?

    private let repository = CalendarRepository()

    /// Colori degli eventi per ogni giorno del mese selezionato (max 3 colori per giorno)
    var daysWithEventColors: [Int: [Color]] {
        let cal = Calendar.current
        var result: [Int: [Color]] = [:]
        for event in events {
            guard cal.isDate(event.startDate, equalTo: selectedDate, toGranularity: .month) else { continue }
            let day = cal.component(.day, from: event.startDate)
            let color: Color = {
                switch event.type {
                case .meeting: return .brandPrimary
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
        events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Prossimi eventi (oggi in poi), max 5
    var upcomingEvents: [CalendarEvent] {
        events.filter { $0.startDate >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchEvents(userId: String) {
        isLoading = true
        repository.fetchEvents(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let events): self?.events = events
                case .failure(let error):
                    self?.appError = .unknown(reason: error.localizedDescription)
                }
            }
        }
    }
}
