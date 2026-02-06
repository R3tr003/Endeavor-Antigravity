import SwiftUI

extension Font {
    static var branding: Branding { Branding() }
    
    struct Branding {
        let largeTitle = Font.system(size: 32, weight: .bold)
        let sectionTitle = Font.system(size: 24, weight: .bold)
        let cardTitle = Font.system(size: 20, weight: .bold)
        let subtitle = Font.system(size: 16, weight: .regular)
        let body = Font.system(size: 16, weight: .regular)
        let inputLabel = Font.system(size: 14, weight: .medium)
        let caption = Font.system(size: 12, weight: .regular)
        
        let scoreLarge = Font.system(size: 48, weight: .bold)
        let profileName = Font.system(size: 20, weight: .bold)
    }
}

struct Typography_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Large Title").font(.branding.largeTitle).foregroundColor(.textPrimary)
            Text("Section Title").font(.branding.sectionTitle).foregroundColor(.textPrimary)
            Text("Card Title").font(.branding.cardTitle).foregroundColor(.textPrimary)
            Text("Subtitle").font(.branding.subtitle).foregroundColor(.textSecondary)
            Text("Body Text").font(.branding.body).foregroundColor(.textPrimary)
            Text("Input Label").font(.branding.inputLabel).foregroundColor(.textSecondary)
            Text("Caption").font(.branding.caption).foregroundColor(.textSecondary)
        }
        .padding()
        .background(Color.background)
    }
}
