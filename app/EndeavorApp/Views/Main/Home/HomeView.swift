import SwiftUI
import SDWebImageSwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var conversationsViewModel: ConversationsViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    @AppStorage("userId") private var currentUserId: String = ""
    @State private var showCalendar = false
    @State private var selectedEvent: CalendarEvent? = nil
    @State private var rescheduleEvent: CalendarEvent? = nil

    // For scroll-based animations
    @State private var scrollOffset: CGFloat = 0

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "home.greeting_morning", defaultValue: "Good morning!")
        case 12..<18: return String(localized: "home.greeting_afternoon", defaultValue: "Good afternoon!")
        case 18..<22: return String(localized: "home.greeting_evening", defaultValue: "Good evening!")
        default: return String(localized: "home.greeting_night", defaultValue: "Good night!")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.background.edgesIgnoringSafeArea(.all)

            // Top ambient glow for modern aesthetic
            Circle()
                .fill(Color.brandPrimary.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -50, y: -200)
                .ignoresSafeArea()

            Circle()
                .fill(Color.brandPrimary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {

                    // 1. Header — Personal Greeting
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                        Text(timeBasedGreeting)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("\(appViewModel.currentUser?.firstName ?? "User")")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(-1)
                        Text(String(localized: "home.sessions_subtitle"))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, DesignSystem.Spacing.standard)
                    .padding(.horizontal, DesignSystem.Spacing.large)

                    // 2. Calendar Card
                    Button(action: { showCalendar = true }) {
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            // Left: icon + label + count
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                                HStack(spacing: DesignSystem.Spacing.xSmall) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.purple)
                                    Text(String(localized: "home.events_this_week"))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Text("\(calendarViewModel.upcomingEvents.filter { Calendar.current.isDate($0.startDate, equalTo: Date(), toGranularity: .weekOfYear) }.count)")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .tracking(-1)
                                Text(String(localized: "home.events_scheduled", defaultValue: "events scheduled"))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            // Right: open button
                            VStack {
                                Spacer()
                                Text(String(localized: "home.open_calendar", defaultValue: "Open Calendar"))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DesignSystem.Spacing.standard)
                                    .padding(.vertical, DesignSystem.Spacing.xSmall)
                                    .background(Color.purple, in: Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DesignSystem.Spacing.medium)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DesignSystem.Spacing.large)

                    // 3. Smart Recommendations
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                        Text(String(localized: "home.recommended"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.large)

                        VStack(spacing: DesignSystem.Spacing.small) {
                            RecommendationCard(
                                icon: "person.fill",
                                color: .brandPrimary,
                                title: "Maria Lopez",
                                subtitle: "SaaS Scaling Expert",
                                pillText: "Mentor"
                            )
                            RecommendationCard(
                                icon: "calendar.badge.plus",
                                color: .purple,
                                title: "CEO Roundtable",
                                subtitle: "Growth Strategies · Thu 3PM",
                                pillText: "Event"
                            )
                            RecommendationCard(
                                icon: "building.2.fill",
                                color: .orange,
                                title: "Carlos Rodriguez",
                                subtitle: "Fintech Founder · Series B",
                                pillText: "Connection"
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    }

                    // 4. Upcoming Sessions
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text(String(localized: "home.upcoming_sessions"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, DesignSystem.Spacing.large)

                        if calendarViewModel.isLoading {
                            ProgressView().tint(.brandPrimary).frame(maxWidth: .infinity)
                        } else if calendarViewModel.upcomingEvents.isEmpty {
                            Text(String(localized: "calendar.no_upcoming", defaultValue: "No upcoming events"))
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, DesignSystem.Spacing.large)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.small) {
                                ForEach(calendarViewModel.upcomingEvents.prefix(5)) { event in
                                    UpcomingEventCard(
                                        event: event,
                                        currentUserId: currentUserId,
                                        onTap: { selectedEvent = event },
                                        onCancel: { calendarViewModel.cancelEvent(eventId: event.id, declinedBy: currentUserId) },
                                        onReschedule: { rescheduleEvent = event }
                                    )
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.standard)

                    Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onAppear {
                if !currentUserId.isEmpty {
                    calendarViewModel.fetchEvents(userId: currentUserId)
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView()
                    .environmentObject(appViewModel)
            }
            .sheet(item: $selectedEvent) { event in
                CalendarEventDetailView(
                    event: event,
                    currentUserId: currentUserId,
                    onCancelledLocally: { calendarViewModel.removeEvent(id: event.id) },
                    onRescheduledLocally: { calendarViewModel.fetchEvents(userId: currentUserId) }
                )
            }
            .sheet(item: $rescheduleEvent) { event in
                ScheduleMeetingView(
                    conversationId: event.conversationId ?? "",
                    currentUserId: currentUserId,
                    recipientId: event.participantIds.first(where: { $0 != currentUserId }) ?? "",
                    recipientName: "",
                    existingEvents: calendarViewModel.upcomingEvents,
                    existingEvent: event
                )
            }

            // Floating Header
            if scrollOffset < -60 {
                VStack {
                    HStack {
                        Text(String(localized: "nav.home")).font(.headline).foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

// MARK: - Subcomponents

struct RecommendationCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let pillText: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            // Circle Icon
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).foregroundColor(color))

            // Text Block
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Pill Label
            Text(pillText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, 6)
                .background(color.opacity(0.15), in: Capsule())
        }
        .padding(DesignSystem.Spacing.standard)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct UpcomingEventCard: View {
    let event: CalendarEvent
    let currentUserId: String
    let onTap: () -> Void
    let onCancel: () -> Void
    let onReschedule: () -> Void

    @State private var participantName: String? = nil
    @State private var participantImageUrl: String? = nil
    @State private var participantCompany: String? = nil
    private let userRepo = FirebaseUserRepository()

    var color: Color {
        switch event.type {
        case .meeting: return .purple
        case .endeavorEvent: return .purple
        case .mentorship: return .orange
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3)
                    .padding(.vertical, DesignSystem.Spacing.standard)

                VStack(alignment: .leading, spacing: 6) {
                    // Title row + status badge
                    HStack(alignment: .center) {
                        Text(event.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(event.status == .confirmed ? Color.success : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(event.status == .confirmed
                                 ? String(localized: "home.confirmed")
                                 : String(localized: "calendar.pending", defaultValue: "Pending"))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(event.status == .confirmed ? .success : .orange)
                        }
                    }

                    // Date and time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(event.startDate.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(event.durationFormatted)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    // Participant row
                    if let name = participantName {
                        HStack(spacing: 6) {
                            if let imgUrl = participantImageUrl, !imgUrl.isEmpty {
                                WebImage(url: URL(string: imgUrl)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(color.opacity(0.2))
                                        .overlay(
                                            Text(String(name.prefix(1)))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(color)
                                        )
                                }
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(color.opacity(0.2))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Text(String(name.prefix(1)))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(color)
                                    )
                            }
                            Text(name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                            if let company = participantCompany {
                                Text("· \(company)")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // Description (optional)
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(DesignSystem.Spacing.standard)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
                .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onCancel) {
                Label(String(localized: "home.cancel_meeting", defaultValue: "Cancel Meeting"), systemImage: "xmark.circle")
            }
            Button(action: onReschedule) {
                Label(String(localized: "home.reschedule", defaultValue: "Reschedule"), systemImage: "calendar.badge.clock")
            }
        }
        .onAppear { fetchParticipant() }
    }

    private func fetchParticipant() {
        guard let otherId = event.participantIds.first(where: { $0 != currentUserId }) else { return }
        userRepo.fetchUserProfile(userId: otherId) { result in
            DispatchQueue.main.async {
                if case .success(let profile) = result {
                    participantName = profile.fullName
                    participantImageUrl = profile.profileImageUrl
                }
            }
        }
        userRepo.fetchCompanyForUser(userId: otherId) { company in
            DispatchQueue.main.async {
                participantCompany = (company?.name.isEmpty == false) ? company?.name : nil
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppViewModel())
            .environmentObject(ConversationsViewModel())
    }
}
