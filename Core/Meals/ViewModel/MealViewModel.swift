//
//  MealViewModel.swift
//  BeFit
//
//  Created by AI Assistant on 3/31/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class MealViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var meals: [Meal] = []
    @Published var dailyMeals: [Meal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastAddedMealId: String?
    @Published var todayNutrition = NutritionTotals()
    
    // MARK: - Services
    
    private let mealService: MealServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(mealService: MealServiceProtocol = ServiceContainer.shared.mealService) {
        self.mealService = mealService
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to meals
        mealService.meals
            .receive(on: RunLoop.main)
            .sink { [weak self] meals in
                self?.meals = meals
            }
            .store(in: &cancellables)
        
        // Subscribe to daily meals
        mealService.dailyMeals
            .receive(on: RunLoop.main)
            .sink { [weak self] dailyMeals in
                self?.dailyMeals = dailyMeals
            }
            .store(in: &cancellables)
        
        // Subscribe to today's nutrition
        mealService.todayNutrition
            .receive(on: RunLoop.main)
            .sink { [weak self] nutrition in
                self?.todayNutrition = nutrition
            }
            .store(in: &cancellables)
        
        // Subscribe to loading state
        mealService.isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Subscribe to error messages
        mealService.errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        // Subscribe to last added meal ID
        mealService.lastAddedMealId
            .receive(on: RunLoop.main)
            .sink { [weak self] mealId in
                self?.lastAddedMealId = mealId
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetch all meals from the service
    func fetchMeals() async {
        await mealService.fetchMeals()
    }
    
    /// Add a new meal
    func addMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, mealType: MealType, weight: Double? = nil) async throws {
        try await mealService.addMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: mealType,
            weight: weight
        )
    }
    
    /// Update an existing meal
    func updateMeal(_ meal: Meal) async throws {
        try await mealService.updateMeal(meal)
    }
    
    /// Delete a meal
    func deleteMeal(_ meal: Meal) async throws {
        try await mealService.deleteMeal(meal)
    }
    
    /// Calculate total nutrients for today
    func calculateTodayTotals() -> NutritionTotals {
        return mealService.calculateTodayTotals()
    }
    
    /// Calculate remaining nutrients for today
    func calculateRemainingMacros(goalCalories: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int) -> NutritionTotals {
        return mealService.calculateRemainingMacros(
            goalCalories: goalCalories,
            targetProtein: targetProtein,
            targetCarbs: targetCarbs,
            targetFat: targetFat
        )
    }
    
    /// Filter meals for today
    func filterTodayMeals() {
        mealService.filterTodayMeals()
    }
    
    // MARK: - Helper Methods
    
    /// Calculate calories from macronutrients
    static func calculateCalories(protein: Int, carbs: Int, fat: Int) -> Int {
        return MealService.calculateCalories(protein: protein, carbs: carbs, fat: fat)
    }
    
    /// Calculate calories from weight and macronutrient percentages
    static func calculateCaloriesFromWeight(
        weight: Double, 
        proteinPercentage: Double, 
        carbsPercentage: Double, 
        fatPercentage: Double
    ) -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        return MealService.calculateCaloriesFromWeight(
            weight: weight,
            proteinPercentage: proteinPercentage,
            carbsPercentage: carbsPercentage,
            fatPercentage: fatPercentage
        )
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
