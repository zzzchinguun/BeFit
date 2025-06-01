//
//  NutritionDataService.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import Foundation
import Combine
import FirebaseFirestore

protocol NutritionDataServiceProtocol {
    var foods: CurrentValueSubject<[NutritionData], Never> { get }
    var filteredFoods: CurrentValueSubject<[NutritionData], Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var selectedCategory: CurrentValueSubject<FoodCategory?, Never> { get }
    var searchQuery: CurrentValueSubject<String, Never> { get }
    var userUnverifiedMeals: CurrentValueSubject<[UnverifiedMeal], Never> { get }
    
    func loadFoods()
    func filterFoods(category: FoodCategory?, searchText: String)
    func addCustomFood(_ food: NutritionData)
    func removeCustomFood(withId id: String)
    func getFoodById(_ id: String) -> NutritionData?
    func getFoodByBarcode(_ barcode: String) -> NutritionData?
}

class NutritionDataService: NutritionDataServiceProtocol {
    // MARK: - Published Properties
    
    let foods = CurrentValueSubject<[NutritionData], Never>([])
    let filteredFoods = CurrentValueSubject<[NutritionData], Never>([])
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let selectedCategory = CurrentValueSubject<FoodCategory?, Never>(nil)
    let searchQuery = CurrentValueSubject<String, Never>("")
    
    // User's own unverified meals (pending approval)
    let userUnverifiedMeals = CurrentValueSubject<[UnverifiedMeal], Never>([])
    
    // MARK: - Storage Keys
    
    private let customFoodsKey = "customFoods"
    
    // MARK: - Services
    
    private let verifiedMealService: VerifiedMealServiceProtocol
    private let mealVerificationService: MealVerificationServiceProtocol
    
    // MARK: - Init
    
    init(
        verifiedMealService: VerifiedMealServiceProtocol = VerifiedMealService.shared,
        mealVerificationService: MealVerificationServiceProtocol = MealVerificationService.shared
    ) {
        self.verifiedMealService = verifiedMealService
        self.mealVerificationService = mealVerificationService
        
        loadFoods()
        
        // Set up subscriptions for automatic filtering
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Combine the category and search text publishers to filter foods
        Publishers.CombineLatest(selectedCategory, searchQuery)
            .sink { [weak self] category, query in
                self?.filterFoods(category: category, searchText: query)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Load foods from sample data, verified meals, user's unverified meals, and any custom foods from UserDefaults
    func loadFoods() {
        // Prevent multiple simultaneous loads
        guard !isLoading.value else {
            print("🔄 Foods already loading, skipping duplicate request")
            return
        }
        
        isLoading.send(true)
        
        print("🔄 Starting to load foods...")
        
        // Start with the sample foods from the static data
        var allFoods = NutritionData.sampleFoods
        print("✅ Loaded \(allFoods.count) sample foods")
        
        // Load verified meals and user's unverified meals from Firebase
        Task {
            do {
                // Load verified meals from VerifiedMealService
                await verifiedMealService.fetchVerifiedMeals()
                let verifiedFoods = verifiedMealService.verifiedMeals.value
                
                await MainActor.run {
                    allFoods.append(contentsOf: verifiedFoods)
                    print("✅ Loaded \(verifiedFoods.count) verified meals")
                }
                
                // Load user's unverified meals so they can see their pending submissions
                await fetchUserUnverifiedMeals()
                let userUnverifiedMeals = self.userUnverifiedMeals.value
                let userUnverifiedFoods = userUnverifiedMeals.map { $0.toNutritionData() }
                
                await MainActor.run {
                    allFoods.append(contentsOf: userUnverifiedFoods)
                    print("✅ Loaded \(userUnverifiedMeals.count) user's own unverified meals")
                }
                
                // Load any custom foods saved locally (legacy support)
                if let data = UserDefaults.standard.data(forKey: customFoodsKey),
                   let customFoods = try? JSONDecoder().decode([NutritionData].self, from: data) {
                    await MainActor.run {
                        allFoods.append(contentsOf: customFoods)
                        print("✅ Loaded \(customFoods.count) custom foods from UserDefaults")
                    }
                }
                
                // Remove duplicates and update on main thread
                await MainActor.run {
                    let uniqueFoods = self.removeDuplicateFoods(allFoods)
                    print("✅ Total foods loaded after deduplication: \(uniqueFoods.count)")
                    
                    // Update the published foods
                    self.foods.send(uniqueFoods)
                    
                    // Apply initial filters
                    self.filterFoods(category: self.selectedCategory.value, searchText: self.searchQuery.value)
                    
                    print("✅ Foods loading completed")
                    
                    // Clear loading state
                    self.isLoading.send(false)
                }
                
            } catch {
                print("❌ Error loading foods: \(error.localizedDescription)")
                
                await MainActor.run {
                    // Even if Firebase fails, we still have sample foods
                    let uniqueFoods = self.removeDuplicateFoods(allFoods)
                    self.foods.send(uniqueFoods)
                    self.filterFoods(category: self.selectedCategory.value, searchText: self.searchQuery.value)
                    
                    // Clear loading state
                    self.isLoading.send(false)
                }
            }
        }
    }
    
    /// Filter foods based on category and search text
    func filterFoods(category: FoodCategory?, searchText: String) {
        var filtered = foods.value
        
        // Filter by category if selected
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text if not empty
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) 
            }
        }
        
