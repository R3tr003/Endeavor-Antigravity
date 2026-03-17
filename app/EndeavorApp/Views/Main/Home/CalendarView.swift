import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel = CalendarViewModel()
    @AppStorage("userId") private var currentUserId: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: CalendarEvent? = nil
    @State private var showSubscribeSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.background.edgesIgnoringSafeArea(.all)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {

                    // Header row: X | Calendar | Share
                    HStack(spacing: DesignSystem.Spacing.standard) {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                        Text(String(localized: "nav.calendar", defaultValue: "Calendar"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { showSubscribeSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.brandPrimary)
                                .frame(width: 40, height: 40)
                                .background(Color.brandPrimary.opacity(0.12), in: Circle())
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, DesignSystem.Spacing.standard)

                    // Month grid
                    MonthCalendarGrid(
                            selectedDate: $viewModel.selectedDate,
                            daysWithEventColors: viewModel.daysWithEventColors
                        )
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.top, DesignSystem.Spacing.standard)

                        // Lista eventi del giorno selezionato
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            let dayLabel = Calendar.current.isDateInToday(viewModel.selectedDate)
                                ? String(localized: "calendar.today", defaultValue: "Today")
                                : viewModel.selectedDate.formatted(.dateTime.weekday(.wide).day().month())

                            Text(dayLabel)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.horizontal, DesignSystem.Spacing.large)

                            if viewModel.isLoading {
                                ProgressView().tint(.brandPrimary)
                                    .frame(maxWidth: .infinity)
                            } else if viewModel.eventsForSelectedDate.isEmpty {
                                emptyDayView
                            } else {
                                VStack(spacing: DesignSystem.Spacing.small) {
                                    ForEach(viewModel.eventsForSelectedDate) { event in
                                        CalendarEventRow(event: event)
                                            .onTapGesture { selectedEvent = event }
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.large)
                            }
                        }

                    Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                }
            }
        }
        .onAppear {
            if !currentUserId.isEmpty {
                viewModel.fetchEvents(userId: currentUserId)
            }
        }
        .sheet(item: $selectedEvent) { event in
            CalendarEventDetailView(event: event)
        }
        .sheet(isPresented: $showSubscribeSheet) {
            CalendarSubscribeView(userId: currentUserId)
        }
    }

    private var emptyDayView: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(String(localized: "calendar.no_events", defaultValue: "No events this day"))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xLarge)
    }
}

// MARK: - Month Grid

struct MonthCalendarGrid: View {
    @Binding var selectedDate: Date
    var daysWithEventColors: [Int: [Color]]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Month navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.brandPrimary)
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.brandPrimary)
                        .frame(width: 36, height: 36)
                }
            }

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        let day = calendar.component(.day, from: date)
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            eventColors: daysWithEventColors[day] ?? []
                        )
                        .onTapGesture { selectedDate = date }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
    }

    private func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingNils = Array(repeating: nil as Date?, count: firstWeekday - 1)
        let days = range.map { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
        return leadingNils + days
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let eventColors: [Color]

    var body: some View {
        VStack(spacing: 3) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : isToday ? .brandPrimary : .primary)
                .frame(width: 36, height: 36)
                .background(
                    isSelected ? Color.brandPrimary :
                    isToday ? Color.brandPrimary.opacity(0.12) :
                    Color.clear,
                    in: Circle()
                )

            // Colored dots — up to 3, one per event type
            HStack(spacing: 3) {
                ForEach(Array(eventColors.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.9) : color)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Event Row

struct CalendarEventRow: View {
    let event: CalendarEvent

    var eventColor: Color {
        switch event.type {
        case .meeting: return .brandPrimary
        case .endeavorEvent: return .purple
        case .mentorship: return .orange
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            RoundedRectangle(cornerRadius: 2)
                .fill(eventColor)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.small) {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(event.durationFormatted)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(event.type.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(eventColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(eventColor.opacity(0.12), in: Capsule())
        }
        .padding(DesignSystem.Spacing.standard)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Event Detail

struct CalendarEventDetailView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {

                        HStack {
                            Image(systemName: event.type.icon)
                            Text(event.type.displayName)
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(event.type == .meeting ? .brandPrimary : event.type == .endeavorEvent ? .purple : .orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((event.type == .meeting ? Color.brandPrimary : event.type == .endeavorEvent ? Color.purple : Color.orange).opacity(0.12), in: Capsule())

                        Text(event.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: DesignSystem.Spacing.small) {
                            detailRow(icon: "clock", text: "\(event.startDate.formatted(.dateTime.weekday(.wide).day().month().hour().minute())) · \(event.durationFormatted)")
                            if let location = event.location, !location.isEmpty {
                                detailRow(icon: "mappin", text: location)
                            }
                            if !event.description.isEmpty {
                                detailRow(icon: "text.alignleft", text: event.description)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.large)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done", defaultValue: "Done")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.standard) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.brandPrimary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(DesignSystem.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
    }
}
