import SwiftUI
import SDWebImageSwiftUI

struct EndeavourEventParticipantsView: View {

    let event: CalendarEvent
    let currentUserId: String
    var onChanged: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var participants: [UserProfile] = []
    @State private var isLoading = true
    @State private var removingId: String? = nil

    private let userRepo = FirebaseUserRepository()
    private let calendarRepo = FirebaseCalendarRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)

                if isLoading {
                    ProgressView().tint(.brandPrimary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if participants.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 36)).foregroundColor(.secondary.opacity(0.4))
                        Text(String(localized: "event.participants.empty", defaultValue: "No participants yet"))
                            .font(.system(size: 15, design: .rounded)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(participants) { user in
                                participantRow(user)
                            }
                        }
                        .padding(DesignSystem.Spacing.large)
                    }
                }
            }
            .navigationTitle(String(localized: "event.participants.title", defaultValue: "Participants"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done", defaultValue: "Done")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
            .onAppear { loadParticipants() }
        }
    }

    // MARK: - Row

    private func participantRow(_ user: UserProfile) -> some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            if !user.profileImageUrl.isEmpty {
                WebImage(url: URL(string: user.profileImageUrl)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    initialsCircle(user.fullName)
                }
                .frame(width: 44, height: 44).clipShape(Circle())
            } else {
                initialsCircle(user.fullName)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                if !user.role.isEmpty {
                    Text(user.role)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if user.id.uuidString != currentUserId {
                if removingId == user.id.uuidString {
                    ProgressView().tint(.error)
                } else {
                    Button(action: { removeParticipant(user) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .glassSurface(.regular, shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
    }

    private func initialsCircle(_ name: String) -> some View {
        Circle()
            .fill(Color.brandPrimary.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay(Text(String(name.prefix(1)))
                .font(.system(size: 18, weight: .bold)).foregroundColor(.brandPrimary))
    }

    // MARK: - Actions

    private func loadParticipants() {
        isLoading = true
        // Fetch fresh event data so we always see the most up-to-date participant list,
        // even if someone joined/left since this sheet was opened.
        calendarRepo.fetchEndeavourEvent(eventId: event.id) { result in
            let ids: [String]
            switch result {
            case .success(let freshEvent): ids = freshEvent.participantIds
            case .failure:                 ids = event.participantIds  // fallback to local
            }
            guard !ids.isEmpty else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            var loaded: [UserProfile] = []
            let group = DispatchGroup()
            for id in ids {
                group.enter()
                userRepo.fetchUserProfile(userId: id) { profileResult in
                    if case .success(let p) = profileResult { loaded.append(p) }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                participants = loaded.sorted { $0.fullName < $1.fullName }
                isLoading = false
            }
        }
    }

    private func removeParticipant(_ user: UserProfile) {
        let userId = user.id.uuidString
        removingId = userId
        calendarRepo.removeParticipantFromEvent(eventId: event.id, userId: userId) { _ in
            DispatchQueue.main.async {
                removingId = nil
                participants.removeAll { $0.id == user.id }
                onChanged?()
            }
        }
    }
}
