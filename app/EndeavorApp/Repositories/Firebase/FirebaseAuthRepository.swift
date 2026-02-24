import Foundation
import FirebaseAuth

class FirebaseAuthRepository: AuthRepositoryProtocol {
    
    init() {}
    
    func signIn(email: String, password: String, completion: @escaping (Result<(User, String), Error>) -> Void) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        Auth.auth().signIn(withEmail: normalizedEmail, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let user = result?.user {
                completion(.success((user, normalizedEmail)))
            }
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<(User, String), Error>) -> Void) {
         let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
         Auth.auth().createUser(withEmail: normalizedEmail, password: password) { result, error in
             if let error = error {
                 completion(.failure(error))
                 return
             }
             if let user = result?.user {
                 completion(.success((user, normalizedEmail)))
             }
         }
     }
     
     func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
         let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
         Auth.auth().sendPasswordReset(withEmail: normalizedEmail) { error in
             if let error = error {
                 print("❌ Error sending password reset: \(error.localizedDescription)")
             } else {
                 print("✅ Password reset email sent to \(normalizedEmail)")
             }
             completion(error)
         }
     }
     
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
     
     func signOut() throws {
         try Auth.auth().signOut()
     }
     
     var isUserAuthenticated: Bool {
         return Auth.auth().currentUser != nil
     }
     
     var currentUserId: String? {
         return Auth.auth().currentUser?.uid
     }
}