        // Update filtered foods
        filteredFoods.send(filtered)
    }
    
    /// Add a custom food to the unverified meals collection
    func addCustomFood(_ food: NutritionData) {
        print("🔄 Starting to add custom food: \(food.name)")
        
        // Check authentication
        guard let userId = AuthService.shared.getCurrentUserId() else {
            print("❌ Error: No user ID available from AuthService")
            return
        }
        print("✅ User ID found: \(userId)")
        
        guard let currentUser = AuthService.shared.currentUser.value else {
            print("❌ Error: No current user data available")
            return
        }
        print("✅ Current user found: \(currentUser.email)")
        
        let unverifiedMeal = UnverifiedMeal(
            userId: userId,
            createdByEmail: currentUser.email,
            name: food.name,
            calories: Int(food.calories),
            protein: Int(food.protein),
            carbs: Int(food.carbs),
            fat: Int(food.fat),
            fiber: food.fiber,
            sugar: food.sugar,
            servingSizeGrams: food.servingSizeGrams,
            servingDescription: food.servingDescription,
            category: food.category,
            imageURL: food.imageURL,
            barcode: food.barcode
        )
        
        print("🔄 Created UnverifiedMeal object, attempting to save to Firebase...")
        
        // Save to unverified meals collection
        Task {
            do {
                try await mealVerificationService.addUnverifiedMeal(unverifiedMeal)
                print("✅ Successfully added custom food to unverified meals: \(food.name)")
                
                // Refresh user's unverified meals to show the new addition immediately
                await fetchUserUnverifiedMeals()
                
                // Update the main foods list to include the new unverified meal
                await MainActor.run {
                    var currentFoods = self.foods.value
                    currentFoods.append(food)
                    currentFoods.sort { $0.name < $1.name }
                    self.foods.send(currentFoods)
                    
                    // Reapply filters
                    self.filterFoods(category: self.selectedCategory.value, searchText: self.searchQuery.value)
                    
                    // Notify other parts of the app to refresh (reduced frequency)
                    NotificationCenter.default.post(name: Notification.Name("refreshNutritionDatabase"), object: nil)
                }
                
                // Provide user feedback that the meal was submitted for review
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: Notification.Name("customFoodSubmitted"),
                        object: food.name
                    )
                }
                
            } catch {
                print("❌ Error adding custom food to unverified meals: \(error.localizedDescription)")
                print("🔄 Falling back to local storage...")
                
                // Fallback: save to local storage
                await MainActor.run {
                    var currentFoods = self.foods.value
                    
                    // Add the new food
                    currentFoods.append(food)
                    
                    // Sort foods alphabetically
                    currentFoods.sort { $0.name < $1.name }
                    
                    // Update the publisher
                    self.foods.send(currentFoods)
                    
                    // Save custom foods locally as backup
                    self.saveCustomFoods()
                    
                    // Reapply filters
                    self.filterFoods(category: self.selectedCategory.value, searchText: self.searchQuery.value)
                    
                    print("✅ Saved to local storage as fallback")
                    
                    // Reduced notifications
                    NotificationCenter.default.post(name: Notification.Name("refreshNutritionDatabase"), object: nil)
                    
                    // Notify user about fallback
                    NotificationCenter.default.post(
                        name: Notification.Name("customFoodSavedLocally"),
                        object: food.name
                    )
                }
            }
        }
    }
    
    /// Remove a custom food from the database
    func removeCustomFood(withId id: String) {
        var currentFoods = foods.value
        
        // Remove the food with the given ID
        currentFoods.removeAll { $0.id == id && $0.category == .custom }
        
        // Update the publisher
        foods.send(currentFoods)
        
        // Save custom foods
        saveCustomFoods()
        
        // Reapply filters
        filterFoods(category: selectedCategory.value, searchText: searchQuery.value)
    }
    
    /// Get a food by its ID
    func getFoodById(_ id: String) -> NutritionData? {
        return foods.value.first { $0.id == id }
    }
    
    /// Get a food by barcode
    func getFoodByBarcode(_ barcode: String) -> NutritionData? {
        return foods.value.first { $0.barcode == barcode }
    }
    
    // MARK: - Private Helper Methods
    
    /// Fetch current user's unverified meals so they can see their pending submissions
    private func fetchUserUnverifiedMeals() async {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            print("❌ Cannot fetch user unverified meals: No user ID available")
            return
        }
        
        do {
            let userMeals = try await mealVerificationService.fetchUserUnverifiedMeals(userId: userId)
            
            await MainActor.run {
                self.userUnverifiedMeals.send(userMeals)
            }
            
            print("✅ Loaded \(userMeals.count) user unverified meals")
            
        } catch {
            print("❌ Error fetching user unverified meals: \(error.localizedDescription)")
            await MainActor.run {
                self.userUnverifiedMeals.send([])
            }
        }
    }
    
    private func saveCustomFoods() {
        // Filter for custom foods only (legacy local storage support)
        let customFoods = foods.value.filter { $0.category == .custom && $0.id.hasPrefix("custom_") }
        
        // Encode and save
        if let data = try? JSONEncoder().encode(customFoods) {
            UserDefaults.standard.set(data, forKey: customFoodsKey)
        }
    }
    
    /// Remove duplicate foods based on name and barcode combination
    private func removeDuplicateFoods(_ foods: [NutritionData]) -> [NutritionData] {
        var uniqueFoods: [NutritionData] = []
        var seenIdentifiers: Set<String> = []
        var duplicateCount = 0
        
        for food in foods {
            // Create a unique identifier based on name and barcode
            let identifier: String
            if let barcode = food.barcode, !barcode.isEmpty {
                identifier = "\(food.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))_\(barcode)"
            } else {
                identifier = food.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            if !seenIdentifiers.contains(identifier) {
                seenIdentifiers.insert(identifier)
                uniqueFoods.append(food)
            } else {
                duplicateCount += 1
                // Only log every 5th duplicate to reduce console spam
                if duplicateCount % 5 == 0 {
                    print("🔄 Removing duplicate food: \(food.name)")
                }
            }
        }
        
        if duplicateCount > 0 {
            print("✅ Removed \(duplicateCount) duplicate foods")
        }
        return uniqueFoods
    }
}

// Factory extension for creating instances
extension NutritionDataService {
    static let shared = NutritionDataService()
} 