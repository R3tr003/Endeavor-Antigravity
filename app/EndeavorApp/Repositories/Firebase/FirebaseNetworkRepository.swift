import Foundation
import FirebaseFirestore

class FirebaseNetworkRepository: NetworkRepositoryProtocol {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    init() {}
    
    func fetchAllUsers(limit: Int, lastDocument: DocumentSnapshot?, completion: @escaping ([UserProfile], DocumentSnapshot?) -> Void) {
        var query: Query = db.collection(usersCollection).limit(to: limit)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching users: \(error)")
                completion([], nil)
                return
            }
            
            let users = snapshot?.documents.compactMap { doc -> UserProfile? in
                let data = doc.data()
                return UserProfile(
                    id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    role: data["role"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    timeZone: data["timeZone"] as? String ?? "",
                    profileImageUrl: data["profileImageUrl"] as? String ?? "",
                    personalBio: data["personalBio"] as? String ?? ""
                )
            } ?? []
            
            completion(users, snapshot?.documents.last)
        }
    }
}
