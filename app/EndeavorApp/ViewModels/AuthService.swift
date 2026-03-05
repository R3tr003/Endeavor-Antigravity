import Foundation
import Combine
import FirebaseAuth
import GoogleSignIn
import UIKit

class AuthService: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isCheckingAuth: Bool = false
    @Published var failedLoginAttempts: Int = 0
    @Published var passwordResetSent: Bool = false
    @Published var emailCollisionDetected: Bool = false
    
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol = FirebaseAuthRepository()) {
        self.authRepository = authRepository
    }
    
    // We use a completion handler to communicate back to the Facade (AppViewModel)
    // so it can trigger the UserRepository's fetch logic.
    typealias AuthResultHandler = (Result<(user: FirebaseAuth.User, email: String, isNewUser: Bool), Error>) -> Void
    
    func login(email: String, password: String, completion: @escaping AuthResultHandler) {
        authRepository.signIn(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.failedLoginAttempts = 0
                    completion(.success((data.0, email, false)))
                case .failure(let error):
                    let nsError = error as NSError
                    // 17011 = user not found (new user path)
                    // 17004 = rimuovilo: è wrong password, va gestito come errore normale
                    if nsError.code != 17011 {
                        self?.failedLoginAttempts += 1
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    


    func signUpNewUser(email: String, password: String, completion: @escaping AuthResultHandler) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        authRepository.signUp(email: normalizedEmail, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    completion(.success((data.0, email.trimmingCharacters(in: .whitespacesAndNewlines), true)))
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.code == 17007 {
                        self?.emailCollisionDetected = true
                    }
                    completion(.failure(error))
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty else { return }
        
        authRepository.resetPassword(email: normalizedEmail) { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.passwordResetSent = true
                }
                completion(error)
            }
        }
    }
    
    func startGoogleSignIn(completion: @escaping (Result<(idToken: String, accessToken: String, email: String, firstName: String, lastName: String, photoUrl: String), Error>) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not start Google Sign In"])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Google User Data"])))
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let email = user.profile?.email ?? ""
            let firstName = user.profile?.givenName ?? ""
            let lastName = user.profile?.familyName ?? ""
            // Request high-resolution avatar (256px)
            let photoUrl = user.profile?.imageURL(withDimension: 256)?.absoluteString ?? ""
            completion(.success((idToken, accessToken, email, firstName, lastName, photoUrl)))
        }
    }
    
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping AuthResultHandler) {
        authRepository.signInWithGoogle(idToken: idToken, accessToken: accessToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    completion(.success((user, user.email ?? "", false))) // Social logins are treated structurally similar
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
    }
}
