import Foundation

protocol UserRepositoryProtocol {
    /// Fetches a single user profile completely.
    func fetchUserProfile(userId: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    
    /// Fetches a company profile completely.
    func fetchCompanyProfile(companyId: String, completion: @escaping (Result<CompanyProfile, Error>) -> Void)
    
    /// Tries to find both the User Profile and their Company by email.
    func findCompleteUserProfile(email: String, completion: @escaping (Result<(UserProfile, CompanyProfile), Error>) -> Void)
    
    /// Persists a UserProfile.
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void)
    
    /// Persists a CompanyProfile.
    func saveCompanyProfile(_ profile: CompanyProfile, userId: String, completion: @escaping (Error?) -> Void)
    
    /// Changes the user's registered email using re-authentication if necessary.
    func changeUserEmail(newEmail: String, password: String?, completion: @escaping (Error?) -> Void)
    
    /// Deletes the authentication account entirely.
    func deleteAuthAccount(password: String?, completion: @escaping (Error?) -> Void)
    
    /// Removes the user's and company's data from the database.
    func deleteUserData(email: String, userId: String, completion: @escaping (Error?) -> Void)
}
