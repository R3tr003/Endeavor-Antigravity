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
                    self?.failedLoginAttempts += 1
                    completion(.failure(error))
                }
            }
        }
    }
    
    func authenticate(email: String, password: String, completion: @escaping AuthResultHandler) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.emailCollisionDetected = false
        
        authRepository.signIn(email: normalizedEmail, password: password) { [weak self] result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self?.failedLoginAttempts = 0
                    completion(.success((data.0, email.trimmingCharacters(in: .whitespacesAndNewlines), false)))
                }
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == 17011 || (nsError.code == 17004 && !nsError.localizedDescription.contains("format")) {
                    // User not found -> Try Sign Up
                    self?.authRepository.signUp(email: normalizedEmail, password: password) { signUpResult in
                        DispatchQueue.main.async {
                            switch signUpResult {
                            case .success(let newUserData):
                                completion(.success((newUserData.0, email.trimmingCharacters(in: .whitespacesAndNewlines), true)))
                            case .failure(let signUpError):
                                self?.failedLoginAttempts += 1
                                completion(.failure(signUpError))
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.failedLoginAttempts += 1
                        completion(.failure(error))
                    }
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
    
    func startGoogleSignIn(completion: @escaping AuthResultHandler) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(.failure(NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not start Google Sign In"])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
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
            self?.signInWithGoogle(idToken: idToken, accessToken: accessToken, completion: completion)
        }
    }
    
    private func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping AuthResultHandler) {
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
