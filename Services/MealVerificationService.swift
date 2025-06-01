//
//  MealVerificationService.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Protocol defining meal verification service capabilities
protocol MealVerificationServiceProtocol {
    var unverifiedMeals: CurrentValueSubject<[UnverifiedMeal], Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var errorMessage: CurrentValueSubject<String?, Never> { get }
    
    func fetchUnverifiedMeals() async
    func fetchUserUnverifiedMeals(userId: String) async throws -> [UnverifiedMeal]
    func addUnverifiedMeal(_ meal: UnverifiedMeal) async throws
    func verifyMeal(_ meal: UnverifiedMeal) async throws
    func rejectMeal(_ meal: UnverifiedMeal, reason: String?) async throws
    func isUserSuperAdmin(_ user: User) -> Bool
}

/// Service for handling meal verification operations
class MealVerificationService: FirebaseService, MealVerificationServiceProtocol {
    // MARK: - Properties
    
    let unverifiedMeals = CurrentValueSubject<[UnverifiedMeal], Never>([])
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = CurrentValueSubject<String?, Never>(nil)
    
    // Super admin identifiers
    private let superAdminEmails = ["sharshuwuu@gmail.com"]
    private let superAdminUserIds = ["SDAYsF2tGIUAprisnFxLwvM52Fm2"]
    
    // MARK: - Public Methods
    
    /// Check if a user is a super admin
    func isUserSuperAdmin(_ user: User) -> Bool {
        return superAdminEmails.contains(user.email) || superAdminUserIds.contains(user.id)
    }
    
    /// Fetch all unverified meals (only for super admins)
    func fetchUnverifiedMeals() async {
        guard let currentUserId = getCurrentUserId() else {
            errorMessage.send("No user is currently signed in")
            return
        }
        
        // Check if current user is super admin
        // We'll need to verify this on the server side too
        isLoading.send(true)
        
        do {
            let querySnapshot = try await db.collection("unverifiedmeals")
                .whereField("isVerified", isEqualTo: false)
                .order(by: "dateCreated", descending: true)
                .getDocuments()
            
            let fetchedMeals = querySnapshot.documents.compactMap { document in
                try? document.data(as: UnverifiedMeal.self)
            }
            
            unverifiedMeals.send(fetchedMeals)
            isLoading.send(false)
        } catch {
            isLoading.send(false)
            let message = handleError(error).localizedDescription
            errorMessage.send(message)
        }
    }
    
    /// Fetch user's own unverified meals
    func fetchUserUnverifiedMeals(userId: String) async throws -> [UnverifiedMeal] {
        let querySnapshot = try await db.collection("unverifiedmeals")
            .whereField("userId", isEqualTo: userId)
            .whereField("isVerified", isEqualTo: false)
            .order(by: "dateCreated", descending: true)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: UnverifiedMeal.self)
        }
    }
    
    /// Add a new unverified meal when user creates custom food
    func addUnverifiedMeal(_ meal: UnverifiedMeal) async throws {
        do {
            let docRef = try await db.collection("unverifiedmeals").addDocument(data: try Firestore.Encoder().encode(meal))
            
            // Optimistically update local data
            var currentMeals = unverifiedMeals.value
            var newMealWithId = meal
            newMealWithId.id = docRef.documentID
            currentMeals.insert(newMealWithId, at: 0)
            unverifiedMeals.send(currentMeals)
            
        } catch {
            throw handleError(error)
        }
    }
    
    /// Verify a meal and move it to verified meals collection
    func verifyMeal(_ meal: UnverifiedMeal) async throws {
        guard let mealId = meal.id else {
            throw FirebaseError.databaseError("Meal does not have a valid ID")
        }
        
        guard let currentUserId = getCurrentUserId() else {
            throw FirebaseError.authError("No user is currently signed in")
        }
        
        do {
            // Create verified meal data for the verifiedmeals collection
            let verifiedMealData: [String: Any] = [
                "id": mealId,
                "name": meal.name,
                "category": meal.category.rawValue,
                "calories": Double(meal.calories),
                "protein": Double(meal.protein),
                "carbs": Double(meal.carbs),
                "fat": Double(meal.fat),
                "fiber": meal.fiber ?? 0.0,
                "sugar": meal.sugar ?? 0.0,
                "servingSizeGrams": meal.servingSizeGrams ?? 100.0,
                "servingDescription": meal.servingDescription ?? "100g",
                "imageURL": meal.imageURL as Any,
                "barcode": meal.barcode as Any,
                "originalCreatorId": meal.userId,
                "originalCreatorEmail": meal.createdByEmail,
                "verifiedBy": currentUserId,
                "verificationDate": Date(),
                "dateCreated": meal.dateCreated
            ]
            
            // Add to verified meals collection
            try await db.collection("verifiedmeals").document(mealId).setData(verifiedMealData)
            
            // Update the unverified meal to mark as verified
            try await db.collection("unverifiedmeals").document(mealId).updateData([
                "isVerified": true,
                "verifiedBy": currentUserId,
                "verificationDate": Date()
            ])
            
            // Remove from local unverified meals list
            var currentMeals = unverifiedMeals.value
            currentMeals.removeAll { $0.id == mealId }
            unverifiedMeals.send(currentMeals)
            
        } catch {
            throw handleError(error)
        }
    }
    
    /// Reject a meal (mark as rejected)
    func rejectMeal(_ meal: UnverifiedMeal, reason: String? = nil) async throws {
        guard let mealId = meal.id else {
            throw FirebaseError.databaseError("Meal does not have a valid ID")
        }
        
        guard let currentUserId = getCurrentUserId() else {
            throw FirebaseError.authError("No user is currently signed in")
        }
        
        do {
            // Update the meal with rejection data
            var updateData: [String: Any] = [
                "isVerified": false,
                "rejectedBy": currentUserId,
                "rejectionDate": Date(),
                "rejectionReason": reason as Any
            ]
            
            try await db.collection("unverifiedmeals").document(mealId).updateData(updateData)
            
            // Remove from local unverified meals list
            var currentMeals = unverifiedMeals.value
            currentMeals.removeAll { $0.id == mealId }
            unverifiedMeals.send(currentMeals)
            
        } catch {
            throw handleError(error)
        }
    }
}

// Factory extension for creating instances
extension MealVerificationService {
    static let shared = MealVerificationService()
} 