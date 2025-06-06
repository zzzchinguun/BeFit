//
//  NutritionData.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import Foundation

struct NutritionData: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: FoodCategory
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let servingSizeGrams: Double
    let servingDescription: String
    let imageURL: String?
    let barcode: String?
    
    // Creator information - optional for backwards compatibility
    let creatorUserId: String?
    let createdByEmail: String?
    
    // Common foods often have standard reference amounts
    var isCommonFood: Bool {
        return category != .custom
    }
    
    // Initialize with optional imageURL, barcode, and creator info
    init(
        id: String, 
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
        barcode: String? = nil,
        creatorUserId: String? = nil,
        createdByEmail: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.servingSizeGrams = servingSizeGrams
        self.servingDescription = servingDescription
        self.imageURL = imageURL
        self.barcode = barcode
        self.creatorUserId = creatorUserId
        self.createdByEmail = createdByEmail
    }
}

extension NutritionData {
    // Calculate values for custom weight
    func valuesForWeight(_ weight: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let ratio = weight / servingSizeGrams
        return (
            calories: calories * ratio,
            protein: protein * ratio,
            carbs: carbs * ratio,
            fat: fat * ratio
        )
    }
    
    // Create meal from nutrition data with specified weight
    func createMeal(userId: String, weight: Double, mealType: MealType) -> Meal {
        let values = valuesForWeight(weight)
        
        return Meal(
            id: UUID().uuidString,
            userId: userId,
            name: name,
            calories: Int(values.calories.rounded()),
            protein: Int(values.protein.rounded()),
            carbs: Int(values.carbs.rounded()),
            fat: Int(values.fat.rounded()),
            date: Date(),
            mealType: mealType,
            weight: weight
        )
    }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case meat = "Мах"
    case dairy = "Сүүн бүтээгдэхүүн"
    case grains = "Үр тариа"
    case fruits = "Жимс"
    case vegetables = "Хүнсний ногоо"
    case nuts = "Самар, үр"
    case beverages = "Ундаа"
    case snacks = "Жижиг хоол"
    case custom = "Өөрийн хоол"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .meat: return "fork.knife"
        case .dairy: return "cup.and.saucer.fill"
        case .grains: return "leaf.fill"
        case .fruits: return "apple.logo"
        case .vegetables: return "carrot.fill" 
        case .nuts: return "ellipsis.curlybraces"
        case .beverages: return "mug.fill"
        case .snacks: return "birthday.cake.fill"
        case .custom: return "plus.circle.fill"
        }
    }
}

