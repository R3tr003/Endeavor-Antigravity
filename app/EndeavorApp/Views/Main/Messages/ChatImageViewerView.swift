import SwiftUI
import SDWebImageSwiftUI
import Photos

// MARK: - Model

struct ChatImageItem {
    let url: String
    let senderName: String
    let timestamp: Date
}

// MARK: - Viewer

struct ChatImageViewerView: View {
    let images: [ChatImageItem]
    @Environment(\.dismiss) var dismiss

    @State private var currentIndex: Int
    @State private var scrollPosition: Int?
    @State private var dismissDrag: CGFloat = 0
    @State private var isUIHidden = false
    @State private var isZoomed = false
    @State private var saveStatus: SaveStatus = .idle
    @State private var showPermissionAlert = false

    enum SaveStatus { case idle, saving, saved, error }

    init(images: [ChatImageItem], initialIndex: Int = 0) {
        self.images = images
        let clamped = max(0, min(initialIndex, images.count - 1))
        self._currentIndex = State(initialValue: clamped)
        self._scrollPosition = State(initialValue: clamped)
    }

    private let topScrim = Gradient(stops: [
        .init(color: .black.opacity(0.90), location: 0.0),
        .init(color: .black.opacity(0.40), location: 0.7),
        .init(color: .clear,               location: 1.0)
    ])
    private let bottomScrim = Gradient(stops: [
        .init(color: .clear,               location: 0.0),
        .init(color: .black.opacity(0.40), location: 0.3),
        .init(color: .black.opacity(0.90), location: 1.0)
    ])

    private var currentItem: ChatImageItem? {
        images.indices.contains(currentIndex) ? images[currentIndex] : nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .opacity(1.0 - abs(dismissDrag) / 400.0)
                .edgesIgnoringSafeArea(.all)

            // Native paging scroll view — always follows the finger
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(images.indices, id: \.self) { idx in
                        ZoomableImageView(
                            url: images[idx].url,
                            index: idx,
                            currentIndex: currentIndex,
                            onSingleTap: {
                                withAnimation(.easeInOut(duration: 0.2)) { isUIHidden.toggle() }
                            },
                            onZoomChanged: { zoomed in
                                isZoomed = zoomed
                                withAnimation(.easeInOut(duration: 0.2)) { isUIHidden = zoomed }
                            }
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(idx)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .scrollIndicators(.hidden)
            .scrollDisabled(isZoomed)  // hand gesture control to ZoomableImageView when zoomed
            .offset(y: dismissDrag)
            // Vertical swipe-to-dismiss — disabled while image is zoomed
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { v in
                        guard !isZoomed else { return }
                        let dy = abs(v.translation.height)
                        let dx = abs(v.translation.width)
                        guard dy > dx * 1.5 else { return }
                        dismissDrag = v.translation.height
                    }
                    .onEnded { v in
                        guard !isZoomed else { return }
                        if abs(dismissDrag) > 120 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) { dismissDrag = 0 }
                        }
                    }
            )
            .onChange(of: scrollPosition) { _, newPos in
                if let pos = newPos, pos != currentIndex { currentIndex = pos }
            }
            .onChange(of: currentIndex) { _, newIdx in
                if scrollPosition != newIdx {
                    withAnimation { scrollPosition = newIdx }
                }
            }

