//
//  UnverifiedMeal.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import FirebaseFirestore

struct UnverifiedMeal: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let createdByEmail: String // Store user email for admin reference
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Double?
    let sugar: Double?
    let servingSizeGrams: Double?
    let servingDescription: String?
    let category: FoodCategory
    let imageURL: String?
    let barcode: String?
    let dateCreated: Date
    let isVerified: Bool
    let verifiedBy: String? // Admin user ID who verified
    let verificationDate: Date?
    
    init(
        id: String? = nil,
        userId: String,
        createdByEmail: String,
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        fiber: Double? = nil,
        sugar: Double? = nil,
        servingSizeGrams: Double? = nil,
        servingDescription: String? = nil,
        category: FoodCategory = .custom,
        imageURL: String? = nil,
        barcode: String? = nil,
        dateCreated: Date = Date(),
        isVerified: Bool = false,
        verifiedBy: String? = nil,
        verificationDate: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.createdByEmail = createdByEmail
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.servingSizeGrams = servingSizeGrams
        self.servingDescription = servingDescription
        self.category = category
        self.imageURL = imageURL
        self.barcode = barcode
        self.dateCreated = dateCreated
        self.isVerified = isVerified
        self.verifiedBy = verifiedBy
        self.verificationDate = verificationDate
    }
}

// Extension for converting to NutritionData for verified meals
extension UnverifiedMeal {
    func toNutritionData(newId: String? = nil) -> NutritionData {
        return NutritionData(
            id: newId ?? (id ?? UUID().uuidString),
            name: name,
            category: category,
            calories: Double(calories),
            protein: Double(protein),
            carbs: Double(carbs),
            fat: Double(fat),
            fiber: fiber ?? 0.0,
            sugar: sugar ?? 0.0,
            servingSizeGrams: servingSizeGrams ?? 100.0,
            servingDescription: servingDescription ?? "100g",
            imageURL: imageURL,
            barcode: barcode,
            creatorUserId: userId,
            createdByEmail: createdByEmail
        )
    }
}

// Extension for mock data
extension UnverifiedMeal {
    static var MOCK_UNVERIFIED_MEALS: [UnverifiedMeal] = [
        UnverifiedMeal(
            id: NSUUID().uuidString,
            userId: "user123",
            createdByEmail: "user@example.com",
            name: "Homemade Buuz",
            calories: 250,
            protein: 15,
            carbs: 20,
            fat: 12,
            fiber: 2.0,
            sugar: 1.0,
            servingSizeGrams: 100.0,
            servingDescription: "5 pieces (100g)",
            category: .custom
        ),
        UnverifiedMeal(
            id: NSUUID().uuidString,
            userId: "user456",
            createdByEmail: "another@example.com",
            name: "Traditional Borts",
            calories: 320,
            protein: 25,
            carbs: 8,
            fat: 22,
            fiber: 0.5,
            sugar: 0.2,
            servingSizeGrams: 100.0,
            servingDescription: "100g dried meat",
            category: .meat
        )
    ]
} 