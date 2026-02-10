
import SwiftUI

struct CustomTextEditor: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var characterLimit: Int? = nil
    var isRequired: Bool = false
    var height: CGFloat = 120
    
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
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.inputBackground)
                
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(.branding.body)
                        .foregroundColor(.textSecondary.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
                
                // Text Editor
                if #available(iOS 16.0, *) {
                    TextEditor(text: $text)
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .scrollContentBackground(.hidden) // Remove default white background
                        .padding(8) // Standard TextEditor padding adjustment
                        .focused($isFocused)
                        .frame(minHeight: height)
                        .onChange(of: text) { _, newValue in
                            if let limit = characterLimit, newValue.count > limit {
                                text = String(newValue.prefix(limit))
                            }
                        }
                } else {
                     TextEditor(text: $text)
                        .font(.branding.body)
                        .foregroundColor(.textPrimary)
                        .onAppear {
                            UITextView.appearance().backgroundColor = .clear
                        }
                        .padding(8)
                        .focused($isFocused)
                        .frame(minHeight: height)
                        .onChange(of: text) { oldValue, newValue in
                            if let limit = characterLimit, newValue.count > limit {
                                text = String(newValue.prefix(limit))
                            }
                        }
                }
                
                // Character Counter
                if let limit = characterLimit {
                    Text("\(text.count)/\(limit)")
                        .font(.branding.caption)
                        .foregroundColor(.textSecondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.brandPrimary : Color.clear, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

struct CustomTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomTextEditor(title: "About You", placeholder: "Tell us about yourself...", text: .constant(""), isRequired: true)
            CustomTextEditor(title: "Bio", placeholder: "Short bio", text: .constant("Founder of TechCo"), isRequired: false)
        }
        .padding()
        .background(Color.background)
    }
}
