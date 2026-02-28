import UIKit

protocol StorageRepositoryProtocol {
    /// Uploads an image to remote storage and returns its URL.
    func uploadImage(image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void)
    
    /// Uploads a generic file document to remote storage and returns its URL.
    func uploadDocument(url: URL, path: String, completion: @escaping (Result<String, Error>) -> Void)
}
