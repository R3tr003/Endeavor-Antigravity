import Foundation
import Combine
import LocalAuthentication

@MainActor
final class BiometricAuthService: ObservableObject {

    static let shared = BiometricAuthService()

    // MARK: - Published State

    @Published private(set) var isLocked: Bool = false
    @Published private(set) var isBiometricEnabled: Bool = false

    // MARK: - Private

    private let enabledKey = "biometricLockEnabled"

    private init() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        // Start locked on every cold start / app-switcher kill so auth is required on reopen
        isLocked = isBiometricEnabled
    }

    // MARK: - Public API

    /// Called when the app enters background.
    func lockIfEnabled() {
        guard isBiometricEnabled else { return }
        isLocked = true
    }

    /// Triggers biometric prompt. Returns true on success.
    /// Uses .deviceOwnerAuthenticationWithBiometrics so Face ID fires via Dynamic Island.
    /// Falls back to passcode-based policy only if biometrics are locked out.
    @discardableResult
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available — fall back to passcode sheet
            return await authenticateWithPasscode(reason: reason)
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success { isLocked = false }
            return success
        } catch let err as LAError where err.code == .biometryLockout {
            // Face ID locked out after too many failures — offer passcode
            return await authenticateWithPasscode(reason: reason)
        } catch {
            return false
        }
    }

    /// Enables biometric lock. Immediately prompts to verify the device supports it.
    /// Returns true if successfully enabled.
    @discardableResult
    func enableBiometric(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                isBiometricEnabled = true
                UserDefaults.standard.set(true, forKey: enabledKey)
            }
            return success
        } catch {
            return false
        }
    }

    // Passcode fallback — only reached when biometrics are unavailable or locked out.
    private func authenticateWithPasscode(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success { isLocked = false }
            return success
        } catch {
            return false
        }
    }

    /// Disables biometric lock.
    func disableBiometric() {
        isBiometricEnabled = false
        isLocked = false
        UserDefaults.standard.set(false, forKey: enabledKey)
    }

    /// Called on logout — disables and unlocks.
    func resetOnLogout() {
        disableBiometric()
    }

    // MARK: - Biometric Type

    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    /// SF Symbol name for the available biometric type.
    var biometricIconName: String {
        switch biometricType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        default:       return "lock.fill"
        }
    }
}
