import SwiftUI

struct Step3HeightWeightView: View {
    @Binding var user: User
    @State private var selectedMetric = true // true for metric, false for imperial
    
    // State for picker values
    @State private var heightCm: Int = 170
    @State private var weightKg: Double = 70.0
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var weightLbs: Int = 154
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Metric Toggle
                Picker("Систем", selection: $selectedMetric) {
                    Text("см/кг").tag(true)
                    Text("фут/фунт").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Height Input
                VStack(spacing: 15) {
                    Text("Өндөр")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if selectedMetric {
                        // Metric Height Picker
                        VStack(spacing: 10) {
                            Text("\(heightCm) см")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if heightCm > 140 {
                                        heightCm -= 1
                                        user.height = Double(heightCm)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                Picker("Өндөр", selection: $heightCm) {
                                    ForEach(140...220, id: \.self) { height in
                                        Text("\(height) см").tag(height)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 80)
                                .clipped()
                                .onChange(of: heightCm) { _, newValue in
                                    user.height = Double(newValue)
                                }
                                
                                Button(action: {
                                    if heightCm < 220 {
                                        heightCm += 1
                                        user.height = Double(heightCm)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        // Imperial Height Picker
                        VStack(spacing: 10) {
                            Text("\(heightFeet)' \(heightInches)\"")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            HStack(spacing: 15) {
                                VStack {
                                    Text("Фут")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Фут", selection: $heightFeet) {
                                        ForEach(4...7, id: \.self) { ft in
                                            Text("\(ft)").tag(ft)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 70, height: 80)
                                    .clipped()
                                }
                                
                                VStack {
                                    Text("Инч")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Инч", selection: $heightInches) {
                                        ForEach(0...11, id: \.self) { inch in
                                            Text("\(inch)").tag(inch)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 70, height: 80)
                                    .clipped()
                                }
                            }
                            .onChange(of: heightFeet) { _, _ in updateHeightFromImperial() }
                            .onChange(of: heightInches) { _, _ in updateHeightFromImperial() }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Weight Input
                VStack(spacing: 15) {
                    Text("Жин")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if selectedMetric {
                        // Metric Weight Picker
                        VStack(spacing: 10) {
                            Text(String(format: "%.1f кг", weightKg))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if weightKg > 40.0 {
                                        weightKg -= 0.5
                                        user.weight = weightKg
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Picker("Жин (кг)", selection: Binding(
                                        get: { Int(weightKg * 2) }, // Convert to 0.5 increments
                                        set: { weightKg = Double($0) / 2.0; user.weight = weightKg }
                                    )) {
                                        ForEach(80...400, id: \.self) { weight in // 40.0 to 200.0 kg in 0.5 increments
                                            Text(String(format: "%.1f", Double(weight) / 2.0)).tag(weight)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    .clipped()
                                    
                                    Text("кг")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Button(action: {
                                    if weightKg < 200.0 {
                                        weightKg += 0.5
                                        user.weight = weightKg
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        // Imperial Weight Picker
                        VStack(spacing: 10) {
                            Text("\(weightLbs) фунт")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if weightLbs > 88 {
                                        weightLbs -= 1
                                        user.weight = Double(weightLbs) / 2.20462
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                                
                                HStack {
                                    Picker("Жин (фунт)", selection: $weightLbs) {
                                        ForEach(88...440, id: \.self) { weight in
                                            Text("\(weight)").tag(weight)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 80)
                                    .clipped()
                                    .onChange(of: weightLbs) { _, newValue in
                                        user.weight = Double(newValue) / 2.20462
                                    }
                                    
                                    Text("фунт")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Button(action: {
                                    if weightLbs < 440 {
                                        weightLbs += 1
                                        user.weight = Double(weightLbs) / 2.20462
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // BMI Display - Made more compact
                if let bmi = calculateBMI() {
                    VStack(spacing: 8) {
                        Text("BMI")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(bmiColor(bmi: bmi))
                        
                        Text(bmiCategory(bmi: bmi))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(bmiColor(bmi: bmi))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(bmiColor(bmi: bmi).opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 10)
        }
        .animation(.easeInOut, value: selectedMetric)
        .onAppear {
            // Initialize picker values from user data
            if let height = user.height {
                heightCm = Int(height)
                let totalInches = height / 2.54
                heightFeet = Int(totalInches / 12)
                heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            }
            if let weight = user.weight {
                weightKg = weight
                weightLbs = Int(weight * 2.20462)
            }
        }
        .onChange(of: selectedMetric) { _, _ in
            // Update values when switching between metric systems
            if selectedMetric {
                // Converting from imperial to metric
                updateHeightFromImperial()
                user.weight = Double(weightLbs) / 2.20462
                weightKg = user.weight ?? 70.0
            } else {
                // Converting from metric to imperial
                updateImperialFromHeight()
                weightLbs = Int((user.weight ?? 70.0) * 2.20462)
            }
        }
    }
    
    private func updateHeightFromImperial() {
        let totalInches = Double(heightFeet * 12 + heightInches)
        user.height = totalInches * 2.54
        heightCm = Int(user.height ?? 170)
    }
    
    private func updateImperialFromHeight() {
        guard let height = user.height else { return }
        let totalInches = height / 2.54
        heightFeet = Int(totalInches / 12)
        heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
    }
    
    private func calculateBMI() -> Double? {
        guard let height = user.height, let weight = user.weight else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    private func bmiCategory(bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Жингийн дутагдалтай"
        case 18.5..<25:
            return "Хэвийн"
        case 25..<30:
            return "Илүүдэл жинтэй"
        default:
            return "Таргалалттай"
        }
    }
    
    private func bmiColor(bmi: Double) -> Color {
        switch bmi {
        case ..<18.5:
            return .orange
        case 18.5..<25:
            return .green
        case 25..<30:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    @Previewable @State var mockUser = User(id: "", firstName: "", lastName: "", email: "")
    Step3HeightWeightView(user: $mockUser)
}
