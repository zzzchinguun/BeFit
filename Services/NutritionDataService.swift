//
//  NutritionDataService.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import Foundation
import Combine

protocol NutritionDataServiceProtocol {
    var foods: CurrentValueSubject<[NutritionData], Never> { get }
    var filteredFoods: CurrentValueSubject<[NutritionData], Never> { get }
    var isLoading: CurrentValueSubject<Bool, Never> { get }
    var selectedCategory: CurrentValueSubject<FoodCategory?, Never> { get }
    var searchQuery: CurrentValueSubject<String, Never> { get }
    
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
    
    // MARK: - Storage Keys
    
    private let customFoodsKey = "customFoods"
    
    // MARK: - Init
    
    init() {
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
    
    /// Load foods from sample data and any custom foods from UserDefaults
    func loadFoods() {
        isLoading.send(true)
        
        // Start with the sample foods from the static data
        var allFoods = NutritionData.sampleFoods
        
        // Load any custom foods from UserDefaults
        if let data = UserDefaults.standard.data(forKey: customFoodsKey),
           let customFoods = try? JSONDecoder().decode([NutritionData].self, from: data) {
            // Add custom foods to the list
            allFoods.append(contentsOf: customFoods)
        }
        
        // Sort foods alphabetically
        allFoods.sort { $0.name < $1.name }
        
        // Update publishers
        foods.send(allFoods)
        filteredFoods.send(allFoods)
        
        isLoading.send(false)
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
    
    /// Add a custom food to the database
    func addCustomFood(_ food: NutritionData) {
        var currentFoods = foods.value
        
        // Add the new food
        currentFoods.append(food)
        
        // Sort foods alphabetically
        currentFoods.sort { $0.name < $1.name }
        
        // Update the publisher
        foods.send(currentFoods)
        
        // Save custom foods
        saveCustomFoods()
        
        // Reapply filters
        filterFoods(category: selectedCategory.value, searchText: searchQuery.value)
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
    
    private func saveCustomFoods() {
        // Filter for custom foods only
        let customFoods = foods.value.filter { $0.category == .custom }
        
        // Encode and save
        if let data = try? JSONEncoder().encode(customFoods) {
            UserDefaults.standard.set(data, forKey: customFoodsKey)
        }
    }
}

// Factory extension for creating instances
extension NutritionDataService {
    static let shared = NutritionDataService()
} 