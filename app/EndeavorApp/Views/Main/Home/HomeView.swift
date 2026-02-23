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
                .fill(Color.brandPrimary.opacity(0.15)) // Safe fallback
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 150, y: -100)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                // Tracking scroll offset
                GeometryReader { proxy in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                VStack(alignment: .leading, spacing: 32) {
                    // Modern Header with Large Typography
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back,")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text("\(appViewModel.currentUser?.firstName ?? "User")!")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(-1)
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    
                    // Cards Grid Area
                    VStack(spacing: 20) {
                        DashboardCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Impact Score")
                                        .font(.caption)
                                        .textCase(.uppercase)
                                        .foregroundColor(.secondary)
                                    Text("8.7")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("+0.5 this month")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                // Micro chart placeholder
                                Circle()
                                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .trim(from: 0, to: 0.87)
                                            .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Side-by-side metrics
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                            DashboardCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: "clock.fill")
                                        .font(.title2)
                                        .foregroundColor(.brandPrimary)
                                    Text("Hours")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("42")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            DashboardCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue) // Variation
                                    Text("Connections")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("12")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Upcoming Events Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Upcoming Sessions")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Event Card 1
                                EventCard(
                                    title: "Founder's Circle",
                                    time: "Tomorrow, 2:00 PM",
                                    color: .brandPrimary
                                )
                                
                                // Event Card 2
                                EventCard(
                                    title: "AI Workshop",
                                    time: "Friday, 10:00 AM",
                                    color: .purple
                                )
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20) // For shadow clearance
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer(minLength: 120) // Deep padding for the floating tab bar
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Floating Header matching scroll
            if scrollOffset < -60 {
                VStack {
                    HStack {
                        Text("Home")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1)),
                        alignment: .bottom
                    )
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

// Mini Event Card component defined locally for Home
struct EventCard: View {
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "calendar")
                            .foregroundColor(color)
                    )
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {}) {
                Text("Join")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(color)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(width: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Scroll Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppViewModel())
    }
}
