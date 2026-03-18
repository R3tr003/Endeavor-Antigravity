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

    private let calendarRepository: CalendarRepositoryProtocol = FirebaseCalendarRepository()
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
        messageCount: Int = 0,
        isFirstMeeting: Bool = false,
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
                let capturedProvider = self.meetProvider
                let capturedTitle = self.title
                let capturedDuration = self.durationMinutes

                let sendInvite = { [weak self] in
                    guard let self = self else { return }
                    self.messagesRepository.sendMeetingInviteMessage(
                        conversationId: conversationId,
                        senderId: currentUserId,
                        recipientId: recipientId,
                        eventId: eventId,
                        eventTitle: capturedTitle
                    ) { [weak self] error in
                        guard let self = self else { return }
                        self.isSending = false
                        if error != nil {
                            self.errorMessage = AppError.meetingInviteFailed.errorDescription
                        } else {
                            AnalyticsService.shared.logMeetingInviteSent(
                                durationMinutes: capturedDuration,
                                provider: capturedProvider.rawValue
                            )
                            // Funnel: how many messages before the first meeting was scheduled
                            AnalyticsService.shared.logMeetingToMessageRatio(messageCount: messageCount)
                            // Conversion: first time this user schedules a meeting
                            if isFirstMeeting {
                                AnalyticsService.shared.logFirstMeetingScheduled()
                            }
                            completion()
                        }
                    }
                }

                // Try to generate meet link from the sender's account before sending the invite.
                // If successful, the Cloud Function already saves the link to Firestore.
                // If the sender has no Google/Teams account, proceed without a link —
                // the recipient will attempt generation on accept.
                if capturedProvider != .none {
                    MeetProviderService.shared.generateMeetLink(
                        eventId: eventId,
                        provider: capturedProvider,
                        userId: currentUserId
                    ) { _ in sendInvite() }
                } else {
                    sendInvite()
                }
            }
        }
    }
}
