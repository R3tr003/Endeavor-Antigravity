import SwiftUI

struct BiometricLockView: View {

    @StateObject private var biometricService = BiometricAuthService.shared
    let onLogout: () -> Void

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Animated fluid background — same as WelcomeView
            FluidBackgroundView()

            VStack(spacing: DesignSystem.Spacing.xLarge) {

                Spacer()

                // Lock icon with pulse ring
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                            value: isPulsing
                        )

                    Circle()
                        .fill(Color.brandPrimary.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(.brandPrimary)
                }

                VStack(spacing: DesignSystem.Spacing.small) {
                    Text(String(localized: "settings.biometric_lock_title", defaultValue: "App Locked"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(String(localized: "settings.biometric_lock_subtitle", defaultValue: "Authenticate to continue"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Unlock button — manually triggers Face ID / Touch ID
                Button(action: {
                    Task {
                        await biometricService.authenticate(
                            reason: String(localized: "settings.biometric_reason",
                                           defaultValue: "Unlock Endeavor")
                        )
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "lock.open.fill")
                        Text(String(localized: "settings.biometric_unlock", defaultValue: "Unlock"))
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Layout.largeButtonHeight)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, DesignSystem.Spacing.large)

                // Logout fallback
                Button(action: onLogout) {
                    Text(String(localized: "settings.log_out", defaultValue: "Log Out"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, DesignSystem.Spacing.xxLarge)
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
        }
        .onAppear {
            isPulsing = true
            // Note: Face ID is triggered from App.swift scenePhase .active
            // so it fires before the lock screen renders, giving a seamless experience.
            // The Unlock button above handles manual re-triggers.
        }
    }
}
