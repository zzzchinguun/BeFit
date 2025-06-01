//
//  NutritionDatabaseViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class NutritionDatabaseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var foods: [NutritionData] = []
    @Published var filteredFoods: [NutritionData] = []
    @Published var isLoading: Bool = false
    @Published var selectedCategory: FoodCategory? = nil
    @Published var searchText: String = ""
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var scannedBarcode: String = ""
    @Published var isScanningBarcode: Bool = false
    @Published var foodFromBarcode: NutritionData? = nil
    
    // MARK: - Services
    
    let nutritionDataService: NutritionDataServiceProtocol
    private let mealService: MealServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(nutritionDataService: NutritionDataServiceProtocol = ServiceContainer.shared.nutritionDataService,
         mealService: MealServiceProtocol = ServiceContainer.shared.mealService) {
        self.nutritionDataService = nutritionDataService
        self.mealService = mealService
        
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to foods
        nutritionDataService.foods
            .receive(on: RunLoop.main)
            .sink { [weak self] foods in
                self?.foods = foods
            }
            .store(in: &cancellables)
        
        // Subscribe to filtered foods
        nutritionDataService.filteredFoods
            .receive(on: RunLoop.main)
            .sink { [weak self] filteredFoods in
                self?.filteredFoods = filteredFoods
            }
            .store(in: &cancellables)
        
        // Subscribe to loading state
        nutritionDataService.isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Forward search text to the service
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.nutritionDataService.searchQuery.send(text)
            }
            .store(in: &cancellables)
        
        // Forward selected category to the service
        $selectedCategory
            .sink { [weak self] category in
                self?.nutritionDataService.selectedCategory.send(category)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load foods from the service
    func loadFoods() {
        nutritionDataService.loadFoods()
    }
    
    /// Select a food category
    func selectCategory(_ category: FoodCategory?) {
        selectedCategory = category
    }
    
    /// Add a food to meal log
    func addFoodToMealLog(food: NutritionData, weight: Double, mealType: MealType) async {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            await MainActor.run {
                self.errorMessage = "Хэрэглэгч олдсонгүй."
                self.showErrorAlert = true
            }
            return
        }
        
        do {
            let meal = food.createMeal(userId: userId, weight: weight, mealType: mealType)
            
            // Add meal without triggering excessive refreshes
            try await mealService.addMeal(
                name: meal.name,
                calories: meal.calories,
                protein: meal.protein,
                carbs: meal.carbs,
                fat: meal.fat,
                mealType: meal.mealType,
                weight: meal.weight
            )
            
            print("Successfully added \(meal.name) to meal log")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Хоолны өгөгдөл нэмэхэд алдаа гарлаа: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
            print("Error adding food to meal log: \(error)")
        }
    }
    
    /// Look up a food by barcode
    func lookupFoodByBarcode(_ barcode: String) {
        scannedBarcode = barcode
        foodFromBarcode = nutritionDataService.getFoodByBarcode(barcode)
        
        if foodFromBarcode == nil {
            errorMessage = "No food found with barcode: \(barcode)"
            showErrorAlert = true
        }
    }
    
    /// Add a custom food to the database with image and barcode
    func addCustomFood(
        name: String, 
        category: FoodCategory,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        sugar: Double,
        servingSizeGrams: Double,
        servingDescription: String,
        imageURL: String? = nil,
        barcode: String? = nil
    ) {
        
        let id = "custom_\(UUID().uuidString)"
        
        // Get current user info for creator attribution
        let currentUserId = AuthService.shared.getCurrentUserId()
        let currentUserEmail = AuthService.shared.currentUser.value?.email
        
        let food = NutritionData(
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
            creatorUserId: currentUserId,
            createdByEmail: currentUserEmail
        )
        
        nutritionDataService.addCustomFood(food)
    }
    
    /// Remove a custom food
    func removeCustomFood(withId id: String) {
        nutritionDataService.removeCustomFood(withId: id)
    }
    
    /// Get a food by its ID
    func getFoodById(_ id: String) -> NutritionData? {
        return nutritionDataService.getFoodById(id)
    }
    
    /// Get a food by its barcode
    func getFoodByBarcode(_ barcode: String) -> NutritionData? {
        return nutritionDataService.getFoodByBarcode(barcode)
    }
} 