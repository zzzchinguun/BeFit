//
//  AddMealView.swift
//  BeFit
//
//  Created by AI Assistant on 3/31/25.
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var mealName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var weight = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingStatusSheet = false
    @State private var statusMessage = ""
    @State private var isError = false
    @State private var isAutoCalculateEnabled = true
    
    // Constants for calorie calculation
    private let proteinCaloriesPerGram = 4
    private let carbsCaloriesPerGram = 4
    private let fatCaloriesPerGram = 9
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meal Details")) {
                    TextField("Meal Name", text: $mealName)
                        .autocapitalization(.words)
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                // Macros and weight section
                Section(header: macroHeaderView()) {
                    HStack {
                        Text("P")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        TextField("Protein (g)", text: $protein)
                            .keyboardType(.numberPad)
                            .onChange(of: protein) { _, _ in
                                if isAutoCalculateEnabled {
                                    calculateCalories()
                                }
                            }
                    }
                    
                    HStack {
                        Text("C")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .frame(width: 24, height: 24)
                        TextField("Carbs (g)", text: $carbs)
                            .keyboardType(.numberPad)
                            .onChange(of: carbs) { _, _ in
                                if isAutoCalculateEnabled {
                                    calculateCalories()
                                }
                            }
                    }
                    
                    HStack {
                        Text("F")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                        TextField("Fat (g)", text: $fat)
                            .keyboardType(.numberPad)
                            .onChange(of: fat) { _, _ in
                                if isAutoCalculateEnabled {
                                    calculateCalories()
                                }
                            }
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        TextField("Calories", text: $calories)
                            .keyboardType(.numberPad)
                            .disabled(isAutoCalculateEnabled)
                            .foregroundColor(isAutoCalculateEnabled ? .gray : .primary)
                    }
                    
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.purple)
                        TextField("Weight (g)", text: $weight)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Preview")) {
                    mealPreviewCard()
                }
                
                Section {
                    Button {
                        Task {
                            await addMeal()
                        }
                    } label: {
                        Text("Add Meal")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(formIsValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .statusSheet(isPresented: $showingStatusSheet, isSuccess: !isError, title: isError ? "Error" : "Success", message: statusMessage)
        }
    }
    
    private func macroHeaderView() -> some View {
        HStack {
            Text("Nutrition")
            
            Spacer()
            
            Toggle("Auto", isOn: $isAutoCalculateEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.8)
                .onChange(of: isAutoCalculateEnabled) { _, _ in
                    if isAutoCalculateEnabled {
                        calculateCalories()
                    }
                }
        }
    }
    
    private func mealPreviewCard() -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: selectedMealType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(mealTypeColor(selectedMealType))
                    .frame(width: 40, height: 40)
                    .background(mealTypeColor(selectedMealType).opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealName.isEmpty ? "Meal Name" : mealName)
                        .font(.headline)
                        .foregroundColor(mealName.isEmpty ? .gray : .primary)
                    
                    Text(selectedMealType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(calories.isEmpty ? "0" : calories) kcal")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            HStack(spacing: 12) {
                MacroCircle(value: protein.isEmpty ? "0" : protein, label: "P", color: .blue)
                MacroCircle(value: carbs.isEmpty ? "0" : carbs, label: "C", color: .green)
                MacroCircle(value: fat.isEmpty ? "0" : fat, label: "F", color: .red)
            }
            
            if !weight.isEmpty {
                Text("Weight: \(weight)g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
    
    private func calculateCalories() {
        guard let proteinValue = Int(protein), 
              let carbsValue = Int(carbs),
              let fatValue = Int(fat) else {
            calories = ""
            return
        }
        
        let calculatedCalories = (proteinValue * proteinCaloriesPerGram) +
                                (carbsValue * carbsCaloriesPerGram) +
                                (fatValue * fatCaloriesPerGram)
        
        calories = "\(calculatedCalories)"
    }
    
    private func addMeal() async {
        guard let caloriesInt = Int(calories),
              let proteinInt = Int(protein),
              let carbsInt = Int(carbs),
              let fatInt = Int(fat) else {
            statusMessage = "Please enter valid numeric values"
            isError = true
            showingStatusSheet = true
            return
        }
        
        // Parse weight if provided
        let weightValue: Double? = Double(weight)
        
        do {
            try await viewModel.addMeal(
                name: mealName,
                calories: caloriesInt,
                protein: proteinInt,
                carbs: carbsInt,
                fat: fatInt,
                mealType: selectedMealType,
                weight: weightValue
            )
            
            statusMessage = "Meal added successfully"
            isError = false
            showingStatusSheet = true
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            statusMessage = "Failed to add meal: \(error.localizedDescription)"
            isError = true
            showingStatusSheet = true
        }
    }
    
    private var formIsValid: Bool {
        return !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
              !calories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
              !protein.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
              !carbs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
              !fat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MacroCircle: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60, height: 60)
        .background(color.opacity(0.1))
        .clipShape(Circle())
    }
}

#Preview {
    AddMealView(viewModel: MealViewModel())
} 