//
//  ModernUIComponents.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import SwiftUI

// MARK: - Modern Macro Chip
struct ModernMacroChip: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 28, height: 28)
        .background(
            Circle()
                .fill(color.opacity(0.15))
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Modern Food Stats Row
struct ModernFoodStatsRow: View {
    let totalFoods: Int
    let filteredCount: Int
    let selectedCategory: FoodCategory?
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: isEnglishLanguage ? "Total" : "Нийт",
                value: "\(totalFoods)",
                icon: "fork.knife",
                color: Color.primaryApp
            )
            
            StatCard(
                title: isEnglishLanguage ? "Showing" : "Харагдаж буй",
                value: "\(filteredCount)",
                icon: "eye",
                color: Color.infoApp
            )
            
            if let category = selectedCategory {
                StatCard(
                    title: isEnglishLanguage ? "Category" : "Ангилал",
                    value: String(category.rawValue.prefix(8)),
                    icon: category.icon,
                    color: categoryColor(category)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
} 