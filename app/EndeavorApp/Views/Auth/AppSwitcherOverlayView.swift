import SwiftUI
import LocalAuthentication

/// Shown in the app switcher (on .inactive) to hide content and communicate biometric requirement.
struct AppSwitcherOverlayView: View {

    let biometricService: BiometricAuthService
    let isLoggedIn: Bool

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            if biometricService.isBiometricEnabled && isLoggedIn {
                VStack(spacing: DesignSystem.Spacing.standard) {
                    Image(systemName: biometricService.biometricIconName)
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white)

                    Text(overlayMessage)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xLarge)
                }
            }
        }
    }

    private var overlayMessage: String {
        switch biometricService.biometricType {
        case .touchID:
            return String(localized: "settings.switcher_touch_id_required",
                          defaultValue: "Touch ID Required\nto open Endeavor")
        default:
            return String(localized: "settings.switcher_face_id_required",
                          defaultValue: "Face ID Required\nto open Endeavor")
        }
    }
}
