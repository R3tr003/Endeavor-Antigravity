import FirebaseAnalytics

/// Centralized analytics service — wraps FirebaseAnalytics with typed methods.
/// All event names and parameter keys are defined as constants to prevent typos.
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

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

    /// Called when the user sends a message.
    func logMessageSent(hasAttachment: Bool) {
        Analytics.logEvent("message_sent", parameters: [
            "has_attachment": hasAttachment
        ])
    }

    /// Called when the user opens a conversation thread.
    func logConversationOpened() {
        Analytics.logEvent("conversation_opened", parameters: nil)
    }

    // MARK: - Discover

    /// Called when the user opens a mentor/user detail card.
    func logProfileViewed(userId: String) {
        Analytics.logEvent("profile_viewed", parameters: [
            AnalyticsParameterItemID: userId
        ])
    }

    // MARK: - Salesforce

    /// Called when Salesforce pre-fill data is applied to onboarding.
    func logSalesforcePrefillApplied() {
        Analytics.logEvent("salesforce_prefill_applied", parameters: nil)
    }
}

// MARK: - Login Method

enum LoginMethod: String {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
