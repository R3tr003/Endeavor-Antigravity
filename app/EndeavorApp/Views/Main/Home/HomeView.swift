import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    // For scroll-based animations
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.background.edgesIgnoringSafeArea(.all)
            
            // Top ambient glow for modern aesthetic
            Circle()
                .fill(Color.brandPrimary.opacity(0.2))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -50, y: -200)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.brandPrimary.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
                    
                    // 1. Header — Personal Greeting
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                        Text("Good morning,")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("\(appViewModel.currentUser?.firstName ?? "User")")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(-1)
                        Text("You have 2 mentorship sessions this week")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, DesignSystem.Spacing.standard)
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    
                    // 2. Quick Stats
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        Button(action: {}) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                Image(systemName: "envelope.badge.fill")
                                    .font(.title2)
                                    .foregroundColor(.brandPrimary)
                                Text("Awaiting Messages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("4")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.medium)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                        }
                        
                        Button(action: {}) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("Events This Week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("12")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DesignSystem.Spacing.medium)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    
                    // 3. Smart Recommendations
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                        Text("RECOMMENDED FOR YOU")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .tracking(1.5)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        VStack(spacing: DesignSystem.Spacing.small) {
                            RecommendationCard(
                                icon: "person.fill",
                                color: .brandPrimary,
                                title: "Maria Lopez",
                                subtitle: "SaaS Scaling Expert",
                                pillText: "Mentor"
                            )
                            RecommendationCard(
                                icon: "calendar.badge.plus",
                                color: .purple,
                                title: "CEO Roundtable",
                                subtitle: "Growth Strategies · Thu 3PM",
                                pillText: "Event"
                            )
                            RecommendationCard(
                                icon: "building.2.fill",
                                color: .orange,
                                title: "Carlos Rodriguez",
                                subtitle: "Fintech Founder · Series B",
                                pillText: "Connection"
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    }
                    
                    // 4. Upcoming Sessions
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("Upcoming Sessions")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.standard) {
                                EventCard(title: "Founder's Circle", time: "Tomorrow, 2:00 PM", color: .brandPrimary)
                                EventCard(title: "AI Workshop", time: "Friday, 10:00 AM", color: .purple)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.large)
                            .padding(.bottom, DesignSystem.Spacing.medium)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.standard)
                    
                    Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Floating Header
            if scrollOffset < -60 {
                VStack {
                    HStack {
                        Text("Home").font(.headline).foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

// MARK: - Subcomponents

struct RecommendationCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let pillText: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            // Circle Icon
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            // Text Block
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Pill Label
            Text(pillText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, 6)
                .background(color.opacity(0.15), in: Capsule())
        }
        .padding(DesignSystem.Spacing.standard)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct EventCard: View {
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            
            // Header: Avatar placeholder and options
            HStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: DesignSystem.Spacing.xxLarge, height: DesignSystem.Spacing.xxLarge)
                    .overlay(Image(systemName: "person.2.fill").foregroundColor(color))
                    
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Confirmed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
            
            // Action Button
            Button(action: {}) {
                Text("Join")
                    .font(.headline)
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .overlay(
                        Capsule().stroke(color, lineWidth: 1.5)
                    )
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(width: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppViewModel())
    }
}
