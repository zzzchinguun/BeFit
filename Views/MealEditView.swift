//
//  MealEditView.swift
//  BeFit
//
//  Created by AI Assistant on 5/2/25.
//

import SwiftUI

struct MealEditView: View {
    let meal: Meal
    var onSave: (Meal) -> Void
    
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var weight: String
    @State private var mealType: MealType
    @State private var date: Date
    
    init(meal: Meal, onSave: @escaping (Meal) -> Void) {
        self.meal = meal
        self.onSave = onSave
        
        // Initialize state with meal values
        _name = State(initialValue: meal.name)
        _calories = State(initialValue: String(meal.calories))
        _protein = State(initialValue: String(meal.protein))
        _carbs = State(initialValue: String(meal.carbs))
        _fat = State(initialValue: String(meal.fat))
        _weight = State(initialValue: meal.weight != nil ? String(meal.weight!) : "")
        _mealType = State(initialValue: meal.mealType)
        _date = State(initialValue: meal.date)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Хоолны мэдээлэл")) {
                TextField("Нэр", text: $name)
                
                Picker("Төрөл", selection: $mealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(getMealTypeColor(type))
                            Text(type.rawValue)
                        }
                        .tag(type)
                    }
                }
                
                DatePicker("Огноо", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section(header: Text("Тэжээллэг чанар")) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    TextField("Калори", text: $calories)
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Image(systemName: "p.circle.fill")
                        .foregroundColor(.blue)
                    TextField("Уураг (г)", text: $protein)
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Image(systemName: "c.circle.fill")
                        .foregroundColor(.green)
                    TextField("Нүүрс ус (г)", text: $carbs)
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Image(systemName: "f.circle.fill")
                        .foregroundColor(.red)
                    TextField("Өөх тос (г)", text: $fat)
                        .keyboardType(.numberPad)
                }
                
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.gray)
                    TextField("Жин (г)", text: $weight)
                        .keyboardType(.decimalPad)
                }
            }
        }
        Button(action: saveChanges) {
            Text("Хадгалах")
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
    
    private func saveChanges() {
        let updatedMeal = Meal(
            id: meal.id,
            userId: meal.userId,
            name: name,
            calories: Int(calories) ?? 0,
            protein: Int(protein) ?? 0,
            carbs: Int(carbs) ?? 0,
            fat: Int(fat) ?? 0,
            date: date,
            mealType: mealType,
            weight: Double(weight)
        )
        
        onSave(updatedMeal)
    }
    
    private func getMealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

#Preview {
    MealEditView(meal: Meal.MOCK_MEALS[0], onSave: { _ in })
} 
