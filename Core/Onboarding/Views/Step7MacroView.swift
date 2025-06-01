import SwiftUI
import Photos

struct Step7MacroView: View {
    @Binding var user: User
    @State private var selectedPlan = ""
    @State private var customProtein: Double = 0
    @State private var customCarbs: Double = 0
    @State private var customFat: Double = 0
    @State private var showingCustomize = false
    @State private var showingSaveSuccess = false
    @State private var saveErrorMessage: String? = nil
    @State private var showingSaveError = false
    @State private var photoDelegate: PhotoLibraryDelegate? // Store the delegate as state
    
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
                // Goal Weight Display
                if let goalWeight = user.goalWeight {
                    VStack(spacing: 10) {
                        Text("Зорилтот жин")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(String(format: "%.1f", goalWeight))")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("кг")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let currentWeight = user.weight {
                            let weightDifference = goalWeight - currentWeight
                            let isGaining = weightDifference > 0
                            
                            HStack {
                                Image(systemName: isGaining ? "arrow.up.circle" : "target")
                                    .foregroundColor(isGaining ? .blue : .green)
                                Text(isGaining ? 
                                     "\(String(format: "%.1f", abs(weightDifference))) кг нэмэх" :
                                     "\(String(format: "%.1f", abs(weightDifference))) кг хасах")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Add calorie target based on goal
                        if let currentWeight = user.weight,
                           let goalWeight = user.goalWeight,
                           let days = user.daysToComplete,
                           days > 0 {
                            
                            let weightDifference = goalWeight - currentWeight
                            let isGaining = weightDifference > 0
                            
                            // Calculate simple TDEE estimate
                            let tdeeEstimate = calculateSimpleTDEE()
                            
                            // Use EXACT SAME calculation as Step6TimelineView - no sugarcoating
                            let totalCalorieChange = weightDifference * 7700
                            let dailyCalorieChange = totalCalorieChange / Double(days)
                            let targetCalories = Int(tdeeEstimate + dailyCalorieChange)
                            
                            Divider()
                                .padding(.vertical, 5)
                            
                            VStack(spacing: 5) {
                                Text("Өдөр бүр идэх илчлэг")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("\(targetCalories) ккал")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text(isGaining ? "жин нэмэхийн тулд" : "зорилгодоо хүрэхийн тулд")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
                
                // TDEE and calculated results
                if let calculationResult = getCalculationResult() {
                    VStack(spacing: 20) {
                        // Add TypingResultCard for calculation results with typing animation
                        TypingResultCard(
                            result: calculationResult.resultString,
                            onSave: {
                                saveCalculationAsImage(calculationResult.resultString)
                            }
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Macro харьцааг сонгох")
                            .font(.headline)
                        
                        if user.macros == nil {
                            Text("• ШААРДЛАГАТАЙ")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if user.macros == nil {
                        VStack(spacing: 10) {
                            Text("👆 Доорх сонголтуудаас нэгийг сонгоно уу")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange, lineWidth: 1.5)
                                        .opacity(0.8)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    ForEach(Array(macroPlans.keys.sorted()), id: \.self) { plan in
                        if plan != "custom" {
                            MacroPlanCard(
                                planName: macroPlans[plan]!.name,
                                protein: macroPlans[plan]!.protein,
                                carbs: macroPlans[plan]!.carbs,
                                fat: macroPlans[plan]!.fat,
                                isSelected: selectedPlan == plan,
                                needsSelection: user.macros == nil
                            ) {
                                withAnimation(.spring()) {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(user.macros == nil ? Color.blue : Color.clear, lineWidth: 2)
                        )
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
        .alert("Алдаа гарлаа", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Зураг хадгалахад алдаа гарлаа")
        }
    }
    
    private func saveMacrosToPhotos() {
        guard let macros = user.macros, let tdee = calculateLocalTDEE() else { return }
        
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
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            .frame(width: 350) // Fixed width
            .background(Color.white)
        )
        
        if let uiImage = renderer.uiImage {
            // Simplified success
            showingSaveSuccess = true
        } else {
            saveErrorMessage = "Зураг үүсгэхэд алдаа гарлаа"
            showingSaveError = true
        }
    }
    
    private func calculateLocalTDEE() -> Double? {
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
        guard let tdee = calculateLocalTDEE() else { return }
        
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
    
    private func getCalculationResult() -> (resultString: String, tdee: Double)? {
        return FitnessCalculations.calculateTDEE(user: user)
    }
    
    private func saveCalculationAsImage(_ resultString: String) {
        let renderer = ImageRenderer(content: 
            VStack(alignment: .leading, spacing: 15) {
                Text("BeFit - Таны биеийн үзүүлэлт")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text(resultString)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        )
        
        renderer.scale = 3.0
        
        if let uiImage = renderer.uiImage {
            // Simplified success
            showingSaveSuccess = true
        } else {
            saveErrorMessage = "Зураг үүсгэхэд алдаа гарлаа"
            showingSaveError = true
        }
    }
    
    // MARK: - Helper Functions
    private func calculateSimpleTDEE() -> Double {
        guard let weight = user.weight,
              let height = user.height,
              let age = user.age,
              let sex = user.sex else { return 2000 }
        
        // Mifflin-St Jeor BMR calculation
        let bmr: Double
        if sex == "Male" {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        
        // Activity multiplier (default to moderate if not set)
        let activityMultiplier: Double
        switch user.activityLevel {
        case "Суугаа амьдралын хэв маяг": activityMultiplier = 1.2
        case "Хөнгөн идэвхтэй": activityMultiplier = 1.375
        case "Дунд зэрэг идэвхтэй": activityMultiplier = 1.55
        case "Идэвхтэй": activityMultiplier = 1.725
        case "Маш идэвхтэй": activityMultiplier = 1.9
        default: activityMultiplier = 1.375 // Default to lightly active
        }
        
        return bmr * activityMultiplier
    }
}

struct TypingResultCard: View {
    let result: String
    let onSave: () -> Void
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var showSaveButton = false
    @State private var typingTimer: Timer?
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(displayedText)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .id("typingText")
                        
                        if currentIndex < result.count {
                            Text("█") // Blinking cursor
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.blue)
                                .opacity(0.8)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isVisible)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onChange(of: displayedText) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typingText", anchor: .bottom)
                    }
                }
            }
            
            if showSaveButton {
                Button(action: onSave) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Зураг болгон хадгалах")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if !isVisible {
                startTypingAnimation()
                isVisible = true
            }
        }
        .onDisappear {
            stopTypingAnimation()
            isVisible = false
        }
    }
    
    private func startTypingAnimation() {
        displayedText = ""
        currentIndex = 0
        showSaveButton = false
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < result.count {
                let index = result.index(result.startIndex, offsetBy: currentIndex)
                displayedText.append(result[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        showSaveButton = true
                    }
                }
            }
        }
    }
    
    private func stopTypingAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
    }
}

struct MacroPlanCard: View {
    let planName: String
    let protein: Int
    let carbs: Int
    let fat: Int
    let isSelected: Bool
    let needsSelection: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(planName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .blue)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    } else if needsSelection {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 15) {
                    MacroPercentage(label: "P", value: protein, color: .blue, isSelected: isSelected)
                    MacroPercentage(label: "C", value: carbs, color: .green, isSelected: isSelected)
                    MacroPercentage(label: "F", value: fat, color: .yellow, isSelected: isSelected)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ? Color.clear : 
                        (needsSelection ? Color.orange.opacity(0.6) : Color.blue.opacity(0.3)), 
                        lineWidth: isSelected ? 0 : (needsSelection ? 1.5 : 1)
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
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
            Text("\(value)%")
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : color)
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
                    if let tdee = calculateCustomTDEE() {
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
                        Text("Нийт 100% болгохыг анхаарна у")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Өөрийн macro тохируулах")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Буцах") {
                        showingCustomize = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Хадгалах") {
                        saveCustomMacros()
                        showingCustomize = false
                    }
                    .disabled(protein + carbs + fat != 100)
                }
            }
        }
    }
    
    private func calculateCustomTDEE() -> Double? {
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
        guard let tdee = calculateCustomTDEE() else { return }
        
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
            
            HStack(spacing: 15) {
                Button(action: {
                    if value > 0 {
                        value = max(0, value - 5)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 5) {
                    Slider(value: $value, in: 0...100, step: 5)
                        .accentColor(color)
                        .frame(height: 44)
                    
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("50%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("100%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    if value < 100 {
                        value = min(100, value + 5)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(color)
                }
            }
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

