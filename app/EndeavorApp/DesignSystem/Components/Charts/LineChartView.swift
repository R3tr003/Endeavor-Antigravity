import SwiftUI

struct LineChartView: View {
    let data: [Double]
    let labels: [String] = ["Q1", "Q2", "Q3", "Q4"] // Implicit for quarterly
    let minY: Double = 6
    let maxY: Double = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quarterly Impact Score")
                .font(.branding.cardTitle)
                .foregroundColor(.textPrimary)
            
            HStack(alignment: .bottom, spacing: 8) {
                // Y-axis labels (simplified for spec: 6-10)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("10").font(.branding.caption).foregroundColor(.textSecondary)
                    Spacer()
                    Text("6").font(.branding.caption).foregroundColor(.textSecondary)
                }
                .frame(height: 150)
                
                ZStack {
                    // Grid
                    VStack {
                        Divider().background(Color.textSecondary.opacity(0.2))
                        Spacer()
                        Divider().background(Color.textSecondary.opacity(0.2))
                    }
                    
                    // Line
                    GeometryReader { geo in
                        let width = geo.size.width
                        let height = geo.size.height
                        
                        Path { path in
                            for (index, value) in data.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(data.count - 1)
                                let y = height * (1 - CGFloat((value - minY) / (maxY - minY)))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.chartAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        
                        // Points
                        ForEach(0..<data.count, id: \.self) { index in
                            let value = data[index]
                            let x = width * CGFloat(index) / CGFloat(data.count - 1)
                            let y = height * (1 - CGFloat((value - minY) / (maxY - minY)))
                            
                            Circle()
                                .fill(Color.chartAccent)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: 150)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView(data: [7.2, 7.8, 8.1, 8.7])
            .padding()
            .background(Color.background)
    }
}
