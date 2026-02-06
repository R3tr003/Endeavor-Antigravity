import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back, \(appViewModel.currentUser?.firstName ?? "User")!")
                        .font(.branding.largeTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Here's your performance summary.")
                        .font(.branding.subtitle)
                        .foregroundColor(.textSecondary)
                }
                
                // Cards
                VStack(spacing: 16) {
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Impact Score")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("8.7/10")
                                .font(.branding.scoreLarge)
                                .foregroundColor(.textPrimary)
                            Text("+0.5 this month")
                                .font(.branding.inputLabel)
                                .foregroundColor(.success)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mentorship Hours")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("42")
                                .font(.branding.scoreLarge)
                                .foregroundColor(.textPrimary)
                            Text("+8 this month")
                                .font(.branding.inputLabel)
                                .foregroundColor(.success)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connections Made")
                                .font(.branding.inputLabel)
                                .foregroundColor(.textSecondary)
                            Text("12")
                                .font(.branding.scoreLarge)
                                .foregroundColor(.textPrimary)
                            Text("-2 this month")
                                .font(.branding.inputLabel)
                                .foregroundColor(.error)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Upcoming Events
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upcoming Events & Sessions")
                        .font(.branding.sectionTitle)
                        .foregroundColor(.textPrimary)
                    
                    // Placeholder list
                    DashboardCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Founder's Circle")
                                    .font(.branding.cardTitle)
                                    .foregroundColor(.textPrimary)
                                Text("Tomorrow, 2:00 PM")
                                    .font(.branding.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Button("Join") { }
                                .font(.branding.inputLabel.weight(.bold))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
                
                Text("Your Agenda")
                     .font(.branding.sectionTitle)
                     .foregroundColor(.textPrimary)
            }
            .padding(24)
            .padding(.bottom, 80) // Tab bar spacing
        }
        .background(Color.background.edgesIgnoringSafeArea(.all))
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppViewModel())
    }
}
