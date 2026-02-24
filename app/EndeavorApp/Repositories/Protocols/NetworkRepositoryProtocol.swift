import Foundation
import FirebaseFirestore // Only needed for DocumentSnapshot, we can abstract this away later if desired

protocol NetworkRepositoryProtocol {
    /// Fetches a paginated list of UserProfiles.
    /// `lastDocument` is used for cursor-based pagination.
    func fetchAllUsers(limit: Int, lastDocument: DocumentSnapshot?, completion: @escaping ([UserProfile], DocumentSnapshot?) -> Void)
}
