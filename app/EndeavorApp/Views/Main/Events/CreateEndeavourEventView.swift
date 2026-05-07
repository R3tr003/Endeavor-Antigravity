import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
struct CreateEndeavourEventView: View {

    let existingEvent: CalendarEvent?
    let currentUserId: String
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEndeavourEventViewModel
    @FocusState private var focusedField: Field?

    init(existingEvent: CalendarEvent? = nil, currentUserId: String, onSaved: @escaping () -> Void) {
        self.existingEvent = existingEvent
        self.currentUserId = currentUserId
        self.onSaved = onSaved
        if let existing = existingEvent {
            _viewModel = StateObject(wrappedValue: CreateEndeavourEventViewModel(existingEvent: existing))
        } else {
            _viewModel = StateObject(wrappedValue: CreateEndeavourEventViewModel())
        }
    }
    @State private var showDocumentPicker = false
    @State private var coverPreview: UIImage? = nil
    @State private var isLoadingPhoto = false

    private enum Field { case title, location, description, maxParticipants }
    private let durationOptions = [30, 60, 90, 120, 180, 240]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xLarge) {
        
                        // MARK: Title
                        formSection(label: String(localized: "event.create.title_label", defaultValue: "Event title"), required: true) {
                            TextField(
                                String(localized: "event.create.title_placeholder", defaultValue: "e.g. Endeavor CEO Summit 2026"),
                                text: $viewModel.title
                            )
                            .font(.system(size: 16, design: .rounded))
                            .focused($focusedField, equals: .title)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                    .stroke(focusedField == .title ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                            )
                        }

                        // MARK: Category
                        formSection(label: String(localized: "event.create.category", defaultValue: "Category")) {
                            Menu {
                                ForEach(CalendarEvent.EventCategory.allCases, id: \.rawValue) { cat in
                                    Button(action: { viewModel.category = cat }) {
                                        Label {
                                            Text(cat.displayName)
                                        } icon: {
                                            Image(systemName: cat.icon)
                                                .foregroundStyle(cat.swiftColor)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: viewModel.category.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(viewModel.category.swiftColor)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            viewModel.category.swiftColor.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                                .stroke(viewModel.category.swiftColor, lineWidth: 1.5)
                                        )
                                    Text(viewModel.category.displayName)
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(DesignSystem.Spacing.standard)
                                .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            }
                        }

                        // MARK: Date & Time
                        formSection(label: String(localized: "schedule.date_time", defaultValue: "Date & Time"), required: true) {
                            DatePicker(
                                "",
                                selection: $viewModel.startDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(.brandPrimary)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular, shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                        }

                        // MARK: Duration
                        formSection(label: String(localized: "schedule.duration", defaultValue: "Duration"), required: true) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.small) {
                                ForEach(durationOptions, id: \.self) { minutes in
                                    EventDurationButton(
                                        minutes: minutes,
                                        isSelected: viewModel.durationMinutes == minutes,
                                        onTap: { viewModel.durationMinutes = minutes }
                                    )
                                }
                            }
                        }

                        // MARK: Location
                        formSection(label: String(localized: "event.create.location", defaultValue: "Location (optional)")) {
                            TextField(
                                String(localized: "event.create.location_placeholder", defaultValue: "Address or venue name"),
                                text: $viewModel.location
                            )
                            .font(.system(size: 16, design: .rounded))
                            .focused($focusedField, equals: .location)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                    .stroke(focusedField == .location ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                            )
                        }

                        // MARK: Video link
                        formSection(label: String(localized: "schedule.video", defaultValue: "Video call")) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                ForEach([CalendarEvent.MeetProvider.none, .googleMeet, .microsoftTeams], id: \.rawValue) { provider in
                                    EventProviderButton(
                                        provider: provider,
                                        isSelected: viewModel.meetProvider == provider,
                                        onTap: { viewModel.meetProvider = provider }
                                    )
                                }
                            }
                            if viewModel.meetProvider != .none {
                                Text(String(localized: "event.create.link_generated_note",
                                            defaultValue: "A link will be generated and shared with participants."))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.top, DesignSystem.Spacing.xxSmall)
                            }
                        }

                        // MARK: Cover image
                        formSection(label: String(localized: "event.create.cover_image", defaultValue: "Cover Image (optional)")) {
                            VStack(spacing: DesignSystem.Spacing.xSmall) {
                                // Preview — local selection takes priority; else show existing URL (edit mode)
                                if let image = coverPreview {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                                } else if let existingUrl = viewModel.existingCoverImageUrl,
                                          let url = URL(string: existingUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let img = phase.image {
                                            img.resizable().scaledToFill()
                                        } else {
                                            Color.brandPrimary.opacity(0.12)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
                                }
                                // Local Bool copies (Sendable) — avoids @MainActor capture in @Sendable PhotosPicker closure
                                let hasCover = coverPreview != nil || viewModel.existingCoverImageUrl != nil
                                let loadingNow = isLoadingPhoto
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    CoverPickerLabel(hasCoverImage: hasCover, isLoading: loadingNow)
                                }
                                .onChange(of: viewModel.selectedPhotoItem) {
                                    guard let item = viewModel.selectedPhotoItem else { return }
                                    isLoadingPhoto = true
                                    viewModel.errorMessage = nil
                                    // Task {} inherits @MainActor — no @Sendable capture of @State.
                                    // UIImage(data:) is offloaded to a detached task that only
                                    // captures `data` (Sendable), keeping the main thread free.
                                    Task {
                                        defer { isLoadingPhoto = false }
                                        guard let data = try? await item.loadTransferable(type: Data.self) else {
                                            viewModel.errorMessage = String(localized: "event.create.photo_load_failed",
                                                                            defaultValue: "Could not load photo. Try another image.")
                                            viewModel.selectedPhotoItem = nil
                                            return
                                        }
                                        let image = await Task.detached(priority: .userInitiated) {
                                            UIImage(data: data)
                                        }.value
                                        guard let image else {
                                            viewModel.errorMessage = String(localized: "event.create.photo_decode_failed",
                                                                            defaultValue: "Could not decode photo. Try another image.")
                                            viewModel.selectedPhotoItem = nil
                                            return
                                        }
                                        coverPreview = image
                                        viewModel.selectedCoverImage = image
                                    }
                                }
                            }
                        }

                        // MARK: Description
                        formSection(label: String(localized: "event.create.description", defaultValue: "Description (optional)")) {
                            TextField(
                                String(localized: "event.create.description_placeholder", defaultValue: "What's this event about?"),
                                text: $viewModel.eventDescription,
                                axis: .vertical
                            )
                            .lineLimit(4, reservesSpace: true)
                            .font(.system(size: 15, design: .rounded))
                            .focused($focusedField, equals: .description)
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                    .stroke(focusedField == .description ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                            )
                        }

                        // MARK: Max participants
                        formSection(label: String(localized: "event.create.max_participants", defaultValue: "Max Participants")) {
                            VStack(spacing: DesignSystem.Spacing.small) {
                                Toggle(
                                    String(localized: "event.create.limit_participants", defaultValue: "Limit number of participants"),
                                    isOn: $viewModel.enableMaxParticipants
                                )
                                .font(.system(size: 15, design: .rounded))
                                .tint(.brandPrimary)

                                if viewModel.enableMaxParticipants {
                                    HStack {
                                        Text(String(localized: "event.create.max_label", defaultValue: "Maximum participants:"))
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("e.g. 100", text: $viewModel.maxParticipantsText)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.brandPrimary)
                                            .frame(width: 80)
                                            .focused($focusedField, equals: .maxParticipants)
                                    }
                                }
                            }
                            .padding(DesignSystem.Spacing.standard)
                            .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous)
                                    .stroke(focusedField == .maxParticipants ? Color.brandPrimary : Color.clear, lineWidth: 1.5)
                                    .animation(.easeInOut(duration: 0.2), value: focusedField)
                            )
                        }

                        // MARK: Attachment
                        formSection(label: String(localized: "event.create.attachment", defaultValue: "Attachment (optional)")) {
                            Button(action: { showDocumentPicker = true }) {
                                HStack(spacing: DesignSystem.Spacing.small) {
                                    Image(systemName: viewModel.attachmentLocalUrl != nil ? "paperclip.circle.fill" : "paperclip")
                                        .font(.system(size: 20))
                                        .foregroundColor(.brandPrimary)
                                    Text(viewModel.attachmentName
                                         ?? String(localized: "event.create.attachment_add", defaultValue: "Attach a document"))
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundColor(viewModel.attachmentLocalUrl != nil ? .primary : .brandPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    if viewModel.attachmentLocalUrl != nil {
                                        Button(action: {
                                            viewModel.attachmentLocalUrl = nil
                                            viewModel.attachmentName = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(DesignSystem.Spacing.standard)
                                .glassSurface(.regular.interactive(), shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large))
                            }
                            .buttonStyle(.plain)
                        }

                        // MARK: Save button
                        Button(action: {
                            if existingEvent != nil {
                                viewModel.saveChanges(currentUserId: currentUserId) {
                                    dismiss()
                                    onSaved()
                                }
                            } else {
                                viewModel.save(currentUserId: currentUserId) {
                                    dismiss()
                                    onSaved()
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: existingEvent != nil ? "checkmark.circle" : "calendar.badge.plus")
                                    Text(existingEvent != nil
                                         ? String(localized: "event.edit.save", defaultValue: "Save Changes")
                                         : String(localized: "event.create.save", defaultValue: "Create Event"))
                                }
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.standard)
                        }
                        .buttonStyle(.glassProminent)
                        .opacity(viewModel.isValid ? 1 : 0.55)
                        .disabled(!viewModel.isValid || viewModel.isSaving)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(DesignSystem.Spacing.large)
                }
            }
            .navigationTitle(existingEvent != nil
                ? String(localized: "event.edit.nav_title", defaultValue: "Edit Event")
                : String(localized: "event.create.title", defaultValue: "New Endeavor Event"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common.cancel", defaultValue: "Cancel")) { dismiss() }
                        .foregroundColor(.brandPrimary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "common.done", defaultValue: "Done")) {
                        focusedField = nil
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.brandPrimary)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    viewModel.attachmentLocalUrl = url
                    viewModel.attachmentName = url.lastPathComponent
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formSection<Content: View>(label: String, required: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            HStack(spacing: 2) {
                Text(label.uppercased())
                if required { Text("*").foregroundColor(.red) }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.secondary)
            .tracking(1.2)
            content()
        }
    }
}

// MARK: - Duration pill

private struct EventDurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var label: String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60; let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    var body: some View {
        if isSelected {
            Button(action: onTap) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button(action: onTap) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }
}

// MARK: - Provider pill

private struct EventProviderButton: View {
    let provider: CalendarEvent.MeetProvider
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        if isSelected {
            Button(action: onTap) { label }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity)
        } else {
            Button(action: onTap) { label }
                .buttonStyle(.glass)
                .frame(maxWidth: .infinity)
        }
    }

    private var label: some View {
        HStack(spacing: 5) {
            if let assetName = provider.iconAssetName {
                Image(assetName)
                    .resizable().scaledToFit()
                    .frame(width: provider.iconNeedsWhiteChip ? 14 : 18,
                           height: provider.iconNeedsWhiteChip ? 14 : 18)
                    .padding(provider.iconNeedsWhiteChip ? 2 : 0)
                    .background(provider.iconNeedsWhiteChip ? Color.white : Color.clear,
                                in: RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: provider.icon)
                    .font(.system(size: 13))
            }
            Text(provider.shortName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .fixedSize()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
    }
}

// MARK: - Cover image picker label (nonisolated — avoids @MainActor capture warning)

private struct CoverPickerLabel: View {
    let hasCoverImage: Bool
    let isLoading: Bool

    // amber when image selected, teal otherwise
    private static let amberColor = Color(red: 1.0, green: 0.75, blue: 0.0)
    private var tintColor: Color { hasCoverImage && !isLoading ? Self.amberColor : .brandPrimary }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if isLoading {
                ProgressView()
                    .tint(.brandPrimary)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: hasCoverImage ? "pencil.circle.fill" : "photo.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(tintColor)
            }
            Text(isLoading
                 ? String(localized: "event.create.cover_image_loading", defaultValue: "Loading photo…")
                 : hasCoverImage
                   ? String(localized: "event.create.cover_image_change", defaultValue: "Change cover image")
                   : String(localized: "event.create.cover_image_add", defaultValue: "Add cover image"))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(tintColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .glassSurface(
            .regular.tint(tintColor.opacity(0.1)),
            shape: .roundedRect(cornerRadius: DesignSystem.CornerRadius.large)
        )
    }
}

// MARK: - Document picker wrapper

private struct DocumentPickerView: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .plainText, .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPicked(url)
        }
    }
}
