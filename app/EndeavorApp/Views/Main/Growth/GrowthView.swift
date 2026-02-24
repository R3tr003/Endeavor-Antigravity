import SwiftUI

struct GrowthView: View {
    @State private var animateGlow = false
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                // Immersive Background
                Color.background.edgesIgnoringSafeArea(.all)
                
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: proxy.size.width * 1.2, height: proxy.size.width * 1.2)
                            .blur(radius: 80)
                            .offset(x: animateGlow ? -50 : 50, y: animateGlow ? 100 : -50)
                        
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: proxy.size.width * 0.8, height: proxy.size.width * 0.8)
                            .blur(radius: 80)
                            .offset(x: animateGlow ? 150 : 0, y: animateGlow ? -200 : -100)
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            animateGlow = true
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Impact\nDashboard")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                                .lineSpacing(-4)
                            
                            Text("Track your progress and milestones.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        
                        // Charts in Glass Cards
                        VStack(spacing: 24) {
                            DashboardCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Monthly Activity")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    BarChartView(
                                        data: [4, 7, 5, 8, 6, 12],
                                        labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
                                    )
                                    .frame(height: 200)
                                }
                                .padding(24)
                            }
                            
                            DashboardCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Growth Trajectory")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    LineChartView(
                                        data: [7.2, 7.8, 8.1, 8.7]
                                    )
                                    .frame(height: 200)
                                    .padding(.vertical, 8)
                                }
                                .padding(24)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // Space for floating tab bar
                    }
                }
                
                // Status bar blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}

struct GrowthView_Previews: PreviewProvider {
    static var previews: some View {
        GrowthView()
    }
}
