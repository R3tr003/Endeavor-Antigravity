import Foundation
import FirebaseAuth

protocol AuthRepositoryProtocol {
    /// Attempts to sign in. Returns a tuple with the user and the cleaned email.
    func signIn(email: String, password: String, completion: @escaping (Result<(FirebaseAuth.User, String), Error>) -> Void)
    
    /// Attempts to register a new user. Returns a tuple with the new user and the cleaned email.
    func signUp(email: String, password: String, completion: @escaping (Result<(FirebaseAuth.User, String), Error>) -> Void)
    
    /// Sends a password reset email.
    func resetPassword(email: String, completion: @escaping (Error?) -> Void)
    
    /// Signs in using a Google ID Token.
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void)
    
    /// Signs the current user out.
    func signOut() throws
    
    /// Checks if a user is currently authenticated via the auth provider.
    var isUserAuthenticated: Bool { get }
    
    /// Returns the current authenticated user's ID
    var currentUserId: String? { get }
}
