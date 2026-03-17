import Foundation

// MARK: - AppError

public enum AppError: LocalizedError, Equatable {

    // MARK: Network
    case networkUnavailable

    // MARK: Auth
    case authFailed(reason: String)
    case incorrectPassword
    case registrationFailed
    case passwordResetFailed
    case userNotFound
    case weakPassword
    case emailAlreadyInUse
    case notAuthorized
    case salesforceUnavailable
    case serviceUnavailable

    // MARK: Data
    case dataCorrupted

    // MARK: Profile
    case profileSaveFailed
    case imageUploadFailed
    case imageRemoveFailed

    // MARK: Conversations
    case conversationDeleteFailed
    case conversationUpdateFailed

    // MARK: Meetings
    case meetingSaveFailed
    case meetingInviteFailed
    case meetingUpdateFailed

    // MARK: Generic
    case unknown(reason: String?)
}

// MARK: - LocalizedError

extension AppError {

    public var errorDescription: String? {
        switch self {

        // MARK: Network
        case .networkUnavailable:
            return String(localized: "error.network_unavailable",
                          defaultValue: "Network timeout. Please check your connection.")

        // MARK: Auth
        case .authFailed(let reason):
            return reason
        case .incorrectPassword:
            return String(localized: "error.incorrect_password",
                          defaultValue: "Incorrect password. Please try again.")
        case .registrationFailed:
            return String(localized: "error.registration_failed",
                          defaultValue: "Registration failed. Please try again.")
        case .passwordResetFailed:
            return String(localized: "error.reset_email_failed",
                          defaultValue: "Could not send password reset email. Please try again.")
        case .userNotFound:
            return String(localized: "error.user_not_found",
                          defaultValue: "No account found with this email.")
        case .weakPassword:
            return String(localized: "error.weak_password",
                          defaultValue: "Password too weak. Use at least 6 characters.")
        case .emailAlreadyInUse:
            return String(localized: "error.email_in_use",
                          defaultValue: "This email is already registered. Try logging in instead.")
        case .notAuthorized:
            return String(localized: "error.not_authorized",
                          defaultValue: "This email isn't registered in the Endeavor network. Contact help@endeavor.org")
        case .salesforceUnavailable:
            return String(localized: "error.salesforce_unavailable",
                          defaultValue: "Unable to verify your account. Check your connection and try again.")
        case .serviceUnavailable:
            return String(localized: "error.service_unavailable",
                          defaultValue: "Service temporarily unavailable. Please try again.")

        // MARK: Data
        case .dataCorrupted:
            return String(localized: "error.data_corrupted",
                          defaultValue: "The data could not be read. Please try again.")

        // MARK: Profile
        case .profileSaveFailed:
            return String(localized: "error.save_profile_failed",
                          defaultValue: "Could not save your changes. Please try again.")
        case .imageUploadFailed:
            return String(localized: "error.upload_image_failed",
                          defaultValue: "Could not upload your photo. Please try again.")
        case .imageRemoveFailed:
            return String(localized: "error.remove_image_failed",
                          defaultValue: "Could not remove your photo. Please try again.")

        // MARK: Conversations
        case .conversationDeleteFailed:
            return String(localized: "messages.error_delete_conversation",
                          defaultValue: "Could not delete this conversation. Please try again.")
        case .conversationUpdateFailed:
            return String(localized: "messages.error_update_conversation",
                          defaultValue: "Could not update this conversation. Please try again.")

        // MARK: Meetings
        case .meetingSaveFailed:
            return String(localized: "schedule.error_save_failed",
                          defaultValue: "Could not create the meeting. Please try again.")
        case .meetingInviteFailed:
            return String(localized: "schedule.error_send_failed",
                          defaultValue: "Meeting created, but the invite could not be sent. Please try again.")
        case .meetingUpdateFailed:
            return String(localized: "schedule.error_update_failed",
                          defaultValue: "Could not update the meeting. Please try again.")

        // MARK: Generic
        case .unknown(let reason):
            return reason ?? String(localized: "error.unknown",
                                    defaultValue: "Something went wrong. Please try again.")
        }
    }
}
