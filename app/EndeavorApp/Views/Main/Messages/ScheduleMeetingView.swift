import SwiftUI

struct ScheduleMeetingView: View {
    let conversationId: String
    let currentUserId: String
    let recipientId: String
    let recipientName: String
    let existingEvents: [CalendarEvent]
    let existingEvent: CalendarEvent?

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ScheduleMeetingViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case title, agenda }

    private var isProposeMode: Bool { existingEvent != nil }
    private let durationOptions: [Int] = [30, 60, 90, 120]

    init(
        conversationId: String,
        currentUserId: String,
        recipientId: String,
        recipientName: String,
        existingEvents: [CalendarEvent],
        existingEvent: CalendarEvent? = nil
    ) {
        self.conversationId = conversationId
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.existingEvents = existingEvents
        self.existingEvent = existingEvent
        self._viewModel = StateObject(wrappedValue: ScheduleMeetingViewModel(prefilling: existingEvent))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {

                        // Titolo meeting
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                            HStack(spacing: 2) {
                                Text(String(localized: "schedule.meeting_title_label", defaultValue: "Meeting title"))
                                Text("*").foregroundColor(.red)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                            TextField(
                                String(localized: "schedule.title_placeholder",
                                       defaultValue: "e.g. Strategy call with \(recipientName)"),
                                text: $viewModel.title
                            )
                            .font(.system(size: 16, design: .rounded))
                            .focused($focusedField, equals: .title)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                        }

                        // Data e ora
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                            Text(String(localized: "schedule.date_time", defaultValue: "Date & Time"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1.2)

                            DatePicker(
                                "",
                                selection: $viewModel.startDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(.brandPrimary)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular, shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                        }

                        // Conflitti nel calendario
                        let conflicts = existingEvents.filter { event in
                            event.startDate < viewModel.endDate && event.endDate > viewModel.startDate
                        }
                        if !conflicts.isEmpty {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(localized: "schedule.conflict_warning",
                                                defaultValue: "Conflict with existing event"))
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.orange)
                                    Text(conflicts.first?.title ?? "")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.tint(Color.orange.opacity(0.10)), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.medium))
                        }

                        // Durata
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                            HStack(spacing: 2) {
                                Text(String(localized: "schedule.duration", defaultValue: "Duration"))
                                Text("*").foregroundColor(.red)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                            HStack(spacing: DesignSystem.Spacing.small) {
                                ForEach(durationOptions, id: \.self) { minutes in
                                    DurationOptionButton(
                                        minutes: minutes,
                                        isSelected: viewModel.durationMinutes == minutes,
                                        onTap: { viewModel.durationMinutes = minutes }
                                    )
                                }
                            }
                        }

                        // Agenda opzionale
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                            Text(String(localized: "schedule.agenda", defaultValue: "Agenda (optional)"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1.2)

                            TextField(
                                String(localized: "schedule.agenda_placeholder",
                                       defaultValue: "Topics to discuss..."),
                                text: $viewModel.description,
                                axis: .vertical
                            )
                            .lineLimit(3, reservesSpace: true)
                            .font(.system(size: 15, design: .rounded))
                            .focused($focusedField, equals: .agenda)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                        }

                        // Provider video
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                            HStack(spacing: 2) {
                                Text(String(localized: "schedule.video", defaultValue: "Video call"))
                                Text("*").foregroundColor(.red)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(1.2)

                            HStack(spacing: DesignSystem.Spacing.small) {
                                ForEach([CalendarEvent.MeetProvider.none, .googleMeet, .microsoftTeams], id: \.rawValue) { provider in
                                    MeetProviderOptionButton(
                                        provider: provider,
                                        isSelected: viewModel.meetProvider == provider,
                                        onTap: { viewModel.meetProvider = provider }
                                    )
                                }
                            }

                            if viewModel.meetProvider != .none {
                                Text(String(localized: "schedule.video_note",
                                            defaultValue: "The meeting link will be generated when the invite is accepted."))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Bottone invia
                        Button(action: {
                        let totalMessages = existingEvents.count
                            viewModel.send(
                                conversationId: conversationId,
                                currentUserId: currentUserId,
                                recipientId: recipientId,
                                recipientName: recipientName,
                                messageCount: totalMessages,
                                isFirstMeeting: existingEvents.filter({ $0.type == .meeting }).isEmpty,
                                declineEventId: existingEvent?.id
                            ) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                if viewModel.isSending {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: isProposeMode ? "calendar.badge.clock" : "calendar.badge.plus")
                                    Text(isProposeMode
                                         ? String(localized: "schedule.propose_new_time", defaultValue: "Propose New Time")
                                         : String(localized: "schedule.send_invite", defaultValue: "Send Meeting Invite"))
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.standard)
                        }
                        .buttonStyle(.glassProminent)
                        .opacity(viewModel.isValid ? 1 : 0.55)
                        .disabled(!viewModel.isValid || viewModel.isSending)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(DesignSystem.Spacing.large)
                }
            }
            .navigationTitle(isProposeMode
                ? String(localized: "schedule.propose_new_time", defaultValue: "Propose New Time")
                : String(localized: "schedule.title", defaultValue: "Schedule Meeting"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}

private struct DurationOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var labelText: String {
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remaining = minutes % 60
        return remaining == 0 ? "\(hours)h" : "\(hours)h \(remaining)m"
    }

    var body: some View {
        if isSelected {
            Button(action: onTap) {
                Text(labelText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button(action: onTap) {
                Text(labelText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }
}

private struct MeetProviderOptionButton: View {
    let provider: CalendarEvent.MeetProvider
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        if isSelected {
            Button(action: onTap) { label }
                .buttonStyle(.glassProminent)
        } else {
            Button(action: onTap) { label }
                .buttonStyle(.glass)
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let assetName = provider.iconAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: provider.iconNeedsWhiteChip ? 16 : 20,
                           height: provider.iconNeedsWhiteChip ? 16 : 20)
                    .padding(provider.iconNeedsWhiteChip ? 2 : 0)
                    .background(
                        provider.iconNeedsWhiteChip ? Color.white : Color.clear,
                        in: RoundedRectangle(cornerRadius: 4)
                    )
            } else {
                Image(systemName: provider.icon)
                    .font(.system(size: 15))
            }
            Text(provider.shortName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .frame(maxWidth: .infinity)
    }
}
