import Foundation
import SwiftUI
import Combine

class NavigationRouter: ObservableObject {
    @Published var isOnboardingComplete: Bool = false
    @Published var isLoading: Bool = false
    @Published var isCheckingAuth: Bool = false  // True while checking if existing user
    @Published var appError: AppError?
    @Published var selectedTheme: String = "Dark"
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil  // System
        }
    }
    
    init() {
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Dark"
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "isOnboardingComplete")
    }
    
    func setTheme(_ theme: String) {
        self.selectedTheme = theme
        UserDefaults.standard.set(theme, forKey: "selectedTheme")
    }
    
    func clearState() {
        self.isOnboardingComplete = false
        self.appError = nil
        self.selectedTheme = "Dark"
    }
}
