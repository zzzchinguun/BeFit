import SwiftUI

struct Step7MacroView: View {
    @Binding var user: User
    @State private var selectedPlan = "balanced"
    @State private var customProtein: Double = 0
    @State private var customCarbs: Double = 0
    @State private var customFat: Double = 0
    @State private var showingCustomize = false
    
    let macroPlans = [
        "balanced": (protein: 30, carbs: 40, fat: 30),
        "lowCarb": (protein: 40, carbs: 20, fat: 40),
        "highProtein": (protein: 40, carbs: 40, fat: 20),
        "ketogenic": (protein: 30, carbs: 10, fat: 60),
        "custom": (protein: 0, carbs: 0, fat: 0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // TDEE Display
                if let tdee = calculateTDEE() {
                    VStack(spacing: 10) {
                        Text("Daily Calorie Target")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(Int(tdee))")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("calories")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
                
                // Macro Plan Selection
                VStack(alignment: .leading, spacing: 15) {
                    Text("Choose Your Macro Split")
                        .font(.headline)
                    
                    ForEach(Array(macroPlans.keys.sorted()), id: \.self) { plan in
                        if plan != "custom" {
                            MacroPlanCard(
                                planName: plan,
                                protein: macroPlans[plan]!.protein,
                                carbs: macroPlans[plan]!.carbs,
                                fat: macroPlans[plan]!.fat,
                                isSelected: selectedPlan == plan
                            ) {
                                withAnimation {
                                    selectedPlan = plan
                                    updateUserMacros(plan: plan)
                                }
                            }
                        }
                    }
                    
                    // Custom Plan Button
                    Button {
                        showingCustomize = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Customize Macros")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                
                // Macro Breakdown
                if let macros = user.macros {
                    VStack(spacing: 15) {
                        Text("Daily Macro Targets")
                            .font(.headline)
                        
                        MacroBreakdownRow(
                            title: "Protein",
                            amount: Double(macros.protein),
                            color: .blue,
                            icon: "figure.strengthtraining.traditional"
                        )
                        
                        MacroBreakdownRow(
                            title: "Carbs",
                            amount: Double(macros.carbs),
                            color: .green,
                            icon: "leaf.fill"
                        )
                        
                        MacroBreakdownRow(
                            title: "Fat",
                            amount: Double(macros.fat),
                            color: .yellow,
                            icon: "drop.fill"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingCustomize) {
            CustomMacrosView(user: $user, showingCustomize: $showingCustomize)
        }
    }
    
    private func calculateTDEE() -> Double? {
        // Implement TDEE calculation based on user's data
        guard let weight = user.weight,
              let height = user.height,
              let age = user.age,
              let activityLevel = user.activityLevel else { return nil }
        
        // Basic BMR calculation using Harris-Benedict equation
        let bmr: Double
        if user.sex == "Male" {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        // Activity multiplier
        let activityMultiplier: Double
        switch activityLevel {
        case "Sedentary": activityMultiplier = 1.2
        case "Lightly Active": activityMultiplier = 1.375
        case "Moderately Active": activityMultiplier = 1.55
        case "Very Active": activityMultiplier = 1.725
        case "Extra Active": activityMultiplier = 1.9
        default: activityMultiplier = 1.2
        }
        
        return bmr * activityMultiplier
    }
    
    private func updateUserMacros(plan: String) {
        guard let tdee = calculateTDEE() else { return }
        
        let macroSplit = macroPlans[plan]!
        let proteinCals = tdee * Double(macroSplit.protein) / 100
        let carbsCals = tdee * Double(macroSplit.carbs) / 100
        let fatCals = tdee * Double(macroSplit.fat) / 100
        
        user.macros = Macros(
            protein: Int(proteinCals / 4), // 4 calories per gram of protein
            carbs: Int(carbsCals / 4),     // 4 calories per gram of carbs
            fat: Int(fatCals / 9)          // 9 calories per gram of fat
        )
    }
}

struct MacroPlanCard: View {
    let planName: String
    let protein: Int
    let carbs: Int
    let fat: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(planName.capitalized)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 15) {
                    MacroPercentage(label: "P", value: protein, color: .blue)
                    MacroPercentage(label: "C", value: carbs, color: .green)
                    MacroPercentage(label: "F", value: fat, color: .yellow)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacroPercentage: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text("\(value)%")
                .font(.subheadline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroBreakdownRow: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(amount))g")
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct CustomMacrosView: View {
    @Binding var user: User
    @Binding var showingCustomize: Bool
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    
    init(user: Binding<User>, showingCustomize: Binding<Bool>) {
        self._user = user
        self._showingCustomize = showingCustomize
        
        // Initialize protein, carbs, and fat with current values or defaults
        let currentMacros = user.wrappedValue.macros
        self._protein = State(initialValue: Double(currentMacros?.protein ?? 0))
        self._carbs = State(initialValue: Double(currentMacros?.carbs ?? 0))
        self._fat = State(initialValue: Double(currentMacros?.fat ?? 0))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // TDEE Display
                    if let tdee = calculateTDEE() {
                        VStack(spacing: 5) {
                            Text("Daily Calories")
                                .font(.headline)
                            Text("\(Int(tdee))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    
                    // Macro Sliders
                    VStack(spacing: 20) {
                        MacroSlider(
                            title: "Protein",
                            value: $protein,
                            color: .blue,
                            icon: "figure.strengthtraining.traditional"
                        )
                        
                        MacroSlider(
                            title: "Carbs",
                            value: $carbs,
                            color: .green,
                            icon: "leaf.fill"
                        )
                        
                        MacroSlider(
                            title: "Fat",
                            value: $fat,
                            color: .yellow,
                            icon: "drop.fill"
                        )
                    }
                    .padding()
                    
                    // Total Percentage
                    let total = protein + carbs + fat
                    Text("Total: \(Int(total))%")
                        .font(.headline)
                        .foregroundColor(total == 100 ? .green : .red)
                    
                    if total != 100 {
                        Text("Adjust values to total 100%")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Custom Macros")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingCustomize = false
                },
                trailing: Button("Save") {
                    saveCustomMacros()
                    showingCustomize = false
                }
                .disabled(protein + carbs + fat != 100)
            )
        }
    }
    
    private func calculateTDEE() -> Double? {
        guard let weight = user.weight,
              let height = user.height,
              let age = user.age,
              let activityLevel = user.activityLevel else { return nil }
        
        let bmr: Double
        if user.sex == "Male" {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        let activityMultiplier: Double
        switch activityLevel {
        case "Sedentary": activityMultiplier = 1.2
        case "Lightly Active": activityMultiplier = 1.375
        case "Moderately Active": activityMultiplier = 1.55
        case "Very Active": activityMultiplier = 1.725
        case "Extra Active": activityMultiplier = 1.9
        default: activityMultiplier = 1.2
        }
        
        return bmr * activityMultiplier
    }
    
    private func saveCustomMacros() {
        guard let tdee = calculateTDEE() else { return }
        
        let proteinCals = tdee * protein / 100
        let carbsCals = tdee * carbs / 100
        let fatCals = tdee * fat / 100
        
        user.macros = Macros(
            protein: Int(proteinCals / 4),
            carbs: Int(carbsCals / 4),
            fat: Int(fatCals / 9)
        )
    }
}

struct MacroSlider: View {
    let title: String
    @Binding var value: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                Spacer()
                Text("\(Int(value))%")
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: 0...100, step: 5)
                .accentColor(color)
        }
    }
}

#Preview {
    Step7MacroView(user: .constant(User(id: "", firstName: "", lastName: "", email: "")))
}
