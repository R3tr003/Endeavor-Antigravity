import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var isHighlighted: Bool
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(isHighlighted ? .brandPrimary : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.error)
                }
            }
            
            ZStack(alignment: .leading) {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 16)
                    .opacity(text.isEmpty && !isHighlighted ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                
                if isSecure {
                    SecureField("", text: $text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .textContentType(.none)
                } else {
                    TextField("", text: $text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .URL ? .never : .sentences)
                        .autocorrectionDisabled(keyboardType == .URL)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: isHighlighted ? Color.brandPrimary.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isHighlighted ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: isHighlighted ? 2 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            )
        }
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTextField(title: "First Name", placeholder: "e.g., John", text: .constant(""), isHighlighted: false, isRequired: true)
            CustomTextField(title: "Last Name", placeholder: "e.g., Doe", text: .constant("Doe"), isHighlighted: true, isRequired: true)
        }
        .padding()
        .background(
            LinearGradient(colors: [.teal.opacity(0.2), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
