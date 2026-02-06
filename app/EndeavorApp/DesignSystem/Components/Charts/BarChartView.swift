import SwiftUI

struct BarChartView: View {
    let data: [Double] // Values for the bars
    let labels: [String] // Labels for X-axis
    let maxY: Double = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Mentorship Hours")
                .font(.branding.cardTitle)
                .foregroundColor(.textPrimary)
            
            HStack(alignment: .bottom, spacing: 12) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach((0...4).reversed(), id: \.self) { i in
                        Text("\(i * 3)")
                            .font(.branding.caption)
                            .foregroundColor(.textSecondary)
                            .frame(height: 30) // Approximate height matching chart grid
                        if i > 0 {
                            Spacer()
                        }
                    }
                }
                .frame(height: 200)
                
                // Chart area
                ZStack(alignment: .bottom) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                                .background(Color.textSecondary.opacity(0.2))
                            Spacer()
                        }
                    }
                    .frame(height: 200)
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 16) {
                        ForEach(0..<data.count, id: \.self) { index in
                            VStack(spacing: 8) {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.brandPrimary)
                                    .frame(height: CGFloat(data[index] / maxY) * 200)
                                Text(labels[index])
                                    .font(.branding.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
            }
            
            // Legend
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.brandPrimary)
                    .frame(width: 12, height: 12)
                Text("hours")
                    .font(.branding.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct BarChartView_Previews: PreviewProvider {
    static var previews: some View {
        BarChartView(
            data: [4, 7, 5, 8, 6, 12],
            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        )
        .padding()
        .background(Color.background)
    }
}
