import SwiftUI

struct Step7MacroView: View {
    @Binding var user: User
    @State private var selectedPlan = "balanced"
    @State private var customProtein: Double = 0
    @State private var customCarbs: Double = 0
    @State private var customFat: Double = 0
    @State private var showingCustomize = false
    @State private var showingSaveSuccess = false
    
    let macroPlans = [
        "balanced": (name: "Тэнцвэртэй", protein: 30, carbs: 40, fat: 30),
        "lowCarb": (name: "Бага нүүрс ус", protein: 40, carbs: 20, fat: 40),
        "highProtein": (name: "Өндөр уураг", protein: 40, carbs: 40, fat: 20),
        "ketogenic": (name: "Кето", protein: 30, carbs: 10, fat: 60),
        "custom": (name: "Өөрийн", protein: 0, carbs: 0, fat: 0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                if let tdee = calculateTDEE() {
                    VStack(spacing: 10) {
                        Text("Өдрийн илчлэгийн зорилт")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(Int(tdee))")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("ккал")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Macro харьцааг сонгох")
                        .font(.headline)
                    
                    ForEach(Array(macroPlans.keys.sorted()), id: \.self) { plan in
                        if plan != "custom" {
                            MacroPlanCard(
                                planName: macroPlans[plan]!.name,
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
                    
                    Button {
                        showingCustomize = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Өөрийн macro тохируулах")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                
                if let macros = user.macros {
                    VStack(spacing: 15) {
                        Text("Өдрийн macro зорилт")
                            .font(.headline)
                        
                        MacroBreakdownRow(
                            title: "Уураг",
                            amount: Double(macros.protein),
                            color: .blue,
                            icon: "figure.strengthtraining.traditional"
                        )
                        
                        MacroBreakdownRow(
                            title: "Нүүрс ус",
                            amount: Double(macros.carbs),
                            color: .green,
                            icon: "leaf.fill"
                        )
                        
                        MacroBreakdownRow(
                            title: "Өөх тос",
                            amount: Double(macros.fat),
                            color: .yellow,
                            icon: "drop.fill"
                        )
                        
                        Button(action: saveMacrosToPhotos) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Зурган файлаар хадгалах")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
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
                .presentationDetents([.fraction(0.8)])
        }
        .alert("Амжилттай", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Зураг амжилттай хадгалагдлаа")
        }
    }
    
    private func saveMacrosToPhotos() {
        guard let macros = user.macros, let tdee = calculateTDEE() else { return }
        
        let renderer = ImageRenderer(content:
            VStack(spacing: 20) {
                Text("BeFit - Таны Macro Зорилтууд")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 15) {
                    Text("Өдрийн илчлэг: \(Int(tdee)) ккал")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        MacroRow(name: "Уураг", amount: macros.protein, color: .blue)
                        MacroRow(name: "Нүүрс ус", amount: macros.carbs, color: .green)
                        MacroRow(name: "Өөх тос", amount: macros.fat, color: .yellow)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(Color(.systemBackground))
        )
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingSaveSuccess = true
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
    
    private func updateUserMacros(plan: String) {
        guard let tdee = calculateTDEE() else { return }
        
        let macroSplit = macroPlans[plan]!
        let proteinCals = tdee * Double(macroSplit.protein) / 100
        let carbsCals = tdee * Double(macroSplit.carbs) / 100
        let fatCals = tdee * Double(macroSplit.fat) / 100
        
        user.macros = Macros(
            protein: Int(proteinCals / 4),
            carbs: Int(carbsCals / 4),
            fat: Int(fatCals / 9)
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
                    Text(planName)
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
            
            Text("\(Int(amount))г")
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
        
        let currentMacros = user.wrappedValue.macros
        self._protein = State(initialValue: Double(currentMacros?.protein ?? 0))
        self._carbs = State(initialValue: Double(currentMacros?.carbs ?? 0))
        self._fat = State(initialValue: Double(currentMacros?.fat ?? 0))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    if let tdee = calculateTDEE() {
                        VStack(spacing: 5) {
                            Text("Өдрийн илчлэг")
                                .font(.headline)
                            Text("\(Int(tdee))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 20) {
                        MacroSlider(
                            title: "Уураг",
                            value: $protein,
                            color: .blue,
                            icon: "figure.strengthtraining.traditional"
                        )
                        
                        MacroSlider(
                            title: "Нүүрс ус",
                            value: $carbs,
                            color: .green,
                            icon: "leaf.fill"
                        )
                        
                        MacroSlider(
                            title: "Өөх тос",
                            value: $fat,
                            color: .yellow,
                            icon: "drop.fill"
                        )
                    }
                    .padding()
                    
                    let total = protein + carbs + fat
                    Text("Нийт: \(Int(total))%")
                        .font(.headline)
                        .foregroundColor(total == 100 ? .green : .red)
                    
                    if total != 100 {
                        Text("Утга зүйг 100% болгохыг хүснэ")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Өөрийн macro тохируулах")
            .navigationBarItems(
                leading: Button("Буцах") {
                    showingCustomize = false
                },
                trailing: Button("Хадгалах") {
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

struct MacroRow: View {
    let name: String
    let amount: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.primary)
            Spacer()
            Text("\(amount)г")
                .foregroundColor(color)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    Step7MacroView(user: .constant(User(id: "", firstName: "", lastName: "", email: "")))
}