// Sample data with common Mongolian and international foods
extension NutritionData {
    static let sampleFoods: [NutritionData] = [
        // Meat & Protein
        NutritionData(
            id: "beef_boiled",
            name: "Чанасан үхрийн мах",
            category: .meat,
            calories: 250.0,
            protein: 26.0,
            carbs: 0.0,
            fat: 15.0,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "mutton_boiled",
            name: "Чанасан хонины мах",
            category: .meat,
            calories: 294.0,
            protein: 25.0,
            carbs: 0.0,
            fat: 21.0,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "chicken_breast",
            name: "Тахианы цээж",
            category: .meat,
            calories: 165.0,
            protein: 31.0,
            carbs: 0.0,
            fat: 3.6,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        
        // Dairy
        NutritionData(
            id: "milk",
            name: "Сүү",
            category: .dairy,
            calories: 42.0,
            protein: 3.4,
            carbs: 5.0,
            fat: 1.0,
            fiber: 0.0,
            sugar: 5.0,
            servingSizeGrams: 100.0,
            servingDescription: "100мл"
        ),
        NutritionData(
            id: "aaruul",
            name: "Ааруул",
            category: .dairy,
            calories: 310.0,
            protein: 31.0,
            carbs: 12.0,
            fat: 15.0,
            fiber: 0.0,
            sugar: 12.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        
        // Grains
        NutritionData(
            id: "rice_boiled",
            name: "Чанасан цагаан будаа",
            category: .grains,
            calories: 130.0,
            protein: 2.7,
            carbs: 28.0,
            fat: 0.3,
            fiber: 0.4,
            sugar: 0.1,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "oatmeal",
            name: "Овъёос",
            category: .grains,
            calories: 68.0,
            protein: 2.4,
            carbs: 12.0,
            fat: 1.4,
            fiber: 2.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г буцалсан"
        ),
        
        // Vegetables
        NutritionData(
            id: "potato_boiled",
            name: "Чанасан төмс",
            category: .vegetables,
            calories: 86.0,
            protein: 1.7,
            carbs: 20.0,
            fat: 0.1,
            fiber: 1.8,
            sugar: 0.8,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "carrot_raw",
            name: "Түүхий лууван",
            category: .vegetables,
            calories: 41.0,
            protein: 0.9,
            carbs: 9.6,
            fat: 0.2,
            fiber: 2.8,
            sugar: 4.7,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        
        // Fruits
        NutritionData(
            id: "apple",
            name: "Алим",
            category: .fruits,
            calories: 52.0,
            protein: 0.3,
            carbs: 14.0,
            fat: 0.2,
            fiber: 2.4,
            sugar: 10.0,
            servingSizeGrams: 100.0,
            servingDescription: "1 дунд зэргийн"
        ),
        NutritionData(
            id: "banana",
            name: "Гадил",
            category: .fruits,
            calories: 89.0,
            protein: 1.1,
            carbs: 23.0,
            fat: 0.3,
            fiber: 2.6,
            sugar: 12.0,
            servingSizeGrams: 100.0,
            servingDescription: "1 дунд зэргийн"
        ),
        
        // Snacks
        NutritionData(
            id: "chocolate",
            name: "Хар шоколад",
            category: .snacks,
            calories: 546.0,
            protein: 4.9,
            carbs: 61.0,
            fat: 31.0,
            fiber: 7.0,
            sugar: 48.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        
        // Traditional Mongolian Dishes
        NutritionData(
            id: "tsuivan",
            name: "Цуйван",
            category: .custom,
            calories: 350.0,
            protein: 15.0,
            carbs: 45.0,
            fat: 12.0,
            fiber: 3.0,
            sugar: 2.0,
            servingSizeGrams: 300.0,
            servingDescription: "1 таваг"
        ),
        NutritionData(
            id: "huitsaa",
            name: "Хуйцаа",
            category: .custom,
            calories: 280.0,
            protein: 12.0,
            carbs: 35.0,
            fat: 10.0,
            fiber: 2.0,
            sugar: 1.0,
            servingSizeGrams: 250.0,
            servingDescription: "1 таваг"
        ),
        NutritionData(
            id: "bansh",
            name: "Банш",
            category: .custom,
            calories: 220.0,
            protein: 18.0,
            carbs: 25.0,
            fat: 8.0,
            fiber: 1.5,
            sugar: 0.5,
            servingSizeGrams: 200.0,
            servingDescription: "1 таваг"
        ),
        NutritionData(
            id: "buuz",
            name: "Бууз",
            category: .custom,
            calories: 180.0,
            protein: 15.0,
            carbs: 20.0,
            fat: 7.0,
            fiber: 1.0,
            sugar: 0.5,
            servingSizeGrams: 100.0,
            servingDescription: "1 ширхэг"
        ),
        NutritionData(
            id: "khuushuur",
            name: "Хуушуур",
            category: .custom,
            calories: 320.0,
            protein: 20.0,
            carbs: 30.0,
            fat: 15.0,
            fiber: 1.5,
            sugar: 0.5,
            servingSizeGrams: 150.0,
            servingDescription: "1 ширхэг"
        ),
        
        // Common Generic Meals
        NutritionData(
            id: "pizza_slice",
            name: "Пицца",
            category: .custom,
            calories: 285.0,
            protein: 12.0,
            carbs: 35.0,
            fat: 12.0,
            fiber: 2.0,
            sugar: 3.0,
            servingSizeGrams: 150.0,
            servingDescription: "1 хэсэг"
        ),
        NutritionData(
            id: "burger",
            name: "Бургер",
            category: .custom,
            calories: 354.0,
            protein: 20.0,
            carbs: 35.0,
            fat: 16.0,
            fiber: 2.0,
            sugar: 6.0,
            servingSizeGrams: 200.0,
            servingDescription: "1 ширхэг"
        ),
        NutritionData(
            id: "fried_rice",
            name: "Шарсан будаа",
            category: .custom,
            calories: 250.0,
            protein: 8.0,
            carbs: 40.0,
            fat: 7.0,
            fiber: 2.0,
            sugar: 1.0,
            servingSizeGrams: 250.0,
            servingDescription: "1 таваг"
        ),
        NutritionData(
            id: "noodle_soup",
            name: "Гоймонтой шөл",
            category: .custom,
            calories: 280.0,
            protein: 12.0,
            carbs: 45.0,
            fat: 8.0,
            fiber: 2.0,
            sugar: 2.0,
            servingSizeGrams: 300.0,
            servingDescription: "1 таваг"
        ),
        NutritionData(
            id: "salad",
            name: "Салат",
            category: .custom,
            calories: 150.0,
            protein: 5.0,
            carbs: 10.0,
            fat: 8.0,
            fiber: 4.0,
            sugar: 3.0,
            servingSizeGrams: 200.0,
            servingDescription: "1 таваг"
        ),
        
        // Oils and Condiments
        NutritionData(
            id: "vegetable_oil",
            name: "Ургамалын тос",
            category: .custom,
            calories: 884.0,
            protein: 0.0,
            carbs: 0.0,
            fat: 100.0,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100мл"
        ),
        NutritionData(
            id: "soy_sauce",
            name: "Шар амтлагч",
            category: .custom,
            calories: 53.0,
            protein: 8.0,
            carbs: 5.0,
            fat: 0.0,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100мл"
        ),
        
        // More Traditional Mongolian Foods
        NutritionData(
            id: "aarts",
            name: "Аарц",
            category: .dairy,
            calories: 180.0,
            protein: 15.0,
            carbs: 8.0,
            fat: 10.0,
            fiber: 0.0,
            sugar: 8.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "tarag",
            name: "Тараг",
            category: .dairy,
            calories: 72.0,
            protein: 3.5,
            carbs: 5.0,
            fat: 4.0,
            fiber: 0.0,
            sugar: 5.0,
            servingSizeGrams: 100.0,
            servingDescription: "100мл"
        ),
        NutritionData(
            id: "boodog",
            name: "Боодог",
            category: .meat,
            calories: 320.0,
            protein: 28.0,
            carbs: 0.0,
            fat: 22.0,
            fiber: 0.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        
        // More Generic Meals
        NutritionData(
            id: "pasta",
            name: "Паста",
            category: .custom,
            calories: 158.0,
            protein: 5.8,
            carbs: 31.0,
            fat: 0.9,
            fiber: 1.8,
            sugar: 0.6,
            servingSizeGrams: 100.0,
            servingDescription: "100г буцалсан"
        ),
        NutritionData(
            id: "sandwich",
            name: "Сэндвич",
            category: .custom,
            calories: 250.0,
            protein: 12.0,
            carbs: 30.0,
            fat: 10.0,
            fiber: 2.0,
            sugar: 3.0,
            servingSizeGrams: 150.0,
            servingDescription: "1 ширхэг"
        ),
        NutritionData(
            id: "sushi_roll",
            name: "Суши",
            category: .custom,
            calories: 200.0,
            protein: 8.0,
            carbs: 35.0,
            fat: 5.0,
            fiber: 1.0,
            sugar: 2.0,
            servingSizeGrams: 100.0,
            servingDescription: "1 ширхэг"
        ),
        NutritionData(
            id: "curry_rice",
            name: "Карри будаа",
            category: .custom,
            calories: 300.0,
            protein: 10.0,
            carbs: 45.0,
            fat: 12.0,
            fiber: 3.0,
            sugar: 2.0,
            servingSizeGrams: 300.0,
            servingDescription: "1 таваг"
        ),
        
        // Snacks and Beverages
        NutritionData(
            id: "ice_cream",
            name: "Мөхөөлдөс",
            category: .snacks,
            calories: 273.0,
            protein: 4.6,
            carbs: 31.0,
            fat: 15.0,
            fiber: 0.0,
            sugar: 28.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "rice_crackers",
            name: "Будаатай хуурга",
            category: .snacks,
            calories: 387.0,
            protein: 6.0,
            carbs: 80.0,
            fat: 2.0,
            fiber: 2.0,
            sugar: 0.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "cola",
            name: "Кола",
            category: .beverages,
            calories: 42.0,
            protein: 0.0,
            carbs: 10.6,
            fat: 0.0,
            fiber: 0.0,
            sugar: 10.6,
            servingSizeGrams: 100.0,
            servingDescription: "100мл"
        ),
        NutritionData(
            id: "pringles",
            name: "Принглс",
            category: .snacks,
            calories: 536.0,
            protein: 4.0,
            carbs: 53.0,
            fat: 35.0,
            fiber: 3.0,
            sugar: 1.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        ),
        NutritionData(
            id: "snickers",
            name: "Сникерс",
            category: .snacks,
            calories: 491.0,
            protein: 7.5,
            carbs: 61.0,
            fat: 24.0,
            fiber: 2.0,
            sugar: 50.0,
            servingSizeGrams: 100.0,
            servingDescription: "100г"
        )
    ]
} 