import SwiftUI

/// Mostra le spunte di stato (✓ / ✓✓ grigie / ✓✓ blu) sotto le bolle in uscita,
/// esattamente come WhatsApp.
struct ReceiptStatusView: View {
    let status: Message.ReceiptStatus

    var body: some View {
        switch status {
        case .sent:
            // Una spunta grigia — consegnato al server
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

        case .delivered:
            // Due spunte grigie — destinatario ha aperto la chat
            doubleCheckmark(color: .secondary)

        case .read:
            // Due spunte blu — destinatario ha letto
            doubleCheckmark(color: Color.brandPrimary)
        }
    }

    @ViewBuilder
    private func doubleCheckmark(color: Color) -> some View {
        HStack(spacing: -4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
