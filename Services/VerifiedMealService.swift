//
//  VerifiedMealService.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import FirebaseFirestore
import Combine

/// Protocol defining verified meal service capabilities
protocol VerifiedMealServiceProtocol {
    var verifiedMeals: CurrentValueSubject<[NutritionData], Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var errorMessage: CurrentValueSubject<String?, Never> { get }
    
    func fetchVerifiedMeals() async
    func getVerifiedMealById(_ id: String) -> NutritionData?
}

/// Service for handling verified meals that are available to all users
class VerifiedMealService: FirebaseService, VerifiedMealServiceProtocol {
    // MARK: - Properties
    
    let verifiedMeals = CurrentValueSubject<[NutritionData], Never>([])
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = CurrentValueSubject<String?, Never>(nil)
    
    // MARK: - Public Methods
    
    /// Fetch all verified meals available to all users
    func fetchVerifiedMeals() async {
        isLoading.send(true)
        
        do {
            let querySnapshot = try await db.collection("verifiedmeals")
                .order(by: "verificationDate", descending: true)
                .getDocuments()
            
            let fetchedMeals = querySnapshot.documents.compactMap { document -> NutritionData? in
                let data = document.data()
                
                // Convert Firebase document to NutritionData
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let categoryString = data["category"] as? String,
                      let category = FoodCategory(rawValue: categoryString),
                      let calories = data["calories"] as? Double,
                      let protein = data["protein"] as? Double,
                      let carbs = data["carbs"] as? Double,
                      let fat = data["fat"] as? Double else {
                    return nil
                }
                
                let fiber = data["fiber"] as? Double ?? 0.0
                let sugar = data["sugar"] as? Double ?? 0.0
                let servingSizeGrams = data["servingSizeGrams"] as? Double ?? 100.0
                let servingDescription = data["servingDescription"] as? String ?? "100g"
                let imageURL = data["imageURL"] as? String
                let barcode = data["barcode"] as? String
                
                // Extract creator information
                let creatorUserId = data["originalCreatorId"] as? String
                let createdByEmail = data["originalCreatorEmail"] as? String
                
                return NutritionData(
                    id: id,
                    name: name,
                    category: category,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber,
                    sugar: sugar,
                    servingSizeGrams: servingSizeGrams,
                    servingDescription: servingDescription,
                    imageURL: imageURL,
                    barcode: barcode,
                    creatorUserId: creatorUserId,
                    createdByEmail: createdByEmail
                )
            }
            
            verifiedMeals.send(fetchedMeals)
            isLoading.send(false)
            
        } catch {
            isLoading.send(false)
            let message = handleError(error).localizedDescription
            errorMessage.send(message)
        }
    }
    
    /// Get a verified meal by its ID
    func getVerifiedMealById(_ id: String) -> NutritionData? {
        return verifiedMeals.value.first { $0.id == id }
    }
}

// Factory extension for creating instances
extension VerifiedMealService {
    static let shared = VerifiedMealService()
} 