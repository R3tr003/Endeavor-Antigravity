import UIKit
import FirebaseStorage
import FirebasePerformance
import UniformTypeIdentifiers

class FirebaseStorageRepository: StorageRepositoryProtocol {
    init() {}
    
    func uploadImage(image: UIImage, path: String, uploaderId: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let trace = Performance.startTrace(name: "Image_Upload_Duration")
        
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            trace?.stop()
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        trace?.setValue(Int64(imageData.count), forMetric: "image_size_bytes")
        
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        if let uid = uploaderId {
            // Path format: chat_media/{conversationId}/images/{fileId}
            let conversationId = path.split(separator: "/").dropFirst().first.map(String.init) ?? ""
            metadata.customMetadata = [
                "uploaderId": uid,
                "conversationId": conversationId
            ]
        }
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                trace?.stop()
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                trace?.stop()
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    func uploadDocument(url: URL, path: String, uploaderId: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let trace = Performance.startTrace(name: "Document_Upload_Duration")
        
        guard url.startAccessingSecurityScopedResource() else {
            trace?.stop()
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied reading file"])))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let fileData = try Data(contentsOf: url)
            let storageRef = Storage.storage().reference().child(path)
            let metadata = StorageMetadata()
            // Detect the real MIME type from the file extension so the Storage
            // content-type allowlist rule (PDF / Word / OOXML / plain text) can
            // validate it. Falls back to octet-stream if unknown — Storage will
            // reject that by design.
            if #available(iOS 14.0, *),
               let utType = UTType(filenameExtension: url.pathExtension),
               let mimeType = utType.preferredMIMEType {
                metadata.contentType = mimeType
            } else {
                metadata.contentType = "application/octet-stream"
            }
            if let uid = uploaderId {
                // Path format: chat_media/{conversationId}/docs/{fileId}
                let conversationId = path.split(separator: "/").dropFirst().first.map(String.init) ?? ""
                metadata.customMetadata = [
                    "uploaderId": uid,
                    "conversationId": conversationId
                ]
            }
            
            storageRef.putData(fileData, metadata: metadata) { metadata, error in
                if let error = error {
                    trace?.stop()
                    completion(.failure(error))
                    return
                }
                
                storageRef.downloadURL { downloadUrl, error in
                    trace?.stop()
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard let secureURL = downloadUrl else {
                        completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"])))
                        return
                    }
                    completion(.success(secureURL.absoluteString))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
}
