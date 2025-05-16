//
//  MealViewModel.swift
//  BeFit
//
//  Created by AI Assistant on 3/31/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MealViewModel: ObservableObject {
    @Published var meals: [Meal] = []
    @Published var dailyMeals: [Meal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastAddedMealId: String?
    @Published var todayNutrition = NutritionTotals()
    
    private let db = Firestore.firestore()
    
    // Calorie calculation constants
    static let proteinCaloriesPerGram = 4
    static let carbsCaloriesPerGram = 4
    static let fatCaloriesPerGram = 9
    
    // Calculate calories from macronutrients
    static func calculateCalories(protein: Int, carbs: Int, fat: Int) -> Int {
        return (protein * proteinCaloriesPerGram) +
               (carbs * carbsCaloriesPerGram) +
               (fat * fatCaloriesPerGram)
    }
    
    // Calculate calories from weight and macronutrient percentages
    static func calculateCaloriesFromWeight(
        weight: Double, 
        proteinPercentage: Double, 
        carbsPercentage: Double, 
        fatPercentage: Double
    ) -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        // Calculate grams of each macronutrient based on percentages of total weight
        let proteinGrams = Int(round(weight * proteinPercentage / 100))
        let carbsGrams = Int(round(weight * carbsPercentage / 100))
        let fatGrams = Int(round(weight * fatPercentage / 100))
        
        // Calculate calories from each macronutrient
        let proteinCalories = proteinGrams * proteinCaloriesPerGram
        let carbsCalories = carbsGrams * carbsCaloriesPerGram
        let fatCalories = fatGrams * fatCaloriesPerGram
        
        // Total calories
        let totalCalories = proteinCalories + carbsCalories + fatCalories
        
        return (totalCalories, proteinGrams, carbsGrams, fatGrams)
    }
    
    // Fetch all meals for a user
    func fetchMeals() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            // Create a base query without ordering first
            let baseQuery = db.collection("meals")
                .whereField("userId", isEqualTo: userId)
            
            // Execute the query
            let querySnapshot = try await baseQuery
                .order(by: "date", descending: true)
                .getDocuments()
            
            self.meals = querySnapshot.documents.compactMap { document in
                try? document.data(as: Meal.self)
            }
            
            // Filter today's meals
            filterTodayMeals()
            
            // Update today's nutrition totals
            updateTodayNutrition()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch meals: \(error.localizedDescription)"
            print("DEBUG: Failed to fetch meals with error: \(error.localizedDescription)")
            
            // If the error is about missing index, show a more helpful error message
            if error.localizedDescription.contains("requires an index") {
                errorMessage = "Database indexing required. Please create the index using the Firebase console link and try again."
                print("DEBUG: Firebase index required. Please visit the Firebase console to create the index.")
            }
        }
    }
    
    // Add a new meal with weight (optional)
    func addMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, mealType: MealType, weight: Double? = nil) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Verify calories match the macros (optional validation)
        let calculatedCalories = MealViewModel.calculateCalories(protein: protein, carbs: carbs, fat: fat)
        if abs(calculatedCalories - calories) > 5 {
            print("DEBUG: Warning - Calories input (\(calories)) doesn't match calculated calories (\(calculatedCalories))")
        }
        
        let newMeal = Meal(
            id: nil,
            userId: userId,
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: Date(),
            mealType: mealType,
            weight: weight
        )
        
        do {
            let docRef = try await db.collection("meals").addDocument(data: try Firestore.Encoder().encode(newMeal))
            // Store the added meal ID for UI highlighting
            self.lastAddedMealId = docRef.documentID
            
            // Refresh meals to include the new one
            await fetchMeals()
        } catch {
            throw error
        }
    }
    
    // Delete a meal
    func deleteMeal(_ meal: Meal) async throws {
        guard let mealId = meal.id else { return }
        
        do {
            try await db.collection("meals").document(mealId).delete()
            await fetchMeals()
        } catch {
            throw error
        }
    }
    
    // Calculate total nutrients for today
    func calculateTodayTotals() -> NutritionTotals {
        return todayNutrition
    }
    
    // Update today's nutrition totals
    private func updateTodayNutrition() {
        let calories = dailyMeals.reduce(0) { $0 + $1.calories }
        let protein = dailyMeals.reduce(0) { $0 + $1.protein }
        let carbs = dailyMeals.reduce(0) { $0 + $1.carbs }
        let fat = dailyMeals.reduce(0) { $0 + $1.fat }
        
        todayNutrition = NutritionTotals(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
    
    // Calculate remaining nutrients for today
    func calculateRemainingMacros(tdee: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int) -> NutritionTotals {
        let totals = todayNutrition
        
        let remainingCalories = max(0, tdee - totals.calories)
        let remainingProtein = max(0, targetProtein - totals.protein)
        let remainingCarbs = max(0, targetCarbs - totals.carbs)
        let remainingFat = max(0, targetFat - totals.fat)
        
        return NutritionTotals(
            calories: remainingCalories, 
            protein: remainingProtein, 
            carbs: remainingCarbs, 
            fat: remainingFat
        )
    }
    
    // Filter meals for today
    private func filterTodayMeals() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        dailyMeals = meals.filter { meal in
            calendar.isDate(calendar.startOfDay(for: meal.date), inSameDayAs: today)
        }
    }
}

// A struct to represent nutrition totals that conforms to Equatable
struct NutritionTotals: Equatable {
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    
    static func == (lhs: NutritionTotals, rhs: NutritionTotals) -> Bool {
        return lhs.calories == rhs.calories &&
               lhs.protein == rhs.protein &&
               lhs.carbs == rhs.carbs &&
               lhs.fat == rhs.fat
    }
} 