            topBar
                .opacity(isUIHidden ? 0 : 1.0 - abs(dismissDrag) / 300.0)
                .animation(.easeInOut(duration: 0.2), value: isUIHidden)
            bottomArea
                .opacity(isUIHidden ? 0 : 1.0 - abs(dismissDrag) / 300.0)
                .animation(.easeInOut(duration: 0.2), value: isUIHidden)
        }
        .statusBarHidden(isUIHidden)
        .alert(
            String(localized: "messages.photos_permission_title", defaultValue: "Photos Access Required"),
            isPresented: $showPermissionAlert
        ) {
            Button(String(localized: "settings.open_settings", defaultValue: "Open Settings")) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button(String(localized: "common.cancel", defaultValue: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "messages.photos_permission_body",
                        defaultValue: "Allow Endeavor to save photos in iOS Settings > Privacy > Photos."))
        }
    }

    // MARK: - Top Bar (centered date/time, no avatar/name)

    private var topBar: some View {
        VStack(spacing: 0) {
            LinearGradient(gradient: topScrim, startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
                .overlay(alignment: .top) {
                    ZStack(alignment: .center) {
                        // Centered timestamp — large
                        Text(formattedTimestamp(currentItem?.timestamp ?? Date()))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)

                        // Close button — right side
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Color.white.opacity(0.20), in: Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.top, DesignSystem.Spacing.standard)
                }
            Spacer()
        }
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        let showThumbs = images.count > 1
        let height: CGFloat = showThumbs ? 185 : 110

        return VStack(spacing: 0) {
            Spacer()
            LinearGradient(gradient: bottomScrim, startPoint: .top, endPoint: .bottom)
                .frame(height: height)
                .overlay(alignment: .bottom) {
                    VStack(spacing: 10) {
                        if showThumbs { thumbnailStrip }
                        actionButtons
                            .padding(.bottom, DesignSystem.Spacing.large)
                    }
                }
        }
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(images.indices, id: \.self) { idx in
                            WebImage(url: URL(string: images[idx].url))
                                .resizable()
                                .indicator(.activity)
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipped()
                                .cornerRadius(DesignSystem.CornerRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                        .stroke(idx == currentIndex ? Color.brandPrimary : Color.clear, lineWidth: 2.5)
                                )
                                .opacity(idx == currentIndex ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        currentIndex = idx
                                    }
                                }
                                .id(idx)
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(minWidth: geo.size.width, alignment: .center)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }
                .onChange(of: currentIndex) { _, newIdx in
                    withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
                }
                .onAppear { proxy.scrollTo(currentIndex, anchor: .center) }
            }
        }
        .frame(height: 52 + 8) // +8 for vertical padding so border is never clipped
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 56) {
            // Save
            Button(action: saveImage) {
                VStack(spacing: 5) {
                    Group {
                        if saveStatus == .saving {
                            ProgressView().tint(.white)
                        } else if saveStatus == .saved {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.brandPrimary)
                        } else {
                            Image(systemName: "arrow.down.to.line").foregroundColor(.white)
                        }
                    }
                    .font(.system(size: 26, weight: .medium))
                    .frame(width: 28, height: 28)

                    Text(saveStatus == .saved
                         ? String(localized: "messages.saved", defaultValue: "Saved!")
                         : String(localized: "messages.save", defaultValue: "Save"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(saveStatus == .saved ? Color.brandPrimary : .white)
                }
            }
            .disabled(saveStatus == .saving || saveStatus == .saved)

            // Share
            Button(action: shareImage) {
                VStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                    Text(String(localized: "messages.share", defaultValue: "Share"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(date) { return "Today, \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday, \(time)" }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let isThisYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
        formatter.setLocalizedDateFormatFromTemplate(isThisYear ? "dMMM" : "dMMMy")
        return "\(formatter.string(from: date)), \(time)"
    }

    private func topViewController(_ root: UIViewController?) -> UIViewController? {
        if let presented = root?.presentedViewController {
            return topViewController(presented)
        }
        return root
    }

    // MARK: - Save

    private func saveImage() {
        guard let item = currentItem else { return }
        saveStatus = .saving
        guard let url = URL(string: item.url) else { saveStatus = .error; return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { saveStatus = .error }
                return
            }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        withAnimation { saveStatus = .saved }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saveStatus = .idle }
                        }
                        AnalyticsService.shared.logChatImageSaved()
                    } else {
                        saveStatus = .idle
                        showPermissionAlert = true
                    }
                }
            }
        }.resume()
    }

    // MARK: - Share

    private func shareImage() {
        guard let item = currentItem, let url = URL(string: item.url) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )
                guard
                    let windowScene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first(where: { $0.activationState == .foregroundActive }),
                    let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
                    let presentingVC = topViewController(keyWindow.rootViewController)
                else { return }

                activityVC.popoverPresentationController?.sourceView = presentingVC.view
                activityVC.popoverPresentationController?.sourceRect = CGRect(
                    x: presentingVC.view.bounds.midX,
                    y: presentingVC.view.bounds.maxY - 80,
                    width: 0, height: 0
                )
                presentingVC.present(activityVC, animated: true)
            }
        }.resume()
    }
}

// MARK: - Zoomable and Full Screen Image

private struct ZoomableImageView: View {
    let url: String
    let index: Int
    let currentIndex: Int
    var onSingleTap: () -> Void
    var onZoomChanged: (Bool) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var viewSize: CGSize = .zero

    var body: some View {
        WebImage(url: URL(string: url)) { image in
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .scaleEffect(scale)
                .offset(offset)
                // Capture view size without wrapping in GeometryReader (avoids gesture conflicts)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { viewSize = geo.size }
                            .onChange(of: geo.size) { _, new in viewSize = new }
                    }
                )
                // Pan — only active when zoomed; disabled at scale 1 so ScrollView paging works
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { v in
                            let newX = lastOffset.width  + v.translation.width
                            let newY = lastOffset.height + v.translation.height
                            let maxX = max(0, (scale - 1) * viewSize.width  / 2)
                            let maxY = max(0, (scale - 1) * viewSize.height / 2)
                            offset = CGSize(
                                width:  max(-maxX, min(maxX, newX)),
                                height: max(-maxY, min(maxY, newY))
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        },
                    isEnabled: scale > 1.0
                )
                // Pinch-to-zoom
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = min(max(lastScale * value, 1.0), 5.0)
                            scale = newScale
                            if newScale > 1.0 { onZoomChanged(true) }
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale <= 1.0 {
                                withAnimation(.spring()) { resetZoom() }
                                onZoomChanged(false)
                            }
                        }
                )
                // double-tap first so SwiftUI waits before firing single-tap
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1.0 { resetZoom(); onZoomChanged(false) }
                        else           { scale = 2.5; lastScale = 2.5; onZoomChanged(true) }
                    }
                }
                .onTapGesture(count: 1) { onSingleTap() }
        } placeholder: {
            ProgressView().tint(.white)
        }
        // Reset zoom/pan when the user swipes to a different image
        .onChange(of: currentIndex) { _, newIdx in
            if newIdx != index {
                withAnimation(.spring()) { resetZoom() }
                onZoomChanged(false)
            }
        }
    }

    private func resetZoom() {
        scale = 1.0; lastScale = 1.0
        offset = .zero; lastOffset = .zero
    }
}
