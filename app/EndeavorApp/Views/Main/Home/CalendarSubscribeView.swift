import SwiftUI
import FirebaseAuth

struct CalendarSubscribeView: View {
    let userId: String
    @Environment(\.dismiss) var dismiss
    @State private var feedUrl: String = ""
    @State private var isCopied = false
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {

                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text(String(localized: "calendar.subscribe_title",
                                        defaultValue: "Add to Your Calendar"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(String(localized: "calendar.subscribe_subtitle",
                                        defaultValue: "Subscribe to your Endeavor calendar in Google Calendar, Apple Calendar, or Outlook. Events sync automatically."))
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        // Instructions per app
                        VStack(spacing: DesignSystem.Spacing.small) {
                            subscribeInstructionRow(
                                icon: googleIcon,
                                title: "Google Calendar",
                                steps: String(localized: "calendar.google_steps",
                                              defaultValue: "Open Google Calendar → + Other calendars → From URL → Paste the link")
                            )
                            subscribeInstructionRow(
                                icon: appleIcon,
                                title: "Apple Calendar",
                                steps: String(localized: "calendar.apple_steps",
                                              defaultValue: "Open Calendar app → File → New Calendar Subscription → Paste the link")
                            )
                            subscribeInstructionRow(
                                icon: outlookIcon,
                                title: "Outlook",
                                steps: String(localized: "calendar.outlook_steps",
                                              defaultValue: "Open Outlook → Add calendar → From internet → Paste the link")
                            )
                        }

                        // Feed URL
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text(String(localized: "calendar.your_link", defaultValue: "Your calendar link"))
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1.2)

                            if feedUrl.isEmpty {
                                Button(action: generateFeedUrl) {
                                    HStack {
                                        if isGenerating {
                                            ProgressView().tint(.white)
                                        } else {
                                            Image(systemName: "link")
                                            Text(String(localized: "calendar.generate_link",
                                                        defaultValue: "Generate my calendar link"))
                                        }
                                    }
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.standard)
                                    .background(Color.brandPrimary, in: Capsule())
                                }
                                .disabled(isGenerating)
                            } else {
                                HStack(spacing: DesignSystem.Spacing.small) {
                                    Text(feedUrl)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.7)
                                    Spacer()
                                    Button(action: {
                                        UIPasteboard.general.string = feedUrl
                                        AnalyticsService.shared.logCalendarICalLinkCopied()
                                        withAnimation { isCopied = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation { isCopied = false }
                                        }
                                    }) {
                                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 16))
                                            .foregroundColor(isCopied ? .success : .brandPrimary)
                                    }
                                }
                                .padding(DesignSystem.Spacing.standard)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .stroke(isCopied ? Color.success.opacity(0.4) : Color.borderGlare.opacity(0.15), lineWidth: 1))

                                if isCopied {
                                    Text(String(localized: "calendar.copied", defaultValue: "Copied to clipboard!"))
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.success)
                                }
                            }
                        }

                        // Nota privacy
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(String(localized: "calendar.privacy_note",
                                        defaultValue: "This link is personal and private. Only your Endeavor events are included — never your other calendar entries."))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
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
            .onAppear {
                AnalyticsService.shared.logCalendarSubscribeSheetOpened()
            }
        }
    }

    private func generateFeedUrl() {
        isGenerating = true
        guard let user = Auth.auth().currentUser else {
            isGenerating = false
            return
        }
        user.getIDTokenForcingRefresh(false) { token, _ in
            DispatchQueue.main.async {
                isGenerating = false
                guard let token = token else { return }
                let baseUrl = "https://europe-west1-endeavor-app-prod.cloudfunctions.net/icalFeed"
                feedUrl = "\(baseUrl)?userId=\(userId)&token=\(token)"
                AnalyticsService.shared.logCalendarICalLinkGenerated()
            }
        }
    }

    // MARK: - Brand Icons

    private var googleIcon: some View {
        Image("BrandGoogle")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
    }

    private var appleIcon: some View {
        Image("BrandApple")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
    }

    private var outlookIcon: some View {
        Image("BrandOutlook")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
    }

    private func subscribeInstructionRow<Icon: View>(icon: Icon, title: String, steps: String) -> some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.standard) {
            icon
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(steps)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.borderGlare.opacity(0.12), lineWidth: 1))
    }
}
