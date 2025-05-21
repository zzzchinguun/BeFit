//
//  AuthViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/26/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Published user session
    @Published var userSession: FirebaseAuth.User?
    
    /// Published current user
    @Published var currentUser: User?
    
    /// Auth service reference
    private let authService: AuthServiceProtocol
    
    /// Cancellables set to store subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(authService: AuthServiceProtocol = ServiceContainer.shared.authService) {
        self.authService = authService
        
        // Set initial user session
        self.userSession = Auth.auth().currentUser
        
        // Subscribe to current user changes
        setupSubscriptions()
        
        Task {
            await authService.fetchUser()
        }
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to current user changes from the auth service
        authService.currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    func signIn(withEmail email: String, password: String) async throws {
        do {
            try await authService.signIn(email: email, password: password)
            self.userSession = Auth.auth().currentUser
        } catch {
            // Force reset userSession to nil to ensure UI updates properly
            self.userSession = nil
            
            // Ensure UI updates by posting a notification
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: nil)
            
            // Log the error
            print("DEBUG log in failed with error: \(error.localizedDescription)")
            
            // Also post to our custom authentication failed notification
            // First post on the main thread for immediate UI update
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("authenticationFailed"), object: error)
            }
            
            // Rethrow the error to be handled by the caller
            throw error
        }
    }
    
    /// Create a new user
    func createUser(withEmail email: String, password: String, firstName: String, lastName: String) async throws {
        do {
            try await authService.createUser(email: email, password: password, firstName: firstName, lastName: lastName)
            self.userSession = Auth.auth().currentUser
        } catch {
            print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update user fitness data
    func updateUserFitnessData(age: Int?, weight: Double?, height: Double?,
                             sex: String?, activityLevel: String?,
                             bodyFatPercentage: Double?, goalWeight: Double?,
                             daysToComplete: Int?, goal: String?,
                             tdee: Double?, macros: Macros?) async throws {
        // Create dictionary of updates
        var userData: [String: Any] = [:]
        
        if let age = age { userData["age"] = age }
        if let weight = weight { userData["weight"] = weight }
        if let height = height { userData["height"] = height }
        if let sex = sex { userData["sex"] = sex }
        if let activityLevel = activityLevel { userData["activityLevel"] = activityLevel }
        if let bodyFatPercentage = bodyFatPercentage { userData["bodyFatPercentage"] = bodyFatPercentage }
        if let goalWeight = goalWeight { userData["goalWeight"] = goalWeight }
        if let daysToComplete = daysToComplete { userData["daysToComplete"] = daysToComplete }
        if let goal = goal { userData["goal"] = goal }
        if let tdee = tdee { userData["tdee"] = tdee }
        if let macros = macros {
            userData["macros"] = [
                "protein": macros.protein,
                "carbs": macros.carbs,
                "fat": macros.fat
            ]
        }
        
        do {
            try await authService.updateUserFitnessData(userData: userData)
        } catch {
            print("DEBUG: Failed to update user data with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Reset password
    func resetPassword(withEmail email: String) async throws {
        do {
            try await authService.resetPassword(email: email)
        } catch {
            print("DEBUG: Failed to reset password with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign out
    func signOut() {
        do {
            try authService.signOut()
            self.userSession = nil
        } catch {
            print("DEBUG: Failed to sign out with error: \(error.localizedDescription)")
        }
    }
    
    /// Delete account
    func deleteAccount() async throws {
        do {
            try await authService.deleteAccount()
            self.userSession = nil
        } catch {
            print("DEBUG: Failed to delete account with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Set up test user
    func setupTestUser() {
        authService.setupTestUser()
    }
}
