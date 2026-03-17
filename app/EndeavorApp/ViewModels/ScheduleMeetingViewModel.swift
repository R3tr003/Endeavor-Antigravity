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
        completion: @escaping () -> Void
    ) {
        guard isValid else { return }
        isSending = true
        errorMessage = nil

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
