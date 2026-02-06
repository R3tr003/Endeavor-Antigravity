import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

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
            "timeZone": user.timeZone
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
            "shortDescription": company.shortDescription,
            "longDescription": company.longDescription
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
                timeZone: data["timeZone"] as? String ?? ""
            )
            completion(user)
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
                shortDescription: data["shortDescription"] as? String ?? "",
                longDescription: data["longDescription"] as? String ?? ""
            )
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
                    timeZone: data["timeZone"] as? String ?? ""
                )
            } ?? []
            
            completion(users)
        }
    }
}
