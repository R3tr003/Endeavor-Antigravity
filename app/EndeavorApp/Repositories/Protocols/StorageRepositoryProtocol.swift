import UIKit

protocol StorageRepositoryProtocol {
    /// Uploads an image to remote storage and returns its URL.
    /// - Parameters:
    ///   - image: The image to upload.
    ///   - path: The storage path.
    ///   - uploaderId: Optional Firebase UID of the uploader. When provided, stored as
    ///     custom metadata so Storage Rules can enforce uploader-only delete.
    func uploadImage(image: UIImage, path: String, uploaderId: String?, completion: @escaping (Result<String, Error>) -> Void)

    /// Uploads a generic file document to remote storage and returns its URL.
    /// - Parameters:
    ///   - url: The local file URL.
    ///   - path: The storage path.
    ///   - uploaderId: Optional Firebase UID of the uploader. When provided, stored as
    ///     custom metadata so Storage Rules can enforce uploader-only delete.
    func uploadDocument(url: URL, path: String, uploaderId: String?, completion: @escaping (Result<String, Error>) -> Void)
}
