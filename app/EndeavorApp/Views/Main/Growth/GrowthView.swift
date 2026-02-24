import SwiftUI

struct GrowthView: View {
    @State private var animateGlow = false
    @StateObject private var viewModel = GrowthViewModel(repository: FirebaseGrowthRepository())
    
    // In a real app we'd pass the actual userId from the environment/AppViewModel
    private let currentUserId = "mock_user_id"
    
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
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Impact\nDashboard")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                                .lineSpacing(-4)
                            
                            Text("Track your progress and milestones.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, DesignSystem.Spacing.standard)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        // Charts in Glass Cards
                        VStack(spacing: DesignSystem.Spacing.large) {
                            if viewModel.isLoading {
                                ProgressView("Loading metrics...")
                                    .padding(.top, DesignSystem.Spacing.xxLarge)
                            } else if let error = viewModel.appError {
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                                    .padding()
                            } else if let metrics = viewModel.metrics {
                                DashboardCard {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                                        Text("Monthly Activity")
                                            .font(.headline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        
                                        BarChartView(
                                            data: metrics.monthlyActivity,
                                            labels: metrics.monthlyLabels
                                        )
                                        .frame(height: 200)
                                    }
                                    .padding(DesignSystem.Spacing.large)
                                }
                                
                                DashboardCard {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                                        Text("Growth Trajectory")
                                            .font(.headline.weight(.semibold))
                                            .foregroundColor(.primary)
                                        
                                        LineChartView(
                                            data: metrics.growthTrajectory
                                        )
                                        .frame(height: 200)
                                        .padding(.vertical, DesignSystem.Spacing.xSmall)
                                    }
                                    .padding(DesignSystem.Spacing.large)
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.bottomSafePadding) // Space for floating tab bar
                    }
                }
                .onAppear {
                    if viewModel.metrics == nil {
                        viewModel.fetchMetrics(userId: currentUserId)
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
