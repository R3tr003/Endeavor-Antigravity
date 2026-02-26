import SwiftUI

public struct FluidBackgroundView: View {
    @State private var animateGradient1 = false
    @State private var animateGradient2 = false
    @State private var animateGradient3 = false
    @Environment(\.colorScheme) private var colorScheme

    public init() {}
    
    public var body: some View {
        ZStack {
            Color.background // Base color
            
            // Teal dynamic blobs
            Circle()
                .fill(Color.brandPrimary.opacity(colorScheme == .dark ? 0.6 : 0.18))
                .blur(radius: 60)
                .frame(width: 300, height: 300)
                .offset(x: animateGradient1 ? -100 : 100, y: animateGradient1 ? -150 : 50)
            
            Circle()
                .fill(Color(hex: "00D9C5").opacity(colorScheme == .dark ? 0.5 : 0.14)) // Slightly different teal
                .blur(radius: 80)
                .frame(width: 400, height: 400)
                .offset(x: animateGradient2 ? 150 : -50, y: animateGradient2 ? 200 : -200)
                
            Circle()
                .fill(Color.chartAccent.opacity(colorScheme == .dark ? 0.3 : 0.08)) // Subtle purple accent
                .blur(radius: 90)
                .frame(width: 250, height: 250)
                .offset(x: animateGradient3 ? -50 : 150, y: animateGradient3 ? 300 : 0)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animateGradient1.toggle()
            }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(1.0)) {
                animateGradient2.toggle()
            }
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true).delay(2.0)) {
                animateGradient3.toggle()
            }
        }
    }
}

struct FluidBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        FluidBackgroundView()
    }
}
