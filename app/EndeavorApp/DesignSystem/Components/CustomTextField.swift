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
                    .font(.branding.inputLabel)
                    .foregroundColor(isFocused ? .brandPrimary : .textSecondary)
                
                if isRequired {
                    Text("*")
                        .font(.branding.inputLabel)
                        .foregroundColor(.error)
                }
            }
            
            ZStack(alignment: .leading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.branding.body)
                        .foregroundColor(.textSecondary.opacity(0.5))
                        .padding(.horizontal, 16)
                }
                
                if isSecure {
                    SecureField("", text: $text)
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .padding(16)
                        .textContentType(.none)
                        .focused($isFocused)
                } else {
                    TextField("", text: $text)
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .padding(16)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(keyboardType == .URL ? .never : .sentences)
                        .autocorrectionDisabled(keyboardType == .URL)
                        .focused($isFocused)
                }
            }
            .background(Color.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.brandPrimary : Color.clear, lineWidth: 1)
            )
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
        .background(Color.background)
    }
}
