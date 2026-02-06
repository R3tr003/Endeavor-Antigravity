import SwiftUI

struct GrowthView: View {
    var body: some View {
        StackNavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Impact Dashboard")
                            .font(.branding.largeTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Track your progress and milestones.")
                            .font(.branding.subtitle)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Charts
                    VStack(spacing: 24) {
                        BarChartView(
                            data: [4, 7, 5, 8, 6, 12],
                            labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
                        )
                        
                        LineChartView(
                            data: [7.2, 7.8, 8.1, 8.7]
                        )
                    }
                }
                .padding(24)
                .padding(.bottom, 80)
            }
        }
    }
}

struct GrowthView_Previews: PreviewProvider {
    static var previews: some View {
        GrowthView()
    }
}
