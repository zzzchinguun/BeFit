import SwiftUI

struct Step6TimelineView: View {
    @Binding var user: User
    @State private var selectedMetric = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Goal Weight Section
                VStack(spacing: 20) {
                    Text("Зорилтот жин")
                        .font(.headline)
                    
                    // Metric Toggle
                    Picker("Систем", selection: $selectedMetric) {
                        Text("Метрийн (кг)").tag(true)
                        Text("Империал (фунт)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    // Weight Selection
                    VStack(spacing: 15) {
                        if selectedMetric {
                            // Metric Weight
                            HStack {
                                Text("Зорилт:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(String(format: "%.1f", user.goalWeight ?? user.weight ?? 70)) кг")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    let current = user.goalWeight ?? user.weight ?? 70
                                    if current > 40 {
                                        user.goalWeight = current - 0.5
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(spacing: 5) {
                                    Slider(
                                        value: Binding(
                                            get: { user.goalWeight ?? user.weight ?? 70 },
                                            set: { user.goalWeight = $0 }
                                        ),
                                        in: 40...200,
                                        step: 0.5
                                    )
                                    .accentColor(.blue)
                                    .frame(height: 44)
                                    
                                    HStack {
                                        Text("40кг")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("120кг")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("200кг")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: {
                                    let current = user.goalWeight ?? user.weight ?? 70
                                    if current < 200 {
                                        user.goalWeight = current + 0.5
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if let currentWeight = user.weight, let goalWeight = user.goalWeight {
                                let difference = goalWeight - currentWeight
                                HStack {
                                    Image(systemName: difference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(difference > 0 ? .green : .blue)
                                    Text("\(abs(difference), specifier: "%.1f") кг \(difference > 0 ? "нэмэх" : "хасах")")
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            // Imperial Weight
                            let goalLbs = Binding(
                                get: { Int((user.goalWeight ?? user.weight ?? 70) * 2.20462) },
                                set: { user.goalWeight = Double($0) / 2.20462 }
                            )
                            
                            HStack {
                                Text("Зорилт:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(goalLbs.wrappedValue) фунт")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if goalLbs.wrappedValue > 88 {
                                        goalLbs.wrappedValue -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(spacing: 5) {
                                    Slider(
                                        value: Binding(
                                            get: { Double(goalLbs.wrappedValue) },
                                            set: { goalLbs.wrappedValue = Int($0) }
                                        ),
                                        in: 88...440,
                                        step: 1
                                    )
                                    .accentColor(.blue)
                                    .frame(height: 44)
                                    
                                    HStack {
                                        Text("88lbs")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("264lbs")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("440lbs")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: {
                                    if goalLbs.wrappedValue < 440 {
                                        goalLbs.wrappedValue += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if let currentWeight = user.weight, let goalWeight = user.goalWeight {
                                let differenceLbs = Int((goalWeight - currentWeight) * 2.20462)
                                HStack {
                                    Image(systemName: differenceLbs > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(differenceLbs > 0 ? .green : .blue)
                                    Text("\(abs(differenceLbs)) фунт \(differenceLbs > 0 ? "нэмэх" : "хасах")")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(15)
                
                // Timeline Section
                VStack(spacing: 20) {
                    Text("Зорилгынхоо хугацаа")
                        .font(.headline)
                    
                    let days = Binding(
                        get: { user.daysToComplete ?? 90 },
                        set: { user.daysToComplete = $0 }
                    )
                    
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            Button(action: {
                                if days.wrappedValue > 30 {
                                    days.wrappedValue -= 7 // Week increments for easier adjustment
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 5) {
                                Slider(value: Binding(
                                    get: { Double(days.wrappedValue) },
                                    set: { days.wrappedValue = Int($0) }
                                ), in: 30...365, step: 1)
                                .accentColor(.blue)
                                .frame(height: 44)
                                
                                HStack {
                                    Text("30 өдөр")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("6 сар")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("1 жил")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                if days.wrappedValue < 365 {
                                    days.wrappedValue += 7 // Week increments for easier adjustment
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        VStack(spacing: 5) {
                            Text("\(days.wrappedValue) өдөр")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("≈ \(Int(Double(days.wrappedValue) / 7)) долоо хоног")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Daily Calorie Goal Display
                    if let currentWeight = user.weight,
                       let goalWeight = user.goalWeight,
                       let days = user.daysToComplete,
                       days > 0 {
                        
                        let weightDifference = goalWeight - currentWeight
                        let isGaining = weightDifference > 0
                        let targetCalories = calculateTargetCalories(
                            currentWeight: currentWeight,
                            goalWeight: goalWeight,
                            days: days
                        )
                        
                        VStack(spacing: 10) {
                            Divider()
                                .padding(.vertical, 5)
                            
                            Text("Өдрийн калорийн зорилт")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text("\(targetCalories) ккал")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(isGaining ? .green : .orange)
                            
                            Text(isGaining ? "жин нэмэхийн тулд" : "жин хасахын тулд")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // Weekly progress indicator
                            let weeklyChange = weightDifference / (Double(days) / 7)
                            HStack {
                                Image(systemName: abs(weeklyChange) <= 0.75 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(abs(weeklyChange) <= 0.75 ? .green : .orange)
                                
                                Text("Долоо хоногт \(String(format: "%.1f", abs(weeklyChange))) кг")
                                    .font(.subheadline)
                                    .foregroundColor(abs(weeklyChange) <= 0.75 ? .green : .orange)
                            }
                            
                            if abs(weeklyChange) > 0.75 {
                                Text("Эрүүл хасалт: 7 хоногт 0.25-0.75кг")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.top, 2)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(15)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
            }
            .padding()
        }
        .animation(.easeInOut, value: selectedMetric)
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
    
    private func getCalculationResult() -> (resultString: String, tdee: Double)? {
        return FitnessCalculations.calculateTDEE(user: user)
    }
    
    private func calculateTargetCalories(currentWeight: Double, goalWeight: Double, days: Int) -> Int {
        let weightDifference = goalWeight - currentWeight
        let isGaining = weightDifference > 0
        
        // Simple TDEE calculation for preview
        let tdeeEstimate = calculateSimpleTDEE()
        
        // Use accurate calculation that matches Legion Athletics method
        let totalCalorieChange = weightDifference * 7700
        let dailyCalorieChange = totalCalorieChange / Double(days)
        let targetCalories = Int(tdeeEstimate + dailyCalorieChange)
        
        return targetCalories
    }
}

#Preview {
    Step6TimelineView(user: .constant(User.MOCK_USER))
}
