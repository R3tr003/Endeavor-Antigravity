import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseUserRepository: UserRepositoryProtocol {
    private let usersCollection = "users"
    private let companiesCollection = "companies"
    private let db = Firestore.firestore()
    
    init() {}
    
    func fetchUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        db.collection(usersCollection).document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            var user = UserProfile(
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
            
            if let createdAtTimestamp = data["createdAt"] as? Timestamp {
                user.createdAt = createdAtTimestamp.dateValue()
            }
            if let lastLoginAtTimestamp = data["lastLoginAt"] as? Timestamp {
                user.lastLoginAt = lastLoginAtTimestamp.dateValue()
            }
            
            completion(.success(user))
        }
    }
    
    func fetchCompanyProfile(companyId: String, completion: @escaping (Result<CompanyProfile, Error>) -> Void) {
        db.collection(companiesCollection).document(companyId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Company not found"])))
                return
            }
            
            let company = CompanyProfile(
                id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                name: data["name"] as? String ?? "",
                website: data["website"] as? String ?? "",
                hqCountry: data["hqCountry"] as? String ?? "",
                hqCity: data["hqCity"] as? String ?? "",
                industries: data["industries"] as? [String] ?? [],
                stage: data["stage"] as? String ?? "",
                employeeRange: data["employeeRange"] as? String ?? "",
                challenges: data["challenges"] as? [String] ?? [],
                desiredExpertise: data["desiredExpertise"] as? [String] ?? [],
                companyBio: data["companyBio"] as? String ?? ""
            )
            completion(.success(company))
        }
    }
    
    func findCompleteUserProfile(email: String, completion: @escaping (Result<(UserProfile, CompanyProfile), Error>) -> Void) {
        db.collection(usersCollection).whereField("email", isEqualTo: email).getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                completion(.failure(NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No user found for email"])))
                return
            }
            
            self?.findUserWithCompany(documents: documents, index: 0, completion: completion)
        }
    }
    
    private func findUserWithCompany(documents: [QueryDocumentSnapshot], index: Int, completion: @escaping (Result<(UserProfile, CompanyProfile), Error>) -> Void) {
        guard index < documents.count else {
            completion(.failure(NSError(domain: "AppError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No user with company found"])))
            return
        }
        
        let data = documents[index].data()
        let userId = data["id"] as? String ?? ""
        
        var user = UserProfile(
            id: UUID(uuidString: userId) ?? UUID(),
            firstName: data["firstName"] as? String ?? "",
            lastName: data["lastName"] as? String ?? "",
            role: data["role"] as? String ?? "",
            email: data["email"] as? String ?? "",
            location: data["location"] as? String ?? "",
            timeZone: data["timeZone"] as? String ?? "",
            profileImageUrl: data["profileImageUrl"] as? String ?? "",
            personalBio: data["personalBio"] as? String ?? ""
        )
        
        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            user.createdAt = createdAtTimestamp.dateValue()
        }
        if let lastLoginAtTimestamp = data["lastLoginAt"] as? Timestamp {
            user.lastLoginAt = lastLoginAtTimestamp.dateValue()
        }
        
        db.collection(companiesCollection).whereField("userId", isEqualTo: userId).limit(to: 1).getDocuments { [weak self] snapshot, error in
            if let document = snapshot?.documents.first {
                let data = document.data()
                let company = CompanyProfile(
                    id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                    name: data["name"] as? String ?? "",
                    website: data["website"] as? String ?? "",
                    hqCountry: data["hqCountry"] as? String ?? "",
                    hqCity: data["hqCity"] as? String ?? "",
                    industries: data["industries"] as? [String] ?? [],
                    stage: data["stage"] as? String ?? "",
                    employeeRange: data["employeeRange"] as? String ?? "",
                    challenges: data["challenges"] as? [String] ?? [],
                    desiredExpertise: data["desiredExpertise"] as? [String] ?? [],
                    companyBio: data["companyBio"] as? String ?? ""
                )
                completion(.success((user, company)))
            } else {
                self?.findUserWithCompany(documents: documents, index: index + 1, completion: completion)
            }
        }
    }
    
    func saveUserProfile(_ user: UserProfile, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "id": user.id.uuidString,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "role": user.role,
            "email": user.email,
            "location": user.location,
            "timeZone": user.timeZone,
            "profileImageUrl": user.profileImageUrl,
            "personalBio": user.personalBio
        ]
        
        if let createdAt = user.createdAt {
            data["createdAt"] = Timestamp(date: createdAt)
        }
        if let lastLoginAt = user.lastLoginAt {
            data["lastLoginAt"] = Timestamp(date: lastLoginAt)
        }
        
        db.collection(usersCollection).document(user.id.uuidString).setData(data, completion: completion)
    }
    
    func saveCompanyProfile(_ company: CompanyProfile, userId: String, completion: @escaping (Error?) -> Void) {
        let data: [String: Any] = [
            "id": company.id.uuidString,
            "userId": userId,
            "name": company.name,
            "website": company.website,
            "hqCountry": company.hqCountry,
            "hqCity": company.hqCity,
            "industries": company.industries,
            "stage": company.stage,
            "employeeRange": company.employeeRange,
            "challenges": company.challenges,
            "desiredExpertise": company.desiredExpertise,
            "companyBio": company.companyBio
        ]
        db.collection(companiesCollection).document(company.id.uuidString).setData(data, completion: completion)
    }
    
    func changeUserEmail(newEmail: String, password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        db.collection(usersCollection).whereField("email", isEqualTo: newEmail).limit(to: 1).getDocuments { snapshot, error in
            if let docs = snapshot?.documents, !docs.isEmpty {
                completion(NSError(domain: "AppError", code: 17007, userInfo: [NSLocalizedDescriptionKey: "EMAIL_ALREADY_IN_USE"]))
                return
            }
            
            let providers = user.providerData.map { $0.providerID }
            let isGoogleUser = providers.contains("google.com")
            
            let sendVerification = {
                user.sendEmailVerification(beforeUpdatingEmail: newEmail, completion: completion)
            }
            
            if isGoogleUser {
                sendVerification()
            } else if let password = password, let email = user.email {
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.reauthenticate(with: credential) { result, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    sendVerification()
                }
            } else {
                completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required"]))
            }
        }
    }
    
    func deleteAuthAccount(password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        let providers = user.providerData.map { $0.providerID }
        let isGoogleUser = providers.contains("google.com")
        
        if isGoogleUser {
            user.delete(completion: completion)
        } else if let password = password, let email = user.email {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { result, error in
                if let error = error {
                    completion(error)
                    return
                }
                user.delete(completion: completion)
            }
        } else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required"]))
        }
    }
    
    func deleteUserData(email: String, userId: String, completion: @escaping (Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var deletionError: Error?
        var foundUserId: String? = nil
        
        dispatchGroup.enter()
        db.collection(usersCollection).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                deletionError = error
                dispatchGroup.leave()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                dispatchGroup.leave()
                return
            }
            
            let deleteGroup = DispatchGroup()
            for doc in documents {
                deleteGroup.enter()
                if let docUserId = doc.data()["id"] as? String {
                    foundUserId = docUserId
                }
                doc.reference.delete { error in
                    if let error = error { deletionError = error }
                    deleteGroup.leave()
                }
            }
            deleteGroup.notify(queue: .main) {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let companyGroup = DispatchGroup()
            let userIdsToCheck = Array(Set([userId, foundUserId].compactMap { $0 }))
            
            for uid in userIdsToCheck {
                companyGroup.enter()
                self.db.collection(self.companiesCollection).whereField("userId", isEqualTo: uid).getDocuments { snapshot, error in
                    if let error = error {
                        deletionError = error
                        companyGroup.leave()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        companyGroup.leave()
                        return
                    }
                    
                    for doc in documents {
                        doc.reference.delete { error in
                            if let error = error { deletionError = error }
                        }
                    }
                    companyGroup.leave()
                }
            }
            
            companyGroup.enter()
            let imagePath = "profile_images/\(userId).jpg"
            Storage.storage().reference().child(imagePath).delete { _ in
                companyGroup.leave()
            }
            
            companyGroup.notify(queue: .main) {
                completion(deletionError)
            }
        }
    }
}
