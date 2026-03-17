import SwiftUI

struct ScheduleMeetingView: View {
    let conversationId: String
    let currentUserId: String
    let recipientId: String
    let recipientName: String
    let existingEvents: [CalendarEvent]

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ScheduleMeetingViewModel()
    @FocusState private var focusedField: Field?

    private enum Field { case title, agenda }

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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .stroke(focusedField == .title ? Color.brandPrimary : Color.borderGlare.opacity(0.15),
                                        lineWidth: focusedField == .title ? 1.5 : 1))
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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
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
                            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
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
                                ForEach([30, 60, 90, 120], id: \.self) { minutes in
                                    Button(action: { viewModel.durationMinutes = minutes }) {
                                        Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h\(minutes%60 == 0 ? "" : " \(minutes%60)m")")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(viewModel.durationMinutes == minutes ? .white : .primary)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                viewModel.durationMinutes == minutes ? Color.brandPrimary : Color.clear,
                                                in: Capsule()
                                            )
                                            .overlay(Capsule().stroke(
                                                viewModel.durationMinutes == minutes ? Color.clear : Color.borderGlare.opacity(0.3),
                                                lineWidth: 1
                                            ))
                                    }
                                    .buttonStyle(.plain)
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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                .stroke(focusedField == .agenda ? Color.brandPrimary : Color.borderGlare.opacity(0.15),
                                        lineWidth: focusedField == .agenda ? 1.5 : 1))
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
                                    Button(action: { viewModel.meetProvider = provider }) {
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
                                        .foregroundColor(viewModel.meetProvider == provider ? .white : .primary)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, DesignSystem.Spacing.small)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            viewModel.meetProvider == provider ? Color.brandPrimary : Color.clear,
                                            in: Capsule()
                                        )
                                        .overlay(Capsule().stroke(
                                            viewModel.meetProvider == provider ? Color.clear : Color.borderGlare.opacity(0.3),
                                            lineWidth: 1
                                        ))
                                    }
                                    .buttonStyle(.plain)
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
                            viewModel.send(
                                conversationId: conversationId,
                                currentUserId: currentUserId,
                                recipientId: recipientId,
                                recipientName: recipientName
                            ) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                if viewModel.isSending {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                    Text(String(localized: "schedule.send_invite", defaultValue: "Send Meeting Invite"))
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.standard)
                            .background(
                                viewModel.isValid ? Color.brandPrimary : Color.secondary.opacity(0.3),
                                in: Capsule()
                            )
                        }
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
            .navigationTitle(String(localized: "schedule.title", defaultValue: "Schedule Meeting"))
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
