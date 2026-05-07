import Foundation
import Combine
import SwiftUI
import PhotosUI

@MainActor
class CreateEndeavourEventViewModel: ObservableObject {

    // MARK: - Form fields

    @Published var title = ""
    @Published var category: CalendarEvent.EventCategory = .other
    @Published var startDate = Date()
    @Published var durationMinutes = 60
    @Published var location = ""
    @Published var meetProvider: CalendarEvent.MeetProvider = .none
    @Published var eventDescription = ""
    @Published var enableMaxParticipants = false
    @Published var maxParticipantsText: String = ""

    var maxParticipants: Int? {
        guard enableMaxParticipants, let val = Int(maxParticipantsText), val > 0 else { return nil }
        return val
    }
    @Published var selectedCoverImage: UIImage? = nil
    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var attachmentLocalUrl: URL? = nil
    @Published var attachmentName: String? = nil

    // MARK: - Edit mode (populated when editing an existing event)

    private(set) var existingEventId: String? = nil
    var existingCoverImageUrl: String? = nil
    var existingAttachmentUrl: String? = nil
    var existingAttachmentName: String? = nil

    // MARK: - UI state

    @Published var isSaving = false
    @Published var errorMessage: String? = nil

    // MARK: - Computed

    var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var endDate: Date {
        Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
    }

    // MARK: - Dependencies

    private let calendarRepo = FirebaseCalendarRepository()
    private let storageRepo = FirebaseStorageRepository()

    // MARK: - Convenience init for edit mode

    convenience init(existingEvent: CalendarEvent) {
        self.init()
        existingEventId = existingEvent.id
        title = existingEvent.title
        category = existingEvent.category
        startDate = existingEvent.startDate
        let durationOptions = [30, 60, 90, 120, 180, 240]
        let mins = Int(existingEvent.endDate.timeIntervalSince(existingEvent.startDate) / 60)
        durationMinutes = durationOptions.min(by: { abs($0 - mins) < abs($1 - mins) }) ?? 60
        location = existingEvent.location ?? ""
        meetProvider = existingEvent.meetProvider
        eventDescription = existingEvent.description
        existingCoverImageUrl = existingEvent.coverImageUrl
        existingAttachmentUrl = existingEvent.attachmentUrl
        existingAttachmentName = existingEvent.attachmentName
        if let maxP = existingEvent.maxParticipants {
            enableMaxParticipants = true
            maxParticipantsText = "\(maxP)"
        }
    }

    // MARK: - Photo picker handling

    func loadSelectedPhoto() {
        guard let item = selectedPhotoItem else { return }
        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedCoverImage = image
            }
        }
    }

    // MARK: - Save

    func save(currentUserId: String, completion: @escaping () -> Void) {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil

        let eventId = UUID().uuidString

        uploadCoverIfNeeded(eventId: eventId, userId: currentUserId) { [weak self] coverUrl in
            guard let self else { return }
            self.uploadAttachmentIfNeeded(eventId: eventId, userId: currentUserId) { [weak self] attUrl, attName in
                guard let self else { return }

                let event = CalendarEvent(
                    id: eventId,
                    title: self.title.trimmingCharacters(in: .whitespaces),
                    description: self.eventDescription,
                    startDate: self.startDate,
                    endDate: self.endDate,
                    type: .endeavorEvent,
                    status: .confirmed,
                    createdBy: currentUserId,
                    participantIds: [currentUserId],
                    conversationId: nil,
                    location: self.location.isEmpty ? nil : self.location,
                    meetLink: nil,
                    meetProvider: self.meetProvider,
                    declinedBy: [],
                    rescheduledBy: [],
                    createdAt: Date(),
                    category: self.category,
                    coverImageUrl: coverUrl,
                    attachmentUrl: attUrl,
                    attachmentName: attName,
                    maxParticipants: self.maxParticipants
                )

                self.calendarRepo.saveEvent(event) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let savedId):
                        if self.meetProvider != .none {
                            MeetProviderService.shared.generateMeetLink(
                                eventId: savedId,
                                provider: self.meetProvider,
                                userId: currentUserId
                            ) { [weak self] _ in
                                DispatchQueue.main.async {
                                    self?.isSaving = false
                                    completion()
                                }
                            }
                        } else {
                            self.isSaving = false
                            completion()
                        }
                    case .failure:
                        self.isSaving = false
                        self.errorMessage = AppError.endeavourEventSaveFailed.errorDescription
                    }
                }
            }
        }
    }

    // MARK: - Save changes (edit mode)

    func saveChanges(currentUserId: String, completion: @escaping () -> Void) {
        guard let eventId = existingEventId, isValid else { return }
        isSaving = true
        errorMessage = nil

        uploadCoverIfNeeded(eventId: eventId, userId: currentUserId) { [weak self] newCoverUrl in
            guard let self else { return }
            let coverUrl = newCoverUrl ?? self.existingCoverImageUrl

            self.uploadAttachmentIfNeeded(eventId: eventId, userId: currentUserId) { [weak self] newAttUrl, newAttName in
                guard let self else { return }
                let attUrl = newAttUrl ?? self.existingAttachmentUrl
                let attName = newAttName ?? self.existingAttachmentName

                var fields: [String: Any] = [
                    "title": self.title.trimmingCharacters(in: .whitespaces),
                    "description": self.eventDescription,
                    "startDate": self.startDate,
                    "endDate": self.endDate,
                    "category": self.category.rawValue,
                    "meetProvider": self.meetProvider.rawValue,
                    "lastModifiedBy": currentUserId   // used by CF to exclude editor from notifications
                ]
                if self.location.isEmpty { fields["location"] = NSNull() } else { fields["location"] = self.location }
                if let maxP = self.maxParticipants { fields["maxParticipants"] = maxP } else { fields["maxParticipants"] = NSNull() }
                if let url = coverUrl { fields["coverImageUrl"] = url } else { fields["coverImageUrl"] = NSNull() }
                if let url = attUrl  { fields["attachmentUrl"]  = url } else { fields["attachmentUrl"]  = NSNull() }
                if let name = attName { fields["attachmentName"] = name } else { fields["attachmentName"] = NSNull() }

                self.calendarRepo.updateEndeavourEvent(eventId: eventId, fields: fields) { [weak self] error in
                    guard let self else { return }
                    self.isSaving = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        completion()
                    }
                }
            }
        }
    }

    // MARK: - Private upload helpers

    private func uploadCoverIfNeeded(eventId: String, userId: String, completion: @escaping (String?) -> Void) {
        guard let image = selectedCoverImage else { completion(nil); return }
        let path = "event_covers/\(eventId)/cover.jpg"
        storageRepo.uploadImage(image: image, path: path, uploaderId: userId) { result in
            completion(try? result.get())
        }
    }

    private func uploadAttachmentIfNeeded(eventId: String, userId: String, completion: @escaping (String?, String?) -> Void) {
        guard let url = attachmentLocalUrl else { completion(nil, nil); return }
        let name = attachmentName ?? url.lastPathComponent
        let path = "event_attachments/\(eventId)/\(name)"
        storageRepo.uploadDocument(url: url, path: path, uploaderId: userId) { result in
            if let downloadUrl = try? result.get() {
                completion(downloadUrl, name)
            } else {
                completion(nil, nil)
            }
        }
    }
}
