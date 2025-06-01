//
//  Meal.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/31/25.
//

import Foundation
import FirebaseFirestore

struct Meal: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let date: Date
    let mealType: MealType
    let weight: Double? // Weight in grams
    
    var macrosTotal: Int {
        return protein + carbs + fat
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Өглөөний цай"
    case lunch = "Өдрийн хоол"
    case dinner = "Оройн хоол"
    case snack = "Хөнгөн зууш"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "sunset.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}

extension Meal {
    static var MOCK_MEALS: [Meal] = [
        Meal(
            id: NSUUID().uuidString,
            userId: "user123",
            name: "Oatmeal with Berries",
            calories: 350,
            protein: 12,
            carbs: 60,
            fat: 7,
            date: Date(),
            mealType: .breakfast,
            weight: 100
        ),
        Meal(
            id: NSUUID().uuidString,
            userId: "user123",
            name: "Chicken Salad",
            calories: 420,
            protein: 35,
            carbs: 15,
            fat: 22,
            date: Date(),
            mealType: .lunch,
            weight: 100
        ),
        Meal(
            id: NSUUID().uuidString,
            userId: "user123",
            name: "Salmon with Vegetables",
            calories: 520,
            protein: 40,
            carbs: 25,
            fat: 25,
            date: Date(),
            mealType: .dinner,
            weight: 100
        )
    ]
} 
