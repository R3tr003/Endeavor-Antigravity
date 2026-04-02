import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import GoogleSignIn

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
            user.userType    = data["userType"] as? String ?? ""
            user.nationality = data["nationality"] as? String ?? ""
            user.languages   = data["languages"] as? [String] ?? []
            user.phone       = data["phone"] as? String ?? ""
            
            if let createdAtTimestamp = data["createdAt"] as? Timestamp {
                user.createdAt = createdAtTimestamp.dateValue()
            }
            if let lastLoginAtTimestamp = data["lastLoginAt"] as? Timestamp {
                user.lastLoginAt = lastLoginAtTimestamp.dateValue()
            }
            
            completion(.success(user))
        }
    }
    
    func fetchCompanyForUser(userId: String, completion: @escaping (CompanyProfile?) -> Void) {
        db.collection(companiesCollection).whereField("userId", isEqualTo: userId).limit(to: 1).getDocuments { snapshot, _ in
            guard let doc = snapshot?.documents.first else { completion(nil); return }
            let cData = doc.data()
            let company = CompanyProfile(
                id: UUID(uuidString: cData["id"] as? String ?? "") ?? UUID(),
                name: cData["name"] as? String ?? "",
                website: cData["website"] as? String ?? "",
                hqCountry: cData["hqCountry"] as? String ?? "",
                hqCity: cData["hqCity"] as? String ?? "",
                industries: cData["industries"] as? [String] ?? [],
                stage: cData["stage"] as? String ?? "",
                employeeRange: cData["employeeRange"] as? String ?? "",
                companyBio: cData["companyBio"] as? String ?? "",
                logoUrl: cData["logoUrl"] as? String ?? "",
                vertical: cData["vertical"] as? String ?? "",
                endeavorChapter: cData["endeavorChapter"] as? String ?? ""
            )
            completion(company)
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
                companyBio: data["companyBio"] as? String ?? "",
                logoUrl: data["logoUrl"] as? String ?? "",
                vertical:        data["vertical"]        as? String ?? "",
                endeavorChapter: data["endeavorChapter"] as? String ?? ""
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
    
    func findAnyUserDoc(email: String, completion: @escaping (UUID?) -> Void) {
        db.collection(usersCollection).whereField("email", isEqualTo: email).limit(to: 1).getDocuments { snapshot, _ in
            guard let doc = snapshot?.documents.first,
                  let idString = doc.data()["id"] as? String,
                  let uuid = UUID(uuidString: idString) else {
                completion(nil)
                return
            }
            completion(uuid)
        }
    }
    
    func findPartialUserProfile(email: String, completion: @escaping (UserProfile?, CompanyProfile?) -> Void) {
        db.collection(usersCollection).whereField("email", isEqualTo: email).limit(to: 1).getDocuments { [weak self] snapshot, _ in
            guard let self = self,
                  let doc = snapshot?.documents.first else {
                completion(nil, nil)
                return
            }
            
            let data = doc.data()
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
            user.userType    = data["userType"] as? String ?? ""
            user.nationality = data["nationality"] as? String ?? ""
            user.languages   = data["languages"] as? [String] ?? []
            user.phone       = data["phone"] as? String ?? ""
            
            if let createdAtTimestamp = data["createdAt"] as? Timestamp {
                user.createdAt = createdAtTimestamp.dateValue()
            }
            if let lastLoginAtTimestamp = data["lastLoginAt"] as? Timestamp {
                user.lastLoginAt = lastLoginAtTimestamp.dateValue()
            }
            
            // Try to fetch company, but don't fail if missing
            self.db.collection(self.companiesCollection).whereField("userId", isEqualTo: userId).limit(to: 1).getDocuments { snapshot, _ in
                if let companyDoc = snapshot?.documents.first {
                    let cData = companyDoc.data()
                    let company = CompanyProfile(
                        id: UUID(uuidString: cData["id"] as? String ?? "") ?? UUID(),
                        name: cData["name"] as? String ?? "",
                        website: cData["website"] as? String ?? "",
                        hqCountry: cData["hqCountry"] as? String ?? "",
                        hqCity: cData["hqCity"] as? String ?? "",
                        industries: cData["industries"] as? [String] ?? [],
                        stage: cData["stage"] as? String ?? "",
                        employeeRange: cData["employeeRange"] as? String ?? "",
                        companyBio: cData["companyBio"] as? String ?? "",
                        logoUrl: cData["logoUrl"] as? String ?? "",
                        vertical: cData["vertical"] as? String ?? ""
                    )
                    completion(user, company)
                } else {
                    completion(user, nil)
                }
            }
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
        user.userType    = data["userType"] as? String ?? ""
        user.nationality = data["nationality"] as? String ?? ""
        user.languages   = data["languages"] as? [String] ?? []
        user.phone       = data["phone"] as? String ?? ""
        
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
                    companyBio: data["companyBio"] as? String ?? "",
                    logoUrl: data["logoUrl"] as? String ?? "",
                    vertical:        data["vertical"]        as? String ?? "",
                    endeavorChapter: data["endeavorChapter"] as? String ?? ""
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
            "personalBio": user.personalBio,
            "userType": user.userType,
            "nationality": user.nationality,
            "languages": user.languages,
            "phone": user.phone
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
            "companyBio": company.companyBio,
            "logoUrl": company.logoUrl,
            "vertical":        company.vertical,
            "endeavorChapter": company.endeavorChapter
        ]
        db.collection(companiesCollection).document(company.id.uuidString).setData(data, completion: completion)
    }
    
    func saveUserAndCompany(user: UserProfile, company: CompanyProfile, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        // User data
        var userData: [String: Any] = [
            "id": user.id.uuidString,
            "firstName": user.firstName,
            "lastName": user.lastName,
            "role": user.role,
            "email": user.email,
            "location": user.location,
            "timeZone": user.timeZone,
            "profileImageUrl": user.profileImageUrl,
            "personalBio": user.personalBio,
            "userType": user.userType,
            "nationality": user.nationality,
            "languages": user.languages,
            "phone": user.phone
        ]
        if let createdAt = user.createdAt {
            userData["createdAt"] = Timestamp(date: createdAt)
        }
        if let lastLoginAt = user.lastLoginAt {
            userData["lastLoginAt"] = Timestamp(date: lastLoginAt)
        }
        
        let userRef = db.collection(usersCollection).document(user.id.uuidString)
        batch.setData(userData, forDocument: userRef, merge: true)
        
        // Company data
        let companyData: [String: Any] = [
            "id": company.id.uuidString,
            "userId": user.id.uuidString,
            "name": company.name,
            "website": company.website,
            "hqCountry": company.hqCountry,
            "hqCity": company.hqCity,
            "industries": company.industries,
            "stage": company.stage,
            "employeeRange": company.employeeRange,
            "companyBio": company.companyBio,
            "logoUrl": company.logoUrl,
            "vertical":        company.vertical,
            "endeavorChapter": company.endeavorChapter
        ]
        
        let companyRef = db.collection(companiesCollection).document(company.id.uuidString)
        batch.setData(companyData, forDocument: companyRef, merge: true)
        
        // Atomic commit — both succeed or both fail
        batch.commit(completion: completion)
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
    
    /// Re-authenticates the current user. Must be called BEFORE any sensitive operations.
    func reauthenticateUser(password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }

        let providers = user.providerData.map { $0.providerID }
        let isGoogleUser = providers.contains("google.com")

        if isGoogleUser {
            guard let presentingVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
                completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot present sign-in"]))
                return
            }

            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
                if let error = error {
                    completion(error)
                    return
                }

                guard let googleUser = signInResult?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google re-authentication failed"]))
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: googleUser.accessToken.tokenString
                )

                user.reauthenticate(with: credential) { _, error in
                    completion(error)
                }
            }
        } else if let password = password, let email = user.email {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                completion(error)
            }
        } else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required"]))
        }
    }

    /// Deletes the Firebase Auth account. Should be called AFTER deleteUserData and reauthenticateUser.
    func deleteAuthAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        user.delete(completion: completion)
    }
    
    func deleteUserData(email: String, userId: String, firebaseUid: String?, completion: @escaping (Error?) -> Void) {
        var deletionError: Error?
        let userIdsToCheck = [userId].filter { !$0.isEmpty }

        // STEP 1: Delete COMPANIES FIRST (before users!)
        // Security rules for company deletion require the user document to exist
        // to verify ownership via: get(/users/$(resource.data.userId)).data.email == request.auth.token.email
        let companyGroup = DispatchGroup()

        for uid in userIdsToCheck {
            companyGroup.enter()
            db.collection(companiesCollection).whereField("userId", isEqualTo: uid).getDocuments { snapshot, error in
                if let error = error {
                    deletionError = error
                    companyGroup.leave()
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    companyGroup.leave()
                    return
                }

                let companyDeleteGroup = DispatchGroup()
                for doc in documents {
                    companyDeleteGroup.enter()
                    doc.reference.delete { error in
                        if let error = error { deletionError = error }
                        companyDeleteGroup.leave()
                    }
                }
                companyDeleteGroup.notify(queue: .main) {
                    companyGroup.leave()
                }
            }
        }

        companyGroup.notify(queue: .main) { [weak self] in
            guard let self = self else {
                completion(deletionError)
                return
            }

            // Check if company deletion failed
            if let error = deletionError {
                completion(error)
                return
            }

            // STEP 2: Delete USER documents (after companies are gone)
            let userGroup = DispatchGroup()
            userGroup.enter()
            self.db.collection(self.usersCollection).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    deletionError = error
                    userGroup.leave()
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    userGroup.leave()
                    return
                }

                let deleteGroup = DispatchGroup()
                for doc in documents {
                    deleteGroup.enter()
                    doc.reference.delete { error in
                        if let error = error { deletionError = error }
                        deleteGroup.leave()
                    }
                }
                deleteGroup.notify(queue: .main) {
                    userGroup.leave()
                }
            }

            userGroup.notify(queue: .main) {
                // STEP 3: Delete profile images from Storage
                let storageGroup = DispatchGroup()
                let storageRef = Storage.storage().reference()

                if let fUid = firebaseUid {
                    storageGroup.enter()
                    storageRef.child("profile_images/\(fUid).jpg").delete { _ in
                        storageGroup.leave()
                    }
                }

                if !userId.isEmpty && userId != firebaseUid {
                    storageGroup.enter()
                    storageRef.child("profile_images/\(userId).jpg").delete { _ in
                        storageGroup.leave()
                    }
                }

                storageGroup.notify(queue: .main) {
                    // STEP 4: Delete messaging DB contents
                    let messagingDb = Firestore.firestore(database: "messaging")
                    messagingDb.collection("conversations")
                        .whereField("participantIds", arrayContains: userId)
                        .getDocuments { snapshot, error in
                            if let error = error {
                                deletionError = error
                                completion(deletionError)
                                return
                            }

                            guard let documents = snapshot?.documents, !documents.isEmpty else {
                                // No conversations, just remove the mapping
                                if let fUid = firebaseUid {
                                    messagingDb.collection("userMappings").document(fUid).delete { _ in
                                        completion(deletionError)
                                    }
                                } else {
                                    completion(deletionError)
                                }
                                return
                            }

                            let convsGroup = DispatchGroup()
                            let storageRef = Storage.storage().reference()
                            
                            for doc in documents {
                                convsGroup.enter()
                                let ref = doc.reference
                                let conversationId = doc.documentID

                                let mediaGroup = DispatchGroup()
                                let msgGroup = DispatchGroup()
                                
                                // 1. Delete chat media (images/ and docs/ subfolders)
                                let subfolders = ["images", "docs"]
                                for subfolder in subfolders {
                                    mediaGroup.enter()
                                    storageRef.child("chat_media/\(conversationId)/\(subfolder)").listAll { result, _ in
                                        if let items = result?.items {
                                            for item in items {
                                                mediaGroup.enter()
                                                item.delete { _ in mediaGroup.leave() }
                                            }
                                        }
                                        mediaGroup.leave()
                                    }
                                }
                                
                                // 2. Delete messages
                                msgGroup.enter()
                                ref.collection("messages").getDocuments { msgSnapshot, _ in
                                    if let msgs = msgSnapshot?.documents, !msgs.isEmpty {
                                        for msg in msgs {
                                            msgGroup.enter()
                                            msg.reference.delete { _ in msgGroup.leave() }
                                        }
                                    }
                                    msgGroup.leave()
                                }
                                
                                // Wait for both media and messages
                                let aggregateGroup = DispatchGroup()
                                aggregateGroup.enter()
                                mediaGroup.notify(queue: .main) { aggregateGroup.leave() }
                                aggregateGroup.enter()
                                msgGroup.notify(queue: .main) { aggregateGroup.leave() }
                                
                                aggregateGroup.notify(queue: .main) {
                                    ref.delete { _ in convsGroup.leave() }
                                }
                            }

                            convsGroup.notify(queue: .main) {
                                if let fUid = firebaseUid {
                                    messagingDb.collection("userMappings").document(fUid).delete { _ in
                                        completion(deletionError)
                                    }
                                } else {
                                    completion(deletionError)
                                }
                            }
                        }
                }
            }
        }
    }
    func generateIcalToken(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let token = UUID().uuidString
        let expiry = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
        db.collection(usersCollection).document(userId).updateData([
            "icalToken": token,
            "icalTokenExpiry": Timestamp(date: expiry)
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(token))
            }
        }
    }

    func revokeIcalToken(userId: String, completion: @escaping (Error?) -> Void) {
        // Rotation: write a brand-new token so old subscription URLs stop working immediately.
        let newToken = UUID().uuidString
        let expiry = Date().addingTimeInterval(7 * 24 * 60 * 60)
        db.collection(usersCollection).document(userId).updateData([
            "icalToken": newToken,
            "icalTokenExpiry": Timestamp(date: expiry)
        ], completion: completion)
    }
}
