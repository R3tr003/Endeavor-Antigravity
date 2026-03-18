import FirebaseAnalytics

/// Centralized analytics service — wraps FirebaseAnalytics with typed methods.
/// All event names and parameter keys are defined as constants to prevent typos.
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - User Identity

    /// Sets the stable user ID for Firebase Analytics so that retention, funnels,
    /// and audience metrics can correctly link sessions to the same person.
    /// Call after every successful login or session restore.
    func setUserID(_ userId: String) {
        Analytics.setUserID(userId)
    }

    /// Clears the user ID on logout so that subsequent events are not attributed
    /// to the previous user (important on shared devices).
    func clearUserID() {
        Analytics.setUserID(nil)
        Analytics.setUserProperty(nil, forName: "user_type")
        Analytics.setUserProperty(nil, forName: "user_nationality")
        // New user properties — must be cleared on logout to avoid cross-user data
        Analytics.setUserProperty(nil, forName: "user_language")
        Analytics.setUserProperty(nil, forName: "has_profile_image")
        Analytics.setUserProperty(nil, forName: "onboarding_version")
    }

    /// Sets persistent user properties so Firebase Analytics can segment audiences.
    /// - Parameters:
    ///   - userType: Platform role (Entrepreneur, Mentor, Investor, Staff).
    ///   - nationality: User's country of origin.
    ///   - primaryLanguage: First language from the user's `languages` array (or "" if empty).
    ///   - hasProfileImage: Whether the user has uploaded a profile image.
    ///   - onboardingVersion: Onboarding flow version, e.g. "v1". Useful for A/B testing future flows.
    func setUserProperties(
        userType: String,
        nationality: String,
        primaryLanguage: String = "",
        hasProfileImage: Bool = false,
        onboardingVersion: String = "v1"
    ) {
        if !userType.isEmpty {
            Analytics.setUserProperty(userType, forName: "user_type")
        }
        if !nationality.isEmpty {
            Analytics.setUserProperty(nationality, forName: "user_nationality")
        }
        if !primaryLanguage.isEmpty {
            Analytics.setUserProperty(primaryLanguage, forName: "user_language")
        }
        Analytics.setUserProperty(hasProfileImage ? "true" : "false", forName: "has_profile_image")
        Analytics.setUserProperty(onboardingVersion, forName: "onboarding_version")
    }

    // MARK: - Auth

    /// Called after successful email/password or Google login.
    func logLogin(method: LoginMethod) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method.rawValue
        ])
    }

    /// Called after a brand-new user account is created.
    func logSignUp(method: LoginMethod) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method.rawValue
        ])
    }

    /// Called on explicit logout.
    func logLogout() {
        Analytics.logEvent("logout", parameters: nil)
    }

    // MARK: - Onboarding

    /// Called when the user taps "Next" on an onboarding step.
    func logOnboardingStepCompleted(step: Int, stepName: String) {
        Analytics.logEvent("onboarding_step_completed", parameters: [
            "step_number": step,
            "step_name": stepName
        ])
    }

    /// Called when the onboarding flow completes and the profile is saved.
    func logOnboardingCompleted(userType: String, role: String) {
        Analytics.logEvent("onboarding_completed", parameters: [
            "user_type": userType,
            "role": role
        ])
    }

    /// Called when the user taps "Exit" during onboarding.
    func logOnboardingAbandoned(atStep step: Int) {
        Analytics.logEvent("onboarding_abandoned", parameters: [
            "step_number": step
        ])
    }

    // MARK: - Profile

    /// Called when the user uploads or changes their profile image.
    func logProfileImageUploaded() {
        Analytics.logEvent("profile_image_uploaded", parameters: nil)
    }

    /// Called when the user saves edits from EditProfileView.
    func logProfileEdited() {
        Analytics.logEvent("profile_edited", parameters: nil)
    }

    // MARK: - Network

    /// Called when the user sends a connection request.
    func logConnectionRequestSent() {
        Analytics.logEvent("connection_request_sent", parameters: nil)
    }

    // MARK: - Messages

    enum MessageType: String {
        case text        = "text"
        case image       = "image"
        case document    = "document"
        case textImage   = "text_image"
        case textDocument = "text_document"
    }

    /// Called when the user sends a message. Tracks type and rough length bucket.
    func logMessageSent(type: MessageType, characterCount: Int) {
        let lengthBucket: String
        switch characterCount {
        case 0:        lengthBucket = "media_only"
        case 1...50:   lengthBucket = "short"
        case 51...200: lengthBucket = "medium"
        default:       lengthBucket = "long"
        }
        Analytics.logEvent("message_sent", parameters: [
            "message_type": type.rawValue,
            "length_bucket": lengthBucket
        ])
    }

    /// Conversion event — called the very first time a user sends any message.
    /// Mark this as a conversion in Firebase Console → Analytics → Events → Conversions.
    func logFirstMessageSent() {
        Analytics.logEvent("first_message_sent", parameters: nil)
    }

    /// Called when a new conversation is created (first message to a new contact).
    func logConversationCreated() {
        Analytics.logEvent("conversation_created", parameters: nil)
    }

    /// Called when the user opens a conversation thread (logged after first message batch loads).
    func logConversationOpened() {
        Analytics.logEvent("conversation_opened", parameters: nil)
    }

    /// Called when the user deletes a conversation.
    func logConversationDeleted() {
        Analytics.logEvent("conversation_deleted", parameters: nil)
    }

    /// Called when the user pins or unpins a conversation.
    func logConversationPinToggled(isPinned: Bool) {
        Analytics.logEvent("conversation_pin_toggled", parameters: [
            "action": isPinned ? "pinned" : "unpinned"
        ])
    }

    /// Called when a media file is uploaded and sent in a conversation.
    func logMediaUploaded(type: String) {
        Analytics.logEvent("chat_media_uploaded", parameters: [
            "media_type": type  // "image" | "document"
        ])
    }

    /// Called when the user reads messages in an open conversation (fires once per open).
    func logMessagesRead() {
        Analytics.logEvent("messages_read", parameters: nil)
    }

    // MARK: - Discover

    /// Called when the user opens a mentor/user detail card.
    func logProfileViewed(userId: String) {
        Analytics.logEvent("profile_viewed", parameters: [
            AnalyticsParameterItemID: userId
        ])
    }

    /// Called when the user spent time viewing a profile before closing it.
    /// Useful to understand intent before a message is sent.
    /// - Parameters:
    ///   - seconds: How long the profile was open, in seconds.
    ///   - userId: The ID of the profile being viewed.
    func logProfileViewDuration(seconds: Int, userId: String) {
        Analytics.logEvent("profile_view_duration", parameters: [
            "view_duration_seconds": seconds,
            AnalyticsParameterItemID: userId
        ])
    }

    // MARK: - Salesforce

    /// Called when Salesforce pre-fill data is applied to onboarding.
    func logSalesforcePrefillApplied() {
        Analytics.logEvent("salesforce_prefill_applied", parameters: nil)
    }

    // MARK: - Meetings

    /// Called when the user opens the scheduling sheet (pre-conditions met).
    func logMeetingScheduleOpened(conversationMessageCount: Int) {
        Analytics.logEvent("meeting_schedule_opened", parameters: [
            "conversation_message_count": conversationMessageCount
        ])
    }

    /// Called when the Schedule button is tapped but pre-conditions are not met.
    func logMeetingScheduleBlocked(messageCount: Int, myCount: Int, theirCount: Int) {
        Analytics.logEvent("meeting_schedule_blocked", parameters: [
            "total_messages": messageCount,
            "sender_messages": myCount,
            "recipient_messages": theirCount
        ])
    }

    /// Called when a meeting invite is sent successfully.
    func logMeetingInviteSent(durationMinutes: Int, provider: String) {
        Analytics.logEvent("meeting_invite_sent", parameters: [
            "duration_minutes": durationMinutes,
            "video_provider": provider
        ])
    }

    /// Conversion event — called the first time a user schedules a meeting.
    /// Mark this as a conversion in Firebase Console → Analytics → Events → Conversions.
    func logFirstMeetingScheduled() {
        Analytics.logEvent("first_meeting_scheduled", parameters: nil)
    }

    /// Key funnel metric — how many messages were exchanged before the first meeting was scheduled.
    /// Helps understand conversation depth needed to convert to a meeting.
    func logMeetingToMessageRatio(messageCount: Int) {
        Analytics.logEvent("meeting_to_message_ratio", parameters: [
            "message_count_at_scheduling": messageCount
        ])
    }

    /// Called when the recipient accepts a meeting invite.
    func logMeetingAccepted(provider: String) {
        Analytics.logEvent("meeting_accepted", parameters: [
            "video_provider": provider
        ])
    }

    /// Called when the recipient declines a meeting invite.
    func logMeetingDeclined() {
        Analytics.logEvent("meeting_declined", parameters: nil)
    }

    /// Called when the recipient proposes a new time.
    func logMeetingNewTimeProposed() {
        Analytics.logEvent("meeting_new_time_proposed", parameters: nil)
    }

    /// Called when the user taps "Join Meeting" to open Google Meet or Teams.
    func logMeetingJoinLinkOpened(provider: String) {
        Analytics.logEvent("meeting_join_link_opened", parameters: [
            "video_provider": provider
        ])
    }

    /// Called when a confirmed meeting's start time has passed — indicates meeting likely took place.
    /// Triggered client-side from CalendarView when the user has confirmed events in the past.
    func logMeetingCompleted(provider: String, durationMinutes: Int) {
        Analytics.logEvent("meeting_completed", parameters: [
            "video_provider": provider,
            "duration_minutes": durationMinutes
        ])
    }

    // MARK: - AI Filter

    /// Called when a conversation is filtered as spam by the AI (trigger or recheck).
    func logConversationFilteredByAI(isRecheck: Bool) {
        Analytics.logEvent("conversation_ai_filtered", parameters: [
            "trigger": isRecheck ? "recheck" : "first_message"
        ])
    }

    /// Called when the user opens the Filtered tab.
    func logFilteredConversationsViewed(count: Int) {
        Analytics.logEvent("filtered_conversations_viewed", parameters: [
            "filtered_count": count
        ])
    }

    /// Called when the user marks a filtered conversation as "Not Spam".
    func logConversationUnfiltered() {
        Analytics.logEvent("conversation_unfiltered", parameters: nil)
    }

    /// Called when the AI recheck is triggered before the Schedule button.
    func logAIRecheckTriggered() {
        Analytics.logEvent("ai_recheck_triggered", parameters: nil)
    }

    // MARK: - Calendar

    /// Called when the user opens CalendarView.
    func logCalendarOpened() {
        Analytics.logEvent("calendar_opened", parameters: nil)
    }

    /// Called when the user navigates to a different month.
    func logCalendarMonthChanged() {
        Analytics.logEvent("calendar_month_changed", parameters: nil)
    }

    /// Called when the user opens an event detail sheet.
    func logCalendarEventOpened(eventType: String) {
        Analytics.logEvent("calendar_event_opened", parameters: [
            "event_type": eventType
        ])
    }

    /// Called when the iCal subscribe sheet is opened.
    func logCalendarSubscribeSheetOpened() {
        Analytics.logEvent("calendar_subscribe_sheet_opened", parameters: nil)
    }

    /// Called when the user generates their personal iCal link.
    func logCalendarICalLinkGenerated() {
        Analytics.logEvent("calendar_ical_link_generated", parameters: nil)
    }

    /// Called when the user copies the iCal link to clipboard.
    func logCalendarICalLinkCopied() {
        Analytics.logEvent("calendar_ical_link_copied", parameters: nil)
    }

    // MARK: - Discover (AI Search)

    /// Called when the user submits an AI search query.
    func logAISearchPerformed(queryLength: Int) {
        let bucket: String
        switch queryLength {
        case 0...20:  bucket = "short"
        case 21...80: bucket = "medium"
        default:      bucket = "long"
        }
        Analytics.logEvent("ai_search_performed", parameters: [
            "query_length_bucket": bucket
        ])
    }

    /// Called when AI search results are shown.
    func logAISearchResultsShown(resultCount: Int) {
        Analytics.logEvent("ai_search_results_shown", parameters: [
            "result_count": resultCount
        ])
    }

    /// Called when the user taps a search result.
    func logAISearchResultTapped(rank: Int) {
        Analytics.logEvent("ai_search_result_tapped", parameters: [
            "result_rank": rank
        ])
    }

    /// Called when the AI search fails.
    func logAISearchFailed(reason: String) {
        Analytics.logEvent("ai_search_failed", parameters: [
            "failure_reason": reason
        ])
    }

    // MARK: - Funnel: Search → Message

    /// Key funnel metric — called when the user taps "Connect" on an AI search result,
    /// i.e. they performed a search and then opened a conversation. Tracks the full
    /// search-to-message funnel without needing BigQuery joins.
    func logSearchToMessage(queryLengthBucket: String) {
        Analytics.logEvent("search_to_message", parameters: [
            "query_length_bucket": queryLengthBucket
        ])
    }

    // MARK: - Session

    /// Called when MainTabView disappears (app backgrounded / session ends).
    /// Tracks the number of unique top-level tabs visited — a proxy for session engagement depth.
    func logSessionDepth(screensVisited: Int) {
        Analytics.logEvent("session_depth", parameters: [
            "unique_screens_count": screensVisited
        ])
    }

    // MARK: - App Open Source

    /// Called on every app open to track how users returned to the app.
    /// - Parameter source: One of "cold_start", "background", "push_notification".
    func logAppOpenSource(source: AppOpenSource) {
        Analytics.logEvent("app_open_source", parameters: [
            "open_source": source.rawValue
        ])
    }
}

// MARK: - Login Method

enum LoginMethod: String {
    case email = "email"
    case google = "google"
    case apple = "apple"
}

// MARK: - App Open Source

enum AppOpenSource: String {
    case coldStart       = "cold_start"
    case background      = "background"
    case pushNotification = "push_notification"
}
