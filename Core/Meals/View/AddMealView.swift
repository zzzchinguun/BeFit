//
//  AddMealView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/31/25.
//

import SwiftUI

struct AddMealView: View {
    @ObservedObject var viewModel: MealViewModel
    @Environment(\.dismiss) private var dismiss
    var onInputFocus: ()-> Void
    @State private var mealName = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var weight = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var showingStatusSheet = false
    @State private var statusMessage = ""
    @State private var isError = false
    
    // Constants for calorie calculation
    private let proteinCaloriesPerGram = 4
    private let carbsCaloriesPerGram = 4
    private let fatCaloriesPerGram = 9
    
    // Calculated calories based on macros (4 cal/g protein, 4 cal/g carbs, 9 cal/g fat)
    private var calculatedCalories: Int {
        let proteinValue = Double(protein) ?? 0
        let carbsValue = Double(carbs) ?? 0
        let fatValue = Double(fat) ?? 0
        
        return Int((proteinValue * 4) + (carbsValue * 4) + (fatValue * 9))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Хоолны Дэлгэрэнгүй")) {
                    TextField("Хоолны Нэр", text: $mealName)
                        .autocapitalization(.words)
                        .simultaneousGesture(TapGesture().onEnded{
                            onInputFocus()
                        })
                    Picker("Хоолны Төрөл", selection: $selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .onTapGesture {
                        onInputFocus()
                    }
                }
                
                // Macros and weight section
                Section(header: macroHeaderView()) {
                    HStack {
                        Text("У")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .frame(width: 16, height: 24)
                        TextField("Уураг (г)", text: $protein)
                            .keyboardType(.numberPad)
                            .onTapGesture {
                                onInputFocus()
                            }
                    }
                    
                    HStack {
                        Text("Н")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .frame(width: 16, height: 24)
                        TextField("Нүүрс ус (г)", text: $carbs)
                            .keyboardType(.numberPad)
                            .onTapGesture {
                                onInputFocus()
                            }
                    }
                    
                    HStack {
                        Text("Ө")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(width: 16, height: 24)
                        TextField("Өөх тос (г)", text: $fat)
                            .keyboardType(.numberPad)
                            .onTapGesture {
                                onInputFocus()
                            }
                    }
                    
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundColor(.purple)
                            .frame(width: 16, height: 24)
                        TextField("Жин (г)", text: $weight)
                            .keyboardType(.decimalPad)
                            .onTapGesture {
                                onInputFocus()
                            }
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .frame(width: 16, height: 24)
                        Text("\(calculatedCalories)")
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("ккал (автомат тооцоо)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    
                }
                
                Section(header: Text("Урьдчилан Харах")) {
                    mealPreviewCard()
                }
            }
            Button {
                Task {
                    await addMeal()
                }
            } label: {
                Text("Хоол Нэмэх")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .background(formIsValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
            }
            .disabled(!formIsValid)
            .navigationTitle("Хоол Нэмэх")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Цуцлах") {
                        dismiss()
                    }
                }
            }
            .statusSheet(isPresented: $showingStatusSheet, isSuccess: !isError, title: isError ? "Алдаа" : "Амжилттай", message: statusMessage)
        }
    }
    
    private func macroHeaderView() -> some View {
        HStack {
            Text("Тэжээллэг чанар")
            Spacer()
        }
    }
    
    private func mealPreviewCard() -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: selectedMealType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(mealTypeColor(selectedMealType))
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mealName.isEmpty ? "Хоолны Нэр" : mealName)
                        .font(.headline)
                        .foregroundColor(mealName.isEmpty ? .gray : .primary)
                    
                    Text(selectedMealType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(calculatedCalories) ккал")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            HStack(spacing: 12) {
                MacroCircle(value: protein.isEmpty ? "0" : protein, label: "У", color: .blue)
                Spacer()
                MacroCircle(value: carbs.isEmpty ? "0" : carbs, label: "Н", color: .green)
                Spacer()
                MacroCircle(value: fat.isEmpty ? "0" : fat, label: "Ө", color: .red)
            }
            
            if !weight.isEmpty {
                Text("Жин: \(weight)г")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
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
    
    private func addMeal() async {
        guard !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !protein.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !carbs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !fat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let proteinInt = Int(protein),
              let carbsInt = Int(carbs),
              let fatInt = Int(fat) else {
            statusMessage = "Зөв тоон утга оруулна уу"
            isError = true
            showingStatusSheet = true
            return
        }
        
        // Parse weight if provided
        let weightValue: Double? = Double(weight)
        
        do {
            try await viewModel.addMeal(
                name: mealName,
                calories: calculatedCalories,
                protein: proteinInt,
                carbs: carbsInt,
                fat: fatInt,
                mealType: selectedMealType,
                weight: weightValue
            )
            
            statusMessage = "Хоол амжилттай нэмэгдлээ"
            isError = false
            showingStatusSheet = true
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            statusMessage = "Хоол нэмэхэд алдаа гарлаа: \(error.localizedDescription)"
            isError = true
            showingStatusSheet = true
        }
    }
    
    private var formIsValid: Bool {
        return !mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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
            
            Text("г")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60, height: 60)
        .background(color.opacity(0.1))
        .clipShape(Circle())
    }
}

#Preview {
    AddMealView(viewModel: MealViewModel(), onInputFocus: {})
}
