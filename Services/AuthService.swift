//
//  AuthService.swift
//  BeFit
//
//  Created by AI Assistant on 5/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Protocol defining authentication service capabilities
protocol AuthServiceProtocol {
    var currentUser: CurrentValueSubject<User?, Never> { get }
    
    func signIn(email: String, password: String) async throws
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws
    func signOut() throws
    func resetPassword(email: String) async throws
    func deleteAccount() async throws
    func updateUserFitnessData(userData: [String: Any]) async throws
    func fetchUser() async
    func setupTestUser()
}

/// Service for handling authentication operations
class AuthService: FirebaseService, AuthServiceProtocol {
    // MARK: - Properties
    
    /// Current user published property that can be observed
    let currentUser = CurrentValueSubject<User?, Never>(nil)
    
    /// FirebaseAuth user session
    var userSession: FirebaseAuth.User? {
        didSet {
            if userSession == nil {
                currentUser.send(nil)
            }
        }
    }
    
    // MARK: - Init
    
    override init() {
        self.userSession = Auth.auth().currentUser
        super.init()
        
        Task {
            await fetchUser()
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Signs in a user with email and password
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            throw handleError(error)
        }
    }
    
    /// Creates a new user account
    func createUser(email: String, password: String, firstName: String, lastName: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let user = User(id: result.user.uid, firstName: firstName, lastName: lastName, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await db.collection("users").document(user.id).setData(encodedUser)
            
            // Ensure onboarding is required for new users
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            await fetchUser()
        } catch {
            throw handleError(error)
        }
    }
    
    /// Signs out the current user
    func signOut() throws {
        do {
            try auth.signOut()
            self.userSession = nil
            
            // Reset all user-related UserDefaults when signing out
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            // Explicitly set to false to ensure new users go through onboarding
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            // Notify about user session change
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: nil)
        } catch {
            throw handleError(error)
        }
    }
    
    /// Sends a password reset email
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw handleError(error)
        }
    }
    
    /// Deletes the current user account and related data
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw FirebaseError.authError("No user is currently signed in")
        }
        
        do {
            // Delete user data from Firestore
            try await db.collection("users").document(user.uid).delete()
            
            // Delete the user account from Firebase Auth
            try await user.delete()
            
            // Clear local user session
            self.userSession = nil
        } catch {
            throw handleError(error)
        }
    }
    
    /// Updates user fitness data
    func updateUserFitnessData(userData: [String: Any]) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw FirebaseError.authError("No user is currently signed in")
        }
        
        do {
            // Get current user document
            let userRef = db.collection("users").document(uid)
            try await userRef.updateData(userData)
            
            // Fetch updated user data
            await fetchUser()
            
            // Set onboarding completion flag
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        } catch {
            throw handleError(error)
        }
    }
    
    /// Fetches the current user's data from Firestore
    func fetchUser() async {
        guard let uid = auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let user = try? snapshot.data(as: User.self) {
                currentUser.send(user)
                
                // Notify about user change
                NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: user)
            }
        } catch {
            print("DEBUG: Failed to fetch user with error: \(error.localizedDescription)")
        }
    }
    
    /// Sets up a test user for development purposes
    func setupTestUser() {
        #if DEBUG
        if currentUser.value == nil {
            currentUser.send(User.MOCK_USER)
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: User.MOCK_USER)
        }
        #endif
    }
} 