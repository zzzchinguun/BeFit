//
//  MealService.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Protocol defining meal service capabilities
protocol MealServiceProtocol {
    var meals: CurrentValueSubject<[Meal], Never> { get }
    var dailyMeals: CurrentValueSubject<[Meal], Never> { get }
    var todayNutrition: CurrentValueSubject<NutritionTotals, Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var errorMessage: CurrentValueSubject<String?, Never> { get }
    var lastAddedMealId: CurrentValueSubject<String?, Never> { get }
    
    func fetchMeals() async
    func addMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, mealType: MealType, weight: Double?) async throws
    func updateMeal(_ meal: Meal) async throws
    func deleteMeal(_ meal: Meal) async throws
    func calculateTodayTotals() -> NutritionTotals
    func calculateRemainingMacros(goalCalories: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int) -> NutritionTotals
    func filterTodayMeals()
}

/// Service for handling meal operations
class MealService: FirebaseService, MealServiceProtocol {
    // MARK: - Properties
    
    let meals = CurrentValueSubject<[Meal], Never>([])
    let dailyMeals = CurrentValueSubject<[Meal], Never>([])
    let todayNutrition = CurrentValueSubject<NutritionTotals, Never>(NutritionTotals())
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = CurrentValueSubject<String?, Never>(nil)
    let lastAddedMealId = CurrentValueSubject<String?, Never>(nil)
    
    // Calorie calculation constants
    static let proteinCaloriesPerGram = 4
    static let carbsCaloriesPerGram = 4
    static let fatCaloriesPerGram = 9
    
    // MARK: - Meal Methods
    
    /// Fetches all meals for the current user
    func fetchMeals() async {
        guard let userId = getCurrentUserId() else { return }
        
        isLoading.send(true)
        
        do {
            // Create a base query without ordering first
            let baseQuery = db.collection("meals")
                .whereField("userId", isEqualTo: userId)
            
            // Execute the query
            let querySnapshot = try await baseQuery
                .order(by: "date", descending: true)
                .getDocuments()
            
            let fetchedMeals = querySnapshot.documents.compactMap { document in
                try? document.data(as: Meal.self)
            }
            
            // Update published values
            meals.send(fetchedMeals)
            
            // Filter today's meals
            filterTodayMeals()
            
            // Update today's nutrition totals
            updateTodayNutrition()
            
            isLoading.send(false)
        } catch let fetchError {
            isLoading.send(false)
            let message = handleError(fetchError).localizedDescription
            errorMessage.send(message)
            
            // If the error is about missing index, show a more helpful error message
            if message.contains("requires an index") {
                errorMessage.send("Database indexing required. Please create the index using the Firebase console link and try again.")
            }
        }
    }
    
    /// Adds a new meal
    func addMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, mealType: MealType, weight: Double? = nil) async throws {
        guard let userId = getCurrentUserId() else {
            throw FirebaseError.authError("No user is currently signed in")
        }
        
        // Verify calories match the macros (optional validation)
        let calculatedCalories = MealService.calculateCalories(protein: protein, carbs: carbs, fat: fat)
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
            lastAddedMealId.send(docRef.documentID)
            
            // Optimistically update local data instead of full refresh
            var currentMeals = meals.value
            let newMealWithId = Meal(
                id: docRef.documentID,
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
            
            currentMeals.insert(newMealWithId, at: 0) // Add to beginning (newest first)
            meals.send(currentMeals)
            
            // Update daily meals and nutrition efficiently
            filterTodayMeals()
            updateTodayNutrition()
            
        } catch {
            throw handleError(error)
        }
    }
    
    /// Updates an existing meal
    func updateMeal(_ meal: Meal) async throws {
        guard let mealId = meal.id else {
            throw FirebaseError.databaseError("Meal does not have a valid ID")
        }
        
        do {
            try await db.collection("meals").document(mealId).setData(try Firestore.Encoder().encode(meal))
            
            // Optimistically update local data
            var currentMeals = meals.value
            if let index = currentMeals.firstIndex(where: { $0.id == mealId }) {
                currentMeals[index] = meal
                meals.send(currentMeals)
                
                // Update daily meals and nutrition
                filterTodayMeals()
                updateTodayNutrition()
            }
            
        } catch {
            // If update fails, refresh from server
            await fetchMeals()
            throw handleError(error)
        }
    }
    
    /// Deletes a meal
    func deleteMeal(_ meal: Meal) async throws {
        guard let mealId = meal.id else {
            throw FirebaseError.databaseError("Meal does not have a valid ID")
        }
        
        do {
            try await db.collection("meals").document(mealId).delete()
            
            // Optimistically update local data
            var currentMeals = meals.value
            currentMeals.removeAll { $0.id == mealId }
            meals.send(currentMeals)
            
            // Update daily meals and nutrition
            filterTodayMeals()
            updateTodayNutrition()
            
        } catch {
            // If delete fails, refresh from server
            await fetchMeals()
            throw handleError(error)
        }
    }
    
    /// Calculate total nutrients for today
    func calculateTodayTotals() -> NutritionTotals {
        return todayNutrition.value
    }
    
    /// Update today's nutrition totals
    private func updateTodayNutrition() {
        let currentDailyMeals = dailyMeals.value
        let calories = currentDailyMeals.reduce(0) { $0 + $1.calories }
        let protein = currentDailyMeals.reduce(0) { $0 + $1.protein }
        let carbs = currentDailyMeals.reduce(0) { $0 + $1.carbs }
        let fat = currentDailyMeals.reduce(0) { $0 + $1.fat }
        
        todayNutrition.send(NutritionTotals(calories: calories, protein: protein, carbs: carbs, fat: fat))
    }
    
    /// Calculate remaining nutrients for today
    func calculateRemainingMacros(goalCalories: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int) -> NutritionTotals {
        let totals = todayNutrition.value
        
        let remainingCalories = max(0, goalCalories - totals.calories)
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
    
    /// Filter meals for today
    func filterTodayMeals() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todayMeals = meals.value.filter { meal in
            calendar.isDate(calendar.startOfDay(for: meal.date), inSameDayAs: today)
        }
        
        dailyMeals.send(todayMeals)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate calories from macronutrients
    static func calculateCalories(protein: Int, carbs: Int, fat: Int) -> Int {
        return (protein * proteinCaloriesPerGram) +
               (carbs * carbsCaloriesPerGram) +
               (fat * fatCaloriesPerGram)
    }
    
    /// Calculate calories from weight and macronutrient percentages
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
} 