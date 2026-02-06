import SwiftUI

struct LinearProgressView: View {
    var progress: Double // 0.0 top 1.0
    var color: Color = .brandPrimary
    var trackColor: Color = .inputBackground
    var height: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(trackColor)
                    .frame(width: geometry.size.width, height: height)
                
                // Indicator
                Rectangle()
                    .fill(color)
                    .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)), height: height)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: progress)
            }
            .cornerRadius(height / 2)
        }
        .frame(height: height)
    }
}

struct LinearProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LinearProgressView(progress: 0.2)
            LinearProgressView(progress: 0.5)
            LinearProgressView(progress: 0.8, color: .success)
        }
        .padding()
        .background(Color.background)
    }
}
