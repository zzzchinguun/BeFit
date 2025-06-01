//
//  MealRowView.swift
//  BeFit
//
// 
//

import SwiftUI
import Foundation

// MARK: - Main Component
struct MealRowView: View {
    let meal: Meal
    @ObservedObject var viewModel: MealViewModel
    var onDelete: () -> Void = {}
    
    // Instead of per-row state, we'll use a reference to the parent's expanded state
    @Binding var expandedMealId: String?
    @State private var showEditSheet = false
    
    // Computed property to check if this meal is expanded
    private var isExpanded: Bool {
        guard let mealId = meal.id else { return false }
        return expandedMealId == mealId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row - Always visible
            Button(action: {
                // Toggle expansion with proper animation scope and safety check
                guard let mealId = meal.id else { return }
                
                // Add small delay to prevent rapid tapping issues
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedMealId = nil
                        } else {
                            expandedMealId = mealId
                        }
                    }
                }
            }) {
                HStack(spacing: 16) {
                    // Meal type icon
                    ZStack {
                        Circle()
                            .fill(mealTypeColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: meal.mealType.icon)
                            .font(.system(size: 22))
                            .foregroundColor(mealTypeColor)
                    }
                    
                    // Meal info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(formatDate(meal.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Calories
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(meal.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Калори")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .bold))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Details
            if isExpanded {
                ExpandedDetailsView(
                    meal: meal,
                    showEditSheet: $showEditSheet,
                    onDelete: onDelete
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .clipped() // Prevent overflow during animation
        // Handle the edit sheet
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                MealEditView(meal: meal, onSave: { updatedMeal in
                    Task {
                        do {
                            try await viewModel.updateMeal(updatedMeal)
                        } catch {
                            print("Error updating meal: \(error.localizedDescription)")
                        }
                    }
                    showEditSheet = false
                })
                .navigationTitle("Хоол засах")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Хаах") {
                        showEditSheet = false
                    }
                )
            }
            .presentationDetents([.fraction(0.99), .medium, .large])
        }
    }
    
    // Computed properties for cleaner code
    private var mealTypeColor: Color {
        switch meal.mealType {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Separate view for expanded details to improve performance
struct ExpandedDetailsView: View {
    let meal: Meal
    @Binding var showEditSheet: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .opacity(0.5)
            
            // Macros details in a separate scrollable area
            HStack(spacing: 12) {
                MacroDetail(value: meal.protein, name: "Уураг", color: .blue, icon: "p.circle.fill")
                MacroDetail(value: meal.carbs, name: "Нүүрс ус", color: .green, icon: "c.circle.fill")
                MacroDetail(value: meal.fat, name: "Өөх тос", color: .red, icon: "f.circle.fill")
            }
            
            HStack {
                Spacer()
                
                // Edit button
                Button(action: { showEditSheet = true }) {
                    Label("Засах", systemImage: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 8)
                
                // Delete button
                Button(action: onDelete) {
                    Label("Устгах", systemImage: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }
}

// Keep MacroDetail as a simple, stateless view
struct MacroDetail: View {
    let value: Int
    let name: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text("\(value)г")
                .font(.headline)
                .foregroundColor(color)
            
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(name)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

#Preview {
    // For preview purposes, we need a static binding
    let previewBinding = Binding<String?>(
        get: { nil },
        set: { _ in }
    )
    
    MealRowView(
        meal: Meal.MOCK_MEALS[0], 
        viewModel: MealViewModel(),
        expandedMealId: previewBinding
    )
    .padding()
    .previewLayout(.sizeThatFits)
} 
