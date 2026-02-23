import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(isFocused ? .brandPrimary : .secondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(.error)
                }
            }
            
            ZStack(alignment: .leading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.horizontal, 16)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .textContentType(.none)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(16)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .URL ? .never : .sentences)
                        .autocorrectionDisabled(keyboardType == .URL)
                        .focused($isFocused)
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isFocused ? Color.brandPrimary : Color.primary.opacity(0.05), lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: isFocused ? Color.brandPrimary.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTextField(title: "First Name", placeholder: "e.g., John", text: .constant(""), isRequired: true)
            CustomTextField(title: "Last Name", placeholder: "e.g., Doe", text: .constant("Doe"), isRequired: true)
        }
        .padding()
        .background(
            LinearGradient(colors: [.teal.opacity(0.2), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
