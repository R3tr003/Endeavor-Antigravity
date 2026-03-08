import Foundation

protocol UserRepositoryProtocol {
    /// Fetches a single user profile completely.
    func fetchUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    
    /// Fetches a company profile completely.
    func fetchCompanyProfile(companyId: String, completion: @escaping (Result<CompanyProfile, Error>) -> Void)
    
    /// Tries to find both the User Profile and their Company by email.
    func findCompleteUserProfile(email: String, completion: @escaping (Result<(UserProfile, CompanyProfile), Error>) -> Void)
    
    /// Looks for any existing users doc by email (regardless of whether a company exists).
    /// Returns the UUID stored in that doc, or nil if none found.
    func findAnyUserDoc(email: String, completion: @escaping (UUID?) -> Void)
    
    /// Fetches a partial user profile by email: returns the user doc data (if found) and
    /// optionally the associated company doc. Unlike `findCompleteUserProfile`, this does
    /// NOT fail if the company doc is missing.
    func findPartialUserProfile(email: String, completion: @escaping (UserProfile?, CompanyProfile?) -> Void)
    
    /// Persists a UserProfile.
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void)
    
    /// Persists a CompanyProfile.
    func saveCompanyProfile(_ profile: CompanyProfile, userId: String, completion: @escaping (Error?) -> Void)
    
    /// Atomically saves both user and company profiles in a single batch write.
    func saveUserAndCompany(user: UserProfile, company: CompanyProfile, completion: @escaping (Error?) -> Void)
    
    /// Changes the user's registered email using re-authentication if necessary.
    func changeUserEmail(newEmail: String, password: String?, completion: @escaping (Error?) -> Void)

    /// Re-authenticates the current user. Must be called BEFORE sensitive operations like account deletion.
    func reauthenticateUser(password: String?, completion: @escaping (Error?) -> Void)

    /// Deletes the authentication account entirely. Call reauthenticateUser first.
    func deleteAuthAccount(completion: @escaping (Error?) -> Void)

    /// Removes the user's and company's data from the database.
    func deleteUserData(email: String, userId: String, firebaseUid: String?, completion: @escaping (Error?) -> Void)
}
