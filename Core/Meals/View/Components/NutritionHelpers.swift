//
//  NutritionHelpers.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import SwiftUI

// MARK: - Global Helper Functions

/// Global function for category colors that can be accessed by all structs
func categoryColor(_ category: FoodCategory) -> Color {
    switch category {
    case .meat: return Color.accentApp
    case .dairy: return Color.infoApp
    case .grains: return Color.warningApp
    case .fruits: return Color.successApp
    case .vegetables: return Color.primaryApp
    case .nuts: return Color.warningApp
    case .beverages: return Color.infoApp
    case .snacks: return Color.accentApp
    case .custom: return Color.primaryApp
    }
}

/// Helper function for meal type colors
func mealTypeColor(_ mealType: MealType) -> Color {
    switch mealType {
    case .breakfast: return Color.warningApp
    case .lunch: return Color.infoApp
    case .dinner: return Color.accentApp
    case .snack: return Color.successApp
    }
} 
