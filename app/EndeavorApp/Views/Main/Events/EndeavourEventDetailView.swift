import SwiftUI
import SDWebImageSwiftUI

struct EndeavourEventDetailView: View {

    let event: CalendarEvent
    let currentUserId: String
    let userType: String
    var onRsvpChanged: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var activeDetailSheet: DetailSheet? = nil
    @State private var showDeleteAlert = false
    @State private var linkCopied = false
    @State private var isRsvping = false

    // Local mutable participant state — updated immediately on RSVP success
    // so the button flips without waiting for a full parent re-fetch.
    @State private var isMeParticipant: Bool
    @State private var participantCount: Int

    private let calendarRepo = FirebaseCalendarRepository()

    private var isStaff: Bool { userType == "Staff" }
    private var hasLink: Bool { !(event.meetLink ?? "").isEmpty }

    // MARK: - Sheet discriminator

    private enum DetailSheet: Identifiable {
        case participants
        case editEvent
        var id: String {
            switch self {
            case .participants: return "participants"
            case .editEvent:    return "editEvent"
            }
        }
    }

    // MARK: - Init (needed to seed @State from event)

    init(event: CalendarEvent,
         currentUserId: String,
         userType: String,
         onRsvpChanged: (() -> Void)? = nil,
         onDeleted: (() -> Void)? = nil) {
        self.event = event
        self.currentUserId = currentUserId
        self.userType = userType
        self.onRsvpChanged = onRsvpChanged
        self.onDeleted = onDeleted
        _isMeParticipant  = State(initialValue: event.participantIds.contains(currentUserId))
        _participantCount = State(initialValue: event.participantIds.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {

                        // MARK: Cover image
                        if let coverUrl = event.coverImageUrl {
                            WebImage(url: URL(string: coverUrl)) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Color.brandPrimary.opacity(0.12)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        }

                        // MARK: Title + category badge
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                            Text(event.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 5) {
                                Image(systemName: event.category.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(event.category.displayName)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(event.category.swiftColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(event.category.swiftColor.opacity(0.18), in: Capsule())
                        }

                        // MARK: Info rows
                        VStack(spacing: DesignSystem.Spacing.small) {
                            infoRow(icon: "clock",
                                    text: "\(event.startDate.formatted(.dateTime.weekday(.wide).day().month().hour().minute()))  –  \(event.durationFormatted)")

                            if let location = event.location, !location.isEmpty {
                                infoRow(icon: "mappin", text: location)
                            }

                            if event.meetProvider != .none {
                                HStack(spacing: DesignSystem.Spacing.standard) {
                                    if let asset = event.meetProvider.iconAssetName {
                                        Image(asset)
                                            .resizable().scaledToFit()
                                            .frame(width: event.meetProvider.iconNeedsWhiteChip ? 16 : 20,
                                                   height: event.meetProvider.iconNeedsWhiteChip ? 16 : 20)
                                            .padding(event.meetProvider.iconNeedsWhiteChip ? 2 : 0)
                                            .background(event.meetProvider.iconNeedsWhiteChip ? Color.white : Color.clear,
                                                        in: RoundedRectangle(cornerRadius: 4))
                                            .frame(width: 24)
                                    } else {
                                        Image(systemName: event.meetProvider.icon)
                                            .font(.system(size: 16)).foregroundColor(.brandPrimary).frame(width: 24)
                                    }
                                    Text(event.meetProvider.displayName)
                                        .font(.system(size: 15, design: .rounded)).foregroundColor(.primary)
                                    Spacer()
                                    if hasLink {
                                        Button(action: {
                                            UIPasteboard.general.string = event.meetLink
                                            linkCopied = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { linkCopied = false }
                                        }) {
                                            Image(systemName: linkCopied ? "checkmark" : "link")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(linkCopied ? .white : .primary)
                                                .frame(width: 34, height: 34)
                                                .background(linkCopied ? Color.success : Color.secondary.opacity(0.15), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Button(action: {
                                        if let link = event.meetLink, !link.isEmpty {
                                            MeetProviderService.shared.openMeetingLink(link, provider: event.meetProvider)
                                        }
                                    }) {
                                        Text(String(localized: "schedule.join_meeting", defaultValue: "Join Meeting"))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(hasLink ? Color.brandPrimary : Color.secondary.opacity(0.4), in: Capsule())
                                    }
                                    .buttonStyle(.plain).disabled(!hasLink)
                                }
                                .padding(DesignSystem.Spacing.standard)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
                            }

                            if let maxP = event.maxParticipants {
                                infoRow(icon: "person.3.fill",
                                        text: String(format: String(localized: "event.detail.spots",
                                                                    defaultValue: "%d / %d spots taken"),
                                                     participantCount, maxP))
                            } else {
                                infoRow(icon: "person.3.fill",
                                        text: String(format: String(localized: "event.detail.participants_count",
                                                                    defaultValue: "%d participants"),
                                                     participantCount))
                            }

                            if !event.description.isEmpty {
                                infoRow(icon: "text.alignleft", text: event.description)
                            }
                        }

                        // MARK: Attachment
                        if let attUrl = event.attachmentUrl, let attName = event.attachmentName {
                            Button(action: {
                                if let url = URL(string: attUrl) { UIApplication.shared.open(url) }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: "paperclip.circle.fill")
                                        .font(.system(size: 20)).foregroundColor(.brandPrimary)
                                    Text(attName)
                                        .font(.system(size: 14, design: .rounded)).foregroundColor(.brandPrimary).lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.brandPrimary)
                                }
                                .padding(DesignSystem.Spacing.standard)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
                                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                                    .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        // MARK: RSVP button (all users)
                        if event.status != .cancelled {
                            if isMeParticipant {
                                Button(action: { cancelRsvp() }) {
                                    HStack {
                                        if isRsvping { ProgressView().tint(.error) }
                                        else {
                                            Image(systemName: "xmark.circle.fill")
                                            Text(String(localized: "event.detail.rsvp_cancel", defaultValue: "Cancel RSVP"))
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.error)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.standard)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .overlay(Capsule().stroke(Color.error.opacity(0.5), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .disabled(isRsvping)
                            } else {
                                Button(action: { rsvp() }) {
                                    HStack {
                                        if isRsvping { ProgressView().tint(.white) }
                                        else {
                                            Image(systemName: "calendar.badge.plus")
                                            Text(String(localized: "event.detail.rsvp_join", defaultValue: "Join Event"))
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.standard)
                                }
                                .buttonStyle(.glassProminent)
                                .disabled(isRsvping)
                            }
                        }

                        // MARK: Staff actions
                        if isStaff {
                            VStack(spacing: DesignSystem.Spacing.small) {
                                Button(action: { activeDetailSheet = .participants }) {
                                    HStack {
                                        Image(systemName: "person.3.fill")
                                        Text(String(localized: "event.detail.manage_participants", defaultValue: "Manage Participants"))
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.system(size: 13))
                                    }
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(DesignSystem.Spacing.standard)
                                    .glassSurface(.regular, shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                                }
                                .buttonStyle(.plain)

                                Button(action: { activeDetailSheet = .editEvent }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text(String(localized: "event.detail.edit", defaultValue: "Edit Event"))
                                    }
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.0))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.standard)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .overlay(Capsule().stroke(Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.5), lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                Button(action: { showDeleteAlert = true }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text(String(localized: "event.detail.delete", defaultValue: "Delete Event"))
                                    }
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.error)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.standard)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .overlay(Capsule().stroke(Color.error.opacity(0.5), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, DesignSystem.Spacing.xSmall)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.vertical, DesignSystem.Spacing.standard)
                    .padding(.bottom, DesignSystem.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AnalyticsService.shared.logEndeavourEventViewed(
                    category: event.category.rawValue,
                    isPast: event.endDate < Date()
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done", defaultValue: "Done")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
            .sheet(item: $activeDetailSheet) { sheet in
                switch sheet {
                case .participants:
                    EndeavourEventParticipantsView(
                        event: event,
                        currentUserId: currentUserId,
                        onChanged: { onRsvpChanged?() }
                    )
                case .editEvent:
                    CreateEndeavourEventView(
                        existingEvent: event,
                        currentUserId: currentUserId,
                        onSaved: { onRsvpChanged?() }
                    )
                }
            }
            .alert(
                String(localized: "event.detail.delete_confirm_title", defaultValue: "Delete Event?"),
                isPresented: $showDeleteAlert
            ) {
                Button(String(localized: "event.detail.delete", defaultValue: "Delete Event"), role: .destructive) {
                    deleteEvent()
                }
                Button(String(localized: "calendar.cancel_keep", defaultValue: "Keep"), role: .cancel) {}
            } message: {
                Text(String(localized: "event.detail.delete_confirm_message",
                            defaultValue: "This action cannot be undone. All participants will be removed."))
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.standard) {
            Image(systemName: icon)
                .font(.system(size: 16)).foregroundColor(.brandPrimary).frame(width: 24)
            Text(text)
                .font(.system(size: 15, design: .rounded)).foregroundColor(.primary)
        }
        .padding(DesignSystem.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
    }

    private func rsvp() {
        isRsvping = true
        calendarRepo.rsvpEvent(eventId: event.id, userId: currentUserId) { error in
            DispatchQueue.main.async {
                isRsvping = false
                if error == nil {
                    isMeParticipant = true
                    participantCount += 1
                }
                onRsvpChanged?()
            }
        }
    }

    private func cancelRsvp() {
        isRsvping = true
        calendarRepo.removeParticipantFromEvent(eventId: event.id, userId: currentUserId) { error in
            DispatchQueue.main.async {
                isRsvping = false
                if error == nil {
                    isMeParticipant = false
                    participantCount = max(0, participantCount - 1)
                }
                onRsvpChanged?()
            }
        }
    }

    private func deleteEvent() {
        calendarRepo.updateEndeavourEvent(eventId: event.id, fields: [
            "status": "cancelled",
            "lastModifiedBy": currentUserId   // CF excludes this person from cancellation notification
        ]) { error in
            DispatchQueue.main.async {
                if error == nil { onDeleted?() }
                dismiss()
            }
        }
    }
}
