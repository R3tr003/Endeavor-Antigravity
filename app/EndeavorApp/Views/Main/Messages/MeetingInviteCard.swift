import SwiftUI
import FirebaseFirestore

struct MeetingInviteCard: View {
    let message: Message
    let isFromMe: Bool
    let currentUserId: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onProposeNew: (CalendarEvent) -> Void

    @State private var event: CalendarEvent? = nil
    @State private var listener: ListenerRegistration? = nil
    @State private var showDetail = false
    @State private var isAccepting = false
    private let calendarRepository: CalendarRepositoryProtocol = FirebaseCalendarRepository()

    var body: some View {
        VStack(alignment: isFromMe ? .trailing : .leading, spacing: DesignSystem.Spacing.xxSmall) {

            // Card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {

                    // Header
                    HStack(spacing: DesignSystem.Spacing.small) {
                        ZStack {
                            Circle()
                                .fill(Color.brandPrimary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "video.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(.brandPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "schedule.invite_label", defaultValue: "Meeting Invite"))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                            if let event = event {
                                Text(event.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 120, height: 14)
                            }
                        }
                        Spacer()
                        statusBadge
                    }

                    if let event = event {
                        Divider().opacity(0.3)

                        // Data, ora e durata — tutto su una riga in grassetto
                        Label(
                            event.startDate.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute())
                                + "  –  " + String(localized: "schedule.duration_label", defaultValue: "Duration: ")
                                + event.durationFormatted,
                            systemImage: "clock"
                        )
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                        // Provider video
                        if event.meetProvider != .none {
                            Label(event.meetProvider.displayName, systemImage: event.meetProvider.icon)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        // Agenda
                        if !event.description.isEmpty {
                            Text(event.description)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        // Azioni — solo per il ricevente e solo se pending
                        if !isFromMe && event.status == .pending {
                            Divider().opacity(0.3)
                            HStack(spacing: DesignSystem.Spacing.xSmall) {
                                Button(action: onDecline) {
                                    Text(String(localized: "schedule.decline", defaultValue: "Decline"))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.error)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .overlay(Capsule().stroke(Color.error.opacity(0.5), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .disabled(isAccepting)

                                Button(action: {
                                    AnalyticsService.shared.logMeetingNewTimeProposed()
                                    onProposeNew(event)
                                }) {
                                    Text(String(localized: "schedule.propose_new", defaultValue: "Propose new"))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.yellow)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .overlay(Capsule().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .disabled(isAccepting)

                                Button(action: {
                                    guard !isAccepting else { return }
                                    isAccepting = true
                                    onAccept()
                                }) {
                                    Group {
                                        if isAccepting {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(.white)
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(String(localized: "schedule.accept", defaultValue: "Accept"))
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 28)
                                    .background(Color.brandPrimary.opacity(isAccepting ? 0.6 : 1), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(isAccepting)
                            }
                        }

                        // Stato finale
                        if event.status == .confirmed {
                            if let link = event.meetLink, !link.isEmpty {
                                Button(action: {
                                    MeetProviderService.shared.openMeetingLink(link, provider: event.meetProvider)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: event.meetProvider.icon)
                                            .font(.system(size: 13))
                                        Text(String(localized: "schedule.join_meeting", defaultValue: "Join Meeting"))
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.brandPrimary, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.standard)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                    .stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1))
                // Timestamp sotto la card
                Text(message.createdAt, style: .time)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignSystem.Spacing.xSmall)
        }
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
        .onTapGesture {
            if event?.status == .confirmed { showDetail = true }
        }
        .sheet(isPresented: $showDetail) {
            if let e = event {
                CalendarEventDetailView(event: e, currentUserId: currentUserId)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let event = event {
            switch event.status {
            case .pending:
                Text(String(localized: "schedule.pending", defaultValue: "Pending"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            case .confirmed:
                Text(String(localized: "home.confirmed", defaultValue: "Confirmed"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.success)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.success.opacity(0.12), in: Capsule())
            case .cancelled:
                if !event.rescheduledBy.isEmpty {
                    Text(String(localized: "schedule.rescheduled", defaultValue: "Rescheduled"))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.12), in: Capsule())
                } else {
                    Text(String(localized: "schedule.declined_label", defaultValue: "Declined"))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.error)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.error.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private func startListening() {
        guard let eventId = message.meetingEventId else { return }
        listener = calendarRepository.listenToEvent(eventId: eventId) { updatedEvent in
            DispatchQueue.main.async {
                self.event = updatedEvent
                // Reset loading state once the event is no longer pending
                if updatedEvent?.status != .pending {
                    self.isAccepting = false
                }
            }
        }
    }
}
