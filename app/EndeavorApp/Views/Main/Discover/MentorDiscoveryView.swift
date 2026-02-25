import SwiftUI

struct MentorDiscoveryView: View {
    @State private var query: String = ""
    @State private var isSearching: Bool = false
    @State private var hasSearched: Bool = false
    @State private var animateGlow: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        StackNavigationView {
            ZStack(alignment: .top) {
                Color.background.edgesIgnoringSafeArea(.all)
                
                // Due cerchi blur animati
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: proxy.size.width * 1.4, height: proxy.size.width * 1.4)
                            .blur(radius: 100)
                            .offset(x: animateGlow ? -80 : 60, y: animateGlow ? 120 : -60)
                        
                        Circle()
                            .fill(Color.purple.opacity(0.08))
                            .frame(width: proxy.size.width * 1.1, height: proxy.size.width * 1.1)
                            .blur(radius: 110)
                            .offset(x: animateGlow ? 120 : -80, y: animateGlow ? -180 : -80)
                    }
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                            animateGlow = true
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                            Text("Find Your")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            Text("Expert Match")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .tracking(-1.5)
                            Text("Describe what you need. AI finds who can help.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.top, DesignSystem.Spacing.xxSmall)
                        }
                        .padding(.top, DesignSystem.Spacing.standard)
                        
                        // Search Input Card
                        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.small) {
                            TextField("e.g. Who has experience scaling SaaS from 50 to 200 employees?", text: $query, axis: .vertical)
                                .lineLimit(1...4)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.primary)
                                .focused($isInputFocused)
                                .padding()
                            
                            Button(action: {
                                isInputFocused = false
                                isSearching = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    isSearching = false
                                    hasSearched = true
                                }
                            }) {
                                Text("Search")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(query.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .white)
                                    .padding(.horizontal, DesignSystem.Spacing.large)
                                    .padding(.vertical, 10)
                                    .background(query.trimmingCharacters(in: .whitespaces).isEmpty ? Color.primary.opacity(0.1) : Color.brandPrimary)
                                    .clipShape(Capsule())
                            }
                            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                            .padding(.bottom, DesignSystem.Spacing.standard)
                            .padding(.trailing, DesignSystem.Spacing.standard)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1))
                        
                        // Example Queries OR Results
                        if !hasSearched {
                            // Example Queries
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("TRY ASKING...")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(1)
                                    .foregroundColor(.textSecondary)
                                
                                VStack(spacing: DesignSystem.Spacing.xSmall) {
                                    exampleChip("Who has experience scaling SaaS from 50 to 200 employees?")
                                    exampleChip("I need help with enterprise sales in fintech. Who should I talk to?")
                                    exampleChip("Which mentors have expanded companies into Latin America?")
                                }
                            }
                        } else {
                            if isSearching {
                                // Loading State
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .brandPrimary))
                                        .scaleEffect(1.2)
                                    Text("Finding the best matches...")
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.xxLarge)
                            } else {
                                // Results State
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    Text("Best Matches")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    VStack(spacing: DesignSystem.Spacing.standard) {
                                        MatchCard(rank: 1, name: "Maria Lopez", role: "Former CEO at Netflix", matchPercent: 98,
                                                  description: "Scaled 3 SaaS companies, expert in 50–200 employee growth phase",
                                                  expertiseTags: ["SaaS Scaling", "Revenue Growth", "Enterprise Sales"])
                                        
                                        MatchCard(rank: 2, name: "Carlos Rodriguez", role: "Former VP Sales at SaaS Unicorn", matchPercent: 87,
                                                  description: "Former VP Sales at SaaS Unicorn, specializes in team scaling",
                                                  expertiseTags: ["Sales Strategy", "Team Building", "FinTech"])
                                        
                                        MatchCard(rank: 3, name: "Ana Martinez", role: "CEO, Series B SaaS Platform", matchPercent: 72,
                                                  description: "CEO of growing SaaS platform, currently navigating 75–150 employee transition",
                                                  expertiseTags: ["Fundraising", "Product", "Operations"])
                                    }
                                    
                                    // New Search Button
                                    Button(action: {
                                        query = ""
                                        hasSearched = false
                                        isSearching = false
                                    }) {
                                        Text("New Search")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.brandPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DesignSystem.Spacing.small)
                                            .overlay(Capsule().stroke(Color.brandPrimary, lineWidth: 1))
                                    }
                                    .padding(.top, DesignSystem.Spacing.medium)
                                }
                            }
                        }
                        
                        Spacer(minLength: DesignSystem.Spacing.bottomSafePadding)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
            }
        }
    }
    
    @ViewBuilder
    private func exampleChip(_ text: String) -> some View {
        Button(action: {
            query = text
            isInputFocused = false
        }) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.standard) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.brandPrimary)
                
                Text(text)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(DesignSystem.Spacing.standard)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }
}

struct MatchCard: View {
    let rank: Int
    let name: String
    let role: String
    let matchPercent: Int
    let description: String
    let expertiseTags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            
            // Top Row
            HStack(spacing: DesignSystem.Spacing.small) {
                // Initial Circle
                Circle()
                    .fill(Color.brandPrimary.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(role)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Match Percent Badge
                Text("\(matchPercent)% Match")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandPrimary, in: Capsule())
            }
            
            // Description Row
            Text(description)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(expertiseTags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.brandPrimary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(Color.brandPrimary.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.brandPrimary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            
            // Action Button
            Button(action: {}) {
                Text("Connect")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xLarge, style: .continuous).stroke(Color.brandPrimary.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.brandPrimary.opacity(0.12), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    MentorDiscoveryView()
}
