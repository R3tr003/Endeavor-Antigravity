import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics
import FirebaseStorage


/// FirebaseService handles all Firestore operations for user and company profiles.
/// This service abstracts Firebase interactions from the rest of the app.
class FirebaseService {
    static let shared = FirebaseService()
    
    // Firestore collection names
    private let usersCollection = "users"
    private let companiesCollection = "companies"
    
    private init() {}
    
    // MARK: - Firebase Configuration
    
    /// Call this in App.swift's init to configure Firebase
    static func configure() {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully!")
        
        // Log a test event on startup
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "platform": "iOS",
            "app_version": "1.0.0"
        ])
        print("📊 Analytics: App Open event logged")

    }
    
    /// Helper to log custom events
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        print("📊 Analytics: Logged event '\(name)'")
    }
    
    // MARK: - Authentication
    
    /// Sign Up with Email & Password
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    
    /// Sign In with Email & Password
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success(user))
            }
        }
    }

    /// Send Password Reset Email
    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("❌ Error sending password reset: \(error.localizedDescription)")
            } else {
                print("✅ Password reset email sent to \(email)")
            }
            completion(error)
        }
    }
    

    
    // MARK: - Social Authentication
    
    /// Sign In with Apple (exchanging ID Token)

    
    /// Sign In with Google (exchanging ID Token & Access Token)
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    


    // MARK: - User Profile Operations
    
    /// Save user profile to Firestore
    func saveUserProfile(_ user: UserProfile, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let data: [String: Any] = [
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
        
        db.collection(usersCollection).document(user.id.uuidString).setData(data) { error in
            if let error = error {
                print("❌ Error saving user: \(error)")
                completion(error)
            } else {
                print("✅ User profile saved to Firestore")
                completion(nil)
            }
        }
    }
    
    /// Save company profile to Firestore
    func saveCompanyProfile(_ company: CompanyProfile, userId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
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
        
        db.collection(companiesCollection).document(company.id.uuidString).setData(data) { error in
            if let error = error {
                print("❌ Error saving company: \(error)")
                completion(error)
            } else {
                print("✅ Company profile saved to Firestore")
                completion(nil)
            }
        }
    }
    
    /// Load user profile from Firestore
    func loadUserProfile(userId: String, completion: @escaping (UserProfile?) -> Void) {
        let db = Firestore.firestore()
        db.collection(usersCollection).document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error loading user: \(error)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            let user = UserProfile(
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
            completion(user)
        }
    }
    
    /// Load user profile by email (queries by email field)
    func loadUserProfileByEmail(email: String, completion: @escaping (UserProfile?) -> Void) {
        let db = Firestore.firestore()
        db.collection(usersCollection).whereField("email", isEqualTo: email).limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading user by email: \(error)")
                completion(nil)
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("⚠️ No user found for email: \(email)")
                completion(nil)
                return
            }
            
            let data = document.data()
            let user = UserProfile(
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
            print("✅ Loaded user for email: \(email)")
            completion(user)
        }
    }
    
    /// Find a complete user profile (one that has an associated company) by email
    /// This handles the case where multiple user profiles exist for the same email
    func findCompleteUserProfile(email: String, completion: @escaping ((UserProfile, CompanyProfile)?) -> Void) {
        let db = Firestore.firestore()
        
        // Get ALL users with this email (not just the first)
        db.collection(usersCollection).whereField("email", isEqualTo: email).getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error searching users by email: \(error)")
                completion(nil)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("⚠️ No users found for email: \(email)")
                completion(nil)
                return
            }
            
            print("ℹ️ Found \(documents.count) user(s) for email: \(email)")
            
            // Try each user to find one with a company
            self?.findUserWithCompany(documents: documents, index: 0, completion: completion)
        }
    }
    
    /// Recursively check each user document to find one with an associated company
    private func findUserWithCompany(documents: [QueryDocumentSnapshot], index: Int, completion: @escaping ((UserProfile, CompanyProfile)?) -> Void) {
        guard index < documents.count else {
            print("⚠️ No user with company found in \(documents.count) profiles")
            completion(nil)
            return
        }
        
        let data = documents[index].data()
        let userId = data["id"] as? String ?? ""
        
        let user = UserProfile(
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
        
        // Check if this user has a company
        loadCompanyProfileByUserId(userId: userId) { [weak self] company in
            if let company = company {
                print("✅ Found complete profile (user + company) for userId: \(userId)")
                completion((user, company))
            } else {
                // Try next user
                self?.findUserWithCompany(documents: documents, index: index + 1, completion: completion)
            }
        }
    }
    
    /// Load company profile from Firestore
    func loadCompanyProfile(companyId: String, completion: @escaping (CompanyProfile?) -> Void) {
        let db = Firestore.firestore()
        db.collection(companiesCollection).document(companyId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error loading company: \(error)")
                completion(nil)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil)
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
            completion(company)
        }
    }
    
    /// Load company profile by user ID (queries by userId field)
    func loadCompanyProfileByUserId(userId: String, completion: @escaping (CompanyProfile?) -> Void) {
        let db = Firestore.firestore()
        db.collection(companiesCollection).whereField("userId", isEqualTo: userId).limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading company by userId: \(error)")
                completion(nil)
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("⚠️ No company found for userId: \(userId)")
                completion(nil)
                return
            }
            
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
            print("✅ Loaded company for userId: \(userId)")
            completion(company)
        }
    }
    
    /// Fetch all users (for admin dashboard or debugging)
    func fetchAllUsers(completion: @escaping ([UserProfile]) -> Void) {
        let db = Firestore.firestore()
        db.collection(usersCollection).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching users: \(error)")
                completion([])
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
            
            completion(users)
        }
    }
    // MARK: - Storage
    
    /// Upload image to Firebase Storage and return download URL
    func uploadImage(image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Error getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"])))
                    return
                }
                
                print("✅ Image uploaded successfully: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    /// Delete a file from Firebase Storage
    func deleteStorageFile(path: String, completion: @escaping (Error?) -> Void) {
        Storage.storage().reference().child(path).delete { error in
            completion(error)
        }
    }
    
    // MARK: - Account Deletion
    
    /// Delete all user data from Firestore (user profile and company profile)
    /// Uses email to find documents reliably regardless of document ID
    func deleteUserData(email: String, userId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        var deletionError: Error?
        var foundUserId: String? = nil
        
        // Step 1: Find and delete user profile by email
        dispatchGroup.enter()
        db.collection(usersCollection).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error finding user profile: \(error.localizedDescription)")
                deletionError = error
                dispatchGroup.leave()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("ℹ️ No user profile found for email: \(email)")
                dispatchGroup.leave()
                return
            }
            
            // Delete all matching user documents
            let deleteGroup = DispatchGroup()
            for doc in documents {
                deleteGroup.enter()
                // Capture userId from the document for company lookup
                if let docUserId = doc.data()["id"] as? String {
                    foundUserId = docUserId
                }
                doc.reference.delete { error in
                    if let error = error {
                        print("❌ Error deleting user profile: \(error.localizedDescription)")
                        deletionError = error
                    } else {
                        print("✅ User profile deleted from Firestore: \(doc.documentID)")
                    }
                    deleteGroup.leave()
                }
            }
            deleteGroup.notify(queue: .main) {
                dispatchGroup.leave()
            }
        }
        
        // Wait for user deletion to get foundUserId, then delete company
        dispatchGroup.notify(queue: .main) {
            let companyGroup = DispatchGroup()
            
            // Delete company profile by userId (try both the passed userId and foundUserId)
            let userIdsToCheck = [userId, foundUserId].compactMap { $0 }
            
            for uid in userIdsToCheck {
                companyGroup.enter()
                db.collection(self.companiesCollection).whereField("userId", isEqualTo: uid).getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Error finding company profile: \(error.localizedDescription)")
                        deletionError = error
                        companyGroup.leave()
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("ℹ️ No company profile found for userId: \(uid)")
                        companyGroup.leave()
                        return
                    }
                    
                    for doc in documents {
                        doc.reference.delete { error in
                            if let error = error {
                                print("❌ Error deleting company profile: \(error.localizedDescription)")
                                deletionError = error
                            } else {
                                print("✅ Company profile deleted from Firestore: \(doc.documentID)")
                            }
                        }
                    }
                    companyGroup.leave()
                }
            }
            
            // Delete profile image from Storage
            companyGroup.enter()
            let imagePath = "profile_images/\(userId).jpg"
            Storage.storage().reference().child(imagePath).delete { error in
                if let error = error {
                    print("ℹ️ Profile image deletion: \(error.localizedDescription)")
                } else {
                    print("✅ Profile image deleted from Storage")
                }
                companyGroup.leave()
            }
            
            companyGroup.notify(queue: .main) {
                completion(deletionError)
            }
        }
    }
    
    /// Change user email via Firebase Auth's verifyBeforeUpdateEmail flow.
    /// First checks Firestore for duplicate emails, then re-authenticates, then sends verification.
    func changeUserEmail(newEmail: String, password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        let db = Firestore.firestore()
        
        // Step 1: Check if the new email already exists in our Firestore users collection
        db.collection(usersCollection).whereField("email", isEqualTo: newEmail).limit(to: 1).getDocuments { snapshot, error in
            if let docs = snapshot?.documents, !docs.isEmpty {
                // Email already exists in our database
                print("❌ Email \(newEmail) already in use by another account")
                completion(NSError(domain: "AppError", code: 17007, userInfo: [NSLocalizedDescriptionKey: "EMAIL_ALREADY_IN_USE"]))
                return
            }
            
            // Step 2: Re-authenticate if needed, then send verification
            let providers = user.providerData.map { $0.providerID }
            let isGoogleUser = providers.contains("google.com")
            
            let sendVerification = {
                user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
                    if let error = error {
                        print("❌ Error sending email change verification: \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("✅ Verification email sent to \(newEmail)")
                        completion(nil)
                    }
                }
            }
            
            if isGoogleUser {
                sendVerification()
            } else if let password = password, let email = user.email {
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.reauthenticate(with: credential) { result, error in
                    if let error = error {
                        print("❌ Re-authentication failed: \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    sendVerification()
                }
            } else {
                completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required for email/password accounts"]))
            }
        }
    }
    
    /// Re-authenticate with email/password and delete Firebase Auth account
    func deleteAuthAccount(password: String?, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        // Check provider type
        let providers = user.providerData.map { $0.providerID }
        let isGoogleUser = providers.contains("google.com")
        
        if isGoogleUser {
            // For Google users, we need to re-authenticate with Google credential
            // This will be handled by AppViewModel which has access to GIDSignIn
            user.delete { error in
                if let error = error {
                    print("❌ Error deleting auth account: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("✅ Firebase Auth account deleted")
                    completion(nil)
                }
            }
        } else if let password = password, let email = user.email {
            // For email/password users, re-authenticate first
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { result, error in
                if let error = error {
                    print("❌ Re-authentication failed: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                user.delete { error in
                    if let error = error {
                        print("❌ Error deleting auth account: \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("✅ Firebase Auth account deleted")
                        completion(nil)
                    }
                }
            }
        } else {
            completion(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required for email/password accounts"]))
        }
    }
    


}
