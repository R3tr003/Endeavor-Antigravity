import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct ChatUserProfileView: View {
    let profile: UserProfile
    let companyName: String?

    @State private var company: CompanyProfile? = nil
    @State private var isLoadingCompany: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                // Ambient glows
                GeometryReader { proxy in
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.15))
                            .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                            .blur(radius: 100)
                            .offset(x: 50, y: -50)

                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: proxy.size.width * 1.2, height: proxy.size.width * 1.2)
                            .blur(radius: 120)
                            .offset(x: -100, y: -100)
                    }
                    .ignoresSafeArea()
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.xLarge) {
                        heroSection
                        if !profile.personalBio.isEmpty { aboutSection }
                        companySection
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "common.done", defaultValue: "Done")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
            }
        }
        .onAppear {
            let db = Firestore.firestore()
            db.collection("companies")
                .whereField("userId", isEqualTo: profile.id.uuidString)
                .limit(to: 1)
                .getDocuments { snapshot, _ in
                    DispatchQueue.main.async {
                        isLoadingCompany = false
                        guard let data = snapshot?.documents.first?.data() else { return }
                        company = CompanyProfile(
                            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                            name: data["name"] as? String ?? "",
                            website: data["website"] as? String ?? "",
                            hqCountry: data["hqCountry"] as? String ?? "",
                            hqCity: data["hqCity"] as? String ?? "",
                            industries: data["industries"] as? [String] ?? [],
                            stage: data["stage"] as? String ?? "",
                            employeeRange: data["employeeRange"] as? String ?? "",
                            companyBio: data["companyBio"] as? String ?? "",
                            logoUrl: data["logoUrl"] as? String ?? "",
                            vertical: data["vertical"] as? String ?? ""
                        )
                    }
                }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 12) {
            Group {
                if !profile.profileImageUrl.isEmpty {
                    WebImage(url: URL(string: profile.profileImageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.brandPrimary.opacity(0.4), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                        .overlay(Circle().stroke(Color.brandPrimary.opacity(0.4), lineWidth: 2))
                }
            }

            Text(profile.fullName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            if !profile.userType.isEmpty {
                Text(profile.userType)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.brandPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.brandPrimary.opacity(0.15), in: Capsule())
            }

            Text(profile.role)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !profile.location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.brandPrimary)
                    Text(profile.location).font(.footnote).foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            sectionTitle(String(localized: "profile.about", defaultValue: "About"))
            Text(profile.personalBio)
                .font(.body)
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
    }

    private var companySection: some View {
        Group {
            if isLoadingCompany {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.brandPrimary)
                    Text(String(localized: "profile.loading"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
            } else if let company = company {
                DashboardCard {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {

                        HStack(spacing: DesignSystem.Spacing.standard) {
                            Group {
                                if !company.logoUrl.isEmpty {
                                    WebImage(url: URL(string: company.logoUrl))
                                        .resizable().scaledToFill()
                                        .frame(width: 52, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                                } else {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                        .fill(Color.primary.opacity(0.05))
                                        .frame(width: 52, height: 52)
                                        .overlay(Image(systemName: "building.2.fill").foregroundColor(.secondary.opacity(0.4)))
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(company.name).font(.title3.weight(.bold))
                                if !company.hqCity.isEmpty {
                                    Text("\(company.hqCity), \(company.hqCountry)")
                                        .font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let url = URL(string: company.website), !company.website.isEmpty {
                                Link(destination: url) {
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.brandPrimary).font(.title3)
                                }
                            }
                        }

                        Divider().opacity(0.15)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.xSmall) {
                                ForEach(company.industries, id: \.self) { item in
                                    Text(item)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .lineLimit(1)
                                        .layoutPriority(1)
                                        .foregroundColor(Color.brandPrimary)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color.brandPrimary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                if !company.stage.isEmpty { outlinedBadge(company.stage) }
                                if !company.employeeRange.isEmpty { outlinedBadge(company.employeeRange) }
                            }
                        }

                        if !company.companyBio.isEmpty {
                            Text(company.companyBio)
                                .font(.footnote).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(DesignSystem.Spacing.large)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
            }
        }
    }

    // MARK: - Helper Views

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func outlinedBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.primary.opacity(0.85))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .overlay(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
    }
}
