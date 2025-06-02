//
//  AuthService.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
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
        // Clear userSession first to ensure a clean slate
        self.userSession = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            // Before setting userSession, verify that user data exists in Firestore
            let userRef = db.collection("users").document(result.user.uid)
            let snapshot = try await userRef.getDocument()
            
            guard snapshot.exists, let _ = try? snapshot.data(as: User.self) else {
                // User record doesn't exist in Firestore - this is a deleted account
                print("DEBUG: Account exists in Auth but not in Firestore - likely deleted")
                
                // Sign out from Firebase Auth
                try? await auth.currentUser?.delete()
                try? auth.signOut()
                
                // Ensure local state is cleaned up
                self.userSession = nil
                self.currentUser.send(nil)
                
                // Post notification to trigger UI updates
                NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: nil)
                
                throw FirebaseError.authError("Account not found or has been deleted")
            }
            
            // User exists, proceed with sign-in
            self.userSession = result.user
            
            // Don't reset language or theme preferences that the user has set
            let defaults = UserDefaults.standard
            let isEnglishLanguage = defaults.bool(forKey: "isEnglishLanguage")
            let isDarkMode = defaults.bool(forKey: "isDarkMode")
            
            // Fetch user data before setting any defaults
            await fetchUser()
            
            // Restore user preferences after login
            defaults.set(isEnglishLanguage, forKey: "isEnglishLanguage")
            defaults.set(isDarkMode, forKey: "isDarkMode")
        } catch let error as NSError {
            // Ensure userSession is nil on any error
            self.userSession = nil
            
            await MainActor.run {
                self.currentUser.send(nil)
            }
            
            // Process error more specifically
            let firebaseError: FirebaseError
            
            if error.domain == AuthErrorDomain {
                // Handle specific Firebase Auth errors
                switch error.code {
                case AuthErrorCode.userNotFound.rawValue:
                    firebaseError = FirebaseError.authError("No user found with that email")
                case AuthErrorCode.wrongPassword.rawValue:
                    firebaseError = FirebaseError.authError("Wrong password")
                case AuthErrorCode.userDisabled.rawValue:
                    firebaseError = FirebaseError.authError("This account has been disabled")
                case AuthErrorCode.invalidEmail.rawValue:
                    firebaseError = FirebaseError.authError("Invalid email format")
                case AuthErrorCode.networkError.rawValue:
                    firebaseError = FirebaseError.networkError("Network connection issue")
                default:
                    firebaseError = FirebaseError.authError(error.localizedDescription)
                }
            } else {
                firebaseError = handleError(error)
            }
            
            // Notify about authentication failure with specific error
            NotificationCenter.default.post(name: Notification.Name("authenticationFailed"), object: firebaseError)
            
            // Throw the specific error
            throw firebaseError
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
            
            // Reset all user-related UserDefaults when signing out
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            
            // Explicitly set to false to ensure new users go through onboarding
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            // Notify about user session change - this ensures the UI updates properly
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: nil)
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
        guard let uid = auth.currentUser?.uid else { 
            // Clear state if no current user - ensure on main thread
            await MainActor.run {
                self.currentUser.send(nil)
            }
            return 
        }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            
            if snapshot.exists, let user = try? snapshot.data(as: User.self) {
                await MainActor.run {
                    // Check if user data actually changed before posting notification
                    let previousUser = self.currentUser.value
                    let userChanged = previousUser?.id != user.id || 
                                    previousUser?.firstName != user.firstName ||
                                    previousUser?.lastName != user.lastName ||
                                    previousUser?.email != user.email
                    
                    currentUser.send(user)
                    
                    // Only notify about user change if data actually changed
                    if userChanged {
                        print("🔵 DEBUG: User data changed, posting userSessionChanged notification")
                        NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: user)
                    } else {
                        print("🔵 DEBUG: User data unchanged, skipping userSessionChanged notification")
                    }
                }
            } else {
                // User document doesn't exist - this is an inconsistent state
                print("⚠️ User auth record exists but Firestore document is missing for \(uid)")
                
                await MainActor.run {
                    // Clear state
                    currentUser.send(nil)
                    
                    // Post notification for auth reset
                    NotificationCenter.default.post(
                        name: Notification.Name("forceAuthReset"), 
                        object: FirebaseError.authError("Account not found or has been deleted")
                    )
                }
                
                // Try to clean up Firebase Auth state
                try? await auth.currentUser?.delete()
                try? auth.signOut()
            }
        } catch {
            print("DEBUG: Failed to fetch user with error: \(error.localizedDescription)")
            
            // Clear current user on any fetch error - ensure on main thread
            await MainActor.run {
                currentUser.send(nil)
            }
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

// Factory extension for creating instances
extension AuthService {
    static let shared = AuthService()
} 