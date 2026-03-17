import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var conversationsViewModel: ConversationsViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    @AppStorage("userId") private var currentUserId: String = ""
    @State private var showCalendar = false

    // For scroll-based animations
    @State private var scrollOffset: CGFloat = 0
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<18: return "Good afternoon!"
        case 18..<22: return "Good evening!"
        default: return "Good night!"
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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.Spacing.standard) {
                                    ForEach(calendarViewModel.upcomingEvents.prefix(5)) { event in
                                        UpcomingEventCard(event: event)
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.large)
                                .padding(.bottom, DesignSystem.Spacing.medium)
                            }
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

    var color: Color {
        switch event.type {
        case .meeting: return .brandPrimary
        case .endeavorEvent: return .purple
        case .mentorship: return .orange
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            HStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: event.type.icon).foregroundColor(color))
                Spacer()
                Image(systemName: "ellipsis").foregroundColor(.secondary)
            }
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(event.startDate.formatted(.dateTime.weekday(.abbreviated).day().hour().minute()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Circle().fill(event.status == .confirmed ? Color.success : Color.orange).frame(width: 6, height: 6)
                    Text(event.status == .confirmed
                        ? String(localized: "home.confirmed")
                        : String(localized: "calendar.pending", defaultValue: "Pending"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(event.status == .confirmed ? .success : .orange)
                }
                .padding(.top, 4)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(width: 220)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge)
            .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppViewModel())
            .environmentObject(ConversationsViewModel())
    }
}
