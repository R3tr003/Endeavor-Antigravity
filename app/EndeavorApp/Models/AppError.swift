import Foundation

public enum AppError: LocalizedError, Equatable {
    case networkUnavailable
    case authFailed(reason: String)
    case dataCorrupted
    case userNotFound
    case weakPassword
    case emailAlreadyInUse
    case notAuthorized
    case salesforceUnavailable
    case serviceUnavailable
    case unknown(reason: String?)
    
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network timeout. Please check your connection."
        case .authFailed(let reason):
            return reason
        case .dataCorrupted:
            return "The data could not be read or is corrupted."
        case .userNotFound:
            return "No account found with this email."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .emailAlreadyInUse:
            return "This email is already registered. Please login instead."
        case .notAuthorized:
            return "This email is not registered in the Endeavor network. Contact your local Endeavor office at help@endeavor.org"
        case .salesforceUnavailable:
            return "Unable to verify authorization. Please check your connection and try again."
        case .serviceUnavailable:
            return "Service unavailable. Please check your connection and try again."
        case .unknown(let reason):
            return reason ?? "An unknown error occurred. Please try again."
        }
    }
}
