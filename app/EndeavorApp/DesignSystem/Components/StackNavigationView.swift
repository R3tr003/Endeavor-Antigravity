import SwiftUI

// Simple wrapper to ensure background color covers everything if needed
struct StackNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            content
        }
        .edgesIgnoringSafeArea(.bottom) // Allow scrolling under tab bar
    }
}
