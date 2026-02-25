import SwiftUI

struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(isFocused ? .brandPrimary : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
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
                    .opacity(text.isEmpty && !isFocused ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                    .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                
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
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: isFocused ? Color.brandPrimary.opacity(0.15) : Color.clear, radius: 10, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isFocused ? Color.brandPrimary : Color.borderGlare.opacity(0.15), lineWidth: isFocused ? 1.5 : 1)
                    .shadow(color: isFocused ? Color.brandPrimary.opacity(0.5) : Color.clear, radius: 4, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
        }
    }
}

struct CustomTextField_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @FocusState private var isFocused: Bool
        var body: some View {
            VStack(spacing: 20) {
                CustomTextField(title: "First Name", placeholder: "e.g., John", text: .constant(""), isFocused: $isFocused, isRequired: true)
            }
            .padding()
            .background(
                LinearGradient(colors: [.teal.opacity(0.2), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
