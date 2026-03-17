import Foundation
import Combine

@MainActor
class ScheduleMeetingViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var startDate: Date = {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!
    }()
    @Published var durationMinutes: Int = 60
    @Published var description: String = ""
    @Published var meetProvider: CalendarEvent.MeetProvider = .none
    @Published var isSending: Bool = false
    @Published var errorMessage: String? = nil

    private let calendarRepository = FirebaseCalendarRepository()
    private let messagesRepository: MessagesRepositoryProtocol = FirebaseMessagesRepository()

    init(prefilling event: CalendarEvent? = nil) {
        guard let event = event else { return }
        title = event.title
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let defaultDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow)!
        startDate = event.startDate > Date() ? event.startDate : defaultDate
        let duration = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
        durationMinutes = [30, 60, 90, 120].contains(duration) ? duration : 60
        description = event.description
        meetProvider = event.meetProvider
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && startDate > Date()
    }

    func send(
        conversationId: String,
        currentUserId: String,
        recipientId: String,
        recipientName: String,
        declineEventId: String? = nil,
        completion: @escaping () -> Void
    ) {
        guard isValid else { return }
        isSending = true
        errorMessage = nil

        // Auto-cancel the previous event when proposing a new time
        if let declineEventId = declineEventId {
            calendarRepository.updateEventStatus(
                eventId: declineEventId,
                status: .cancelled,
                rescheduledBy: currentUserId
            ) { _ in }
        }

        let event = CalendarEvent(
            id: "",
            title: title.trimmingCharacters(in: .whitespaces),
            description: description,
            startDate: startDate,
            endDate: endDate,
            type: .meeting,
            status: .pending,
            createdBy: currentUserId,
            participantIds: [currentUserId, recipientId],
            conversationId: conversationId,
            location: nil,
            meetLink: nil,
            meetProvider: meetProvider,
            declinedBy: [],
            createdAt: Date()
        )

        calendarRepository.saveEvent(event) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.isSending = false
                self.errorMessage = AppError.meetingSaveFailed.errorDescription

            case .success(let eventId):
                self.messagesRepository.sendMeetingInviteMessage(
                    conversationId: conversationId,
                    senderId: currentUserId,
                    recipientId: recipientId,
                    eventId: eventId,
                    eventTitle: self.title
                ) { [weak self] error in
                    guard let self = self else { return }
                    self.isSending = false
                    if error != nil {
                        self.errorMessage = AppError.meetingInviteFailed.errorDescription
                    } else {
                        AnalyticsService.shared.logMeetingInviteSent(
                            durationMinutes: self.durationMinutes,
                            provider: self.meetProvider.rawValue
                        )
                        completion()
                    }
                }
            }
        }
    }
}
