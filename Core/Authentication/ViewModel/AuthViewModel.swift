//
//  AuthViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/26/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol AuthenticationFormProtocol {
    var formIsValid: Bool { get }
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        Task{
            await fetchUser()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws{
        print("Signing in")
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            print("DEBUG log in failed with error: \(error.localizedDescription)")
        }
    }
    
    func createUser(withEmail email: String, password: String, firstName: String, lastName: String) async throws{
        print("Creating user")
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, firstName: firstName, lastName: lastName, email: email)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateUserFitnessData(age: Int?, weight: Double?, height: Double?,
                             sex: String?, activityLevel: String?,
                             bodyFatPercentage: Double?, goalWeight: Double?,
                             daysToComplete: Int?, goal: String?,
                             tdee: Double?, macros: Macros?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Create an updated user object
        var updatedUser = currentUser
        updatedUser?.age = age
        updatedUser?.weight = weight
        updatedUser?.height = height
        updatedUser?.sex = sex
        updatedUser?.activityLevel = activityLevel
        updatedUser?.bodyFatPercentage = bodyFatPercentage
        updatedUser?.goalWeight = goalWeight
        updatedUser?.daysToComplete = daysToComplete
        updatedUser?.goal = goal
        updatedUser?.tdee = tdee
        updatedUser?.macros = macros
        
        do {
            let encodedUser = try Firestore.Encoder().encode(updatedUser)
            try await Firestore.firestore().collection("users").document(uid).setData(encodedUser)
            self.currentUser = updatedUser
            // Set onboarding completion flag
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        } catch {
            print("DEBUG: Failed to update user data with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func resetPassword(withEmail email: String) async throws{
        do {
             try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            print("DEBUG: Failed to reset password with error: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
            // Reset onboarding flag when signing out
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        } catch {
            print("DEBUG: Failed to sign out with error: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        // Get a reference to Firestore
        let db = Firestore.firestore()
        
        do {
            // Delete user data from Firestore
            try await db.collection("users").document(user.uid).delete()
            
            // Delete the user account from Firebase Auth
            try await user.delete()
            
            // Clear local user session
            self.userSession = nil
            self.currentUser = nil
            
        } catch {
            print("DEBUG: Failed to delete account with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
        
        // Notify UserService about user change
        if let user = self.currentUser {
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: user)
        }
        
        print("Debug: Current user is \(self.currentUser?.email ?? "No user")")
    }
    
    // Helper method to provide a simulated user for testing
    func setupTestUser() {
        // Set a mock user when running in simulator/debug mode
        #if DEBUG
        if self.currentUser == nil {
            self.currentUser = User.MOCK_USER
            NotificationCenter.default.post(name: Notification.Name("userSessionChanged"), object: User.MOCK_USER)
        }
        #endif
    }
}
