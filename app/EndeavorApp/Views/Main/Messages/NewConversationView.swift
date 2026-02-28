import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkViewModel = NetworkViewModel(repository: FirebaseNetworkRepository())
    private let messagesRepository = FirebaseMessagesRepository()
    @State private var searchText: String = ""
    @State private var isCreating: Bool = false
    @State private var creationError: String? = nil
    @State private var companyNames: [String: String] = [:]   // userId → company name

    /// Chiamato dopo la creazione/recupero conversazione — passa (conversationId, recipientId)
    var onConversationReady: (String, String) -> Void

    @AppStorage("userId") private var currentUserId: String = ""

    private var filteredProfiles: [UserProfile] {
        let others = networkViewModel.profiles.filter { $0.id.uuidString != currentUserId }
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return others }
        return others.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerBar
                searchBar
                if let error = creationError {
                    Text(error)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.error)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.bottom, DesignSystem.Spacing.small)
                }
                contentArea
            }

            if isCreating {
                Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                ProgressView()
                    .tint(.brandPrimary)
                    .scaleEffect(1.5)
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .onAppear {
            if networkViewModel.profiles.isEmpty {
                networkViewModel.fetchUsers(isInitial: true)
            }
        }
        .onChange(of: networkViewModel.profiles) { _, profiles in
            let db = Firestore.firestore()
            for profile in profiles {
                let userId = profile.id.uuidString
                guard companyNames[userId] == nil else { continue }
                db.collection("companies")
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 1)
                    .getDocuments { snapshot, _ in
                        if let name = snapshot?.documents.first?.data()["name"] as? String {
                            DispatchQueue.main.async {
                                companyNames[userId] = name
                            }
                        }
                    }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.borderGlare.opacity(0.2), lineWidth: 1))
            }
            Spacer()
            Text("New Message")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Circle().fill(Color.clear).frame(width: 36, height: 36)
        }
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.standard)
        .background(.regularMaterial)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderGlare.opacity(0.1)), alignment: .bottom)
    }

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            TextField("Search by name or role...", text: $searchText)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(DesignSystem.Spacing.standard)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, DesignSystem.Spacing.medium)
        .padding(.bottom, DesignSystem.Spacing.small)
    }

    @ViewBuilder
    private var contentArea: some View {
        if networkViewModel.isLoading {
            Spacer()
            ProgressView().tint(.brandPrimary)
            Spacer()
        } else if filteredProfiles.isEmpty {
            Spacer()
            VStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: "person.2.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(searchText.isEmpty ? "No contacts available" : "No results for \"\(searchText)\"")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(filteredProfiles) { profile in
                        contactRow(profile: profile)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.small)
            }
        }
    }

    private func contactRow(profile: UserProfile) -> some View {
        Button(action: { startConversation(with: profile) }) {
            HStack(spacing: DesignSystem.Spacing.standard) {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    if profile.profileImageUrl.isEmpty {
                        Text(String(profile.fullName.prefix(2)).uppercased())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPrimary)
                    } else {
                        WebImage(url: URL(string: profile.profileImageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } placeholder: {
                            Text(String(profile.fullName.prefix(2)).uppercased())
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.borderGlare.opacity(0.15), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.fullName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(companyNames[profile.id.uuidString] ?? profile.role)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(DesignSystem.Spacing.standard)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .stroke(Color.borderGlare.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(isCreating)
    }

    private func startConversation(with profile: UserProfile) {
        guard !currentUserId.isEmpty else {
            creationError = "Authentication error. Please log in again."
            return
        }
        isCreating = true
        creationError = nil

        messagesRepository.getOrCreateConversation(
            between: currentUserId,
            and: profile.id.uuidString
        ) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success(let conversationId):
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onConversationReady(conversationId, profile.id.uuidString)
                    }
                case .failure(let error):
                    creationError = "Could not start conversation: \(error.localizedDescription)"
                }
            }
        }
    }
}
