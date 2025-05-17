//
//  MealRowView.swift
//  BeFit
//
//  Created by AI Assistant on 3/31/25.
//

import SwiftUI

struct MealRowView: View {
    let meal: Meal
    @ObservedObject var viewModel: MealViewModel
    var onDelete: () -> Void = {}
    @State private var showDetails = false
    @State private var showEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDetails.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    // Meal type icon
                    ZStack {
                        Circle()
                            .fill(mealTypeColor(meal.mealType).opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: meal.mealType.icon)
                            .font(.system(size: 22))
                            .foregroundColor(mealTypeColor(meal.mealType))
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
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .bold))
                        .animation(.spring(), value: showDetails)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
            
            // Expanded details
            if showDetails {
                VStack(spacing: 16) {
                    Divider()
                        
                    
                    // Macros details
                    HStack(spacing: 12) {
                        MacroDetail(value: meal.protein, name: "Уураг", color: .blue, icon: "p.circle.fill")
                        MacroDetail(value: meal.carbs, name: "Нүүрс ус", color: .green, icon: "c.circle.fill")
                        MacroDetail(value: meal.fat, name: "Өөх тос", color: .red, icon: "f.circle.fill")
                    }
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showEditSheet = true
                        }) {
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
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
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
    
    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
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
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MealRowView(meal: Meal.MOCK_MEALS[0], viewModel: MealViewModel())
        .padding()
        .previewLayout(.sizeThatFits)
} 
