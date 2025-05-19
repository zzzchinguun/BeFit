import SwiftUI

struct Step3HeightWeightView: View {
    @Binding var user: User
    @State private var selectedMetric = true // true for metric, false for imperial
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // Height Input
                VStack(spacing: 15) {
                    HStack{
                        Text("Өндөр")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            if let currentHeight = user.height {
                                   user.height = currentHeight - 1
                               }
                        }){
                            Image(systemName: "minus.circle.fill")
                        }
                        Text("\(Int(user.height ?? 170)) см")
                            .font(.title3)
                            .frame(width: 80)
                            .foregroundColor(user.height == nil ? .gray : .primary)
                        Button(action: {
                            if let currentHeight = user.height {
                                user.height = currentHeight + 1
                            }
                        }){
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                    .padding(.horizontal)
                    
                    if selectedMetric {
                        // Metric Height (cm)
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { user.height ?? 170 },
                                    set: { user.height = $0 }
                                ),
                                in: 140...220,
                                step: 1
                            )
                            .accentColor(.blue)
                            .padding(.horizontal)
                            
                            
                        }
                    } else {
                        // Imperial Height (ft/in)
                        let feet = Int((user.height ?? 170) / 30.48)
                        let inches = Int(((user.height ?? 170) / 2.54) - (Double(feet) * 12))
                        
                        HStack(spacing: 20) {
                            // Feet Picker
                            Picker("Фут", selection: Binding(
                                get: { feet },
                                set: { newFeet in
                                    let totalInches = (Double(newFeet) * 12 + Double(inches)) * 2.54
                                    user.height = totalInches
                                }
                            )) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft) фут").tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            // Inches Picker
                            Picker("Инч", selection: Binding(
                                get: { inches },
                                set: { newInches in
                                    let totalInches = (Double(feet) * 12 + Double(newInches)) * 2.54
                                    user.height = totalInches
                                }
                            )) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) инч").tag(inch)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Weight Input
                VStack(spacing: 15) {
                    VStack{
                        HStack{
                            Text("Жин")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                if let currentWeight = user.weight {
                                    user.weight = currentWeight - 1
                                }
                            }){
                                Image(systemName: "minus.circle.fill")
                            }
                            Text(String(format: "%.1f кг", user.weight ?? 70))
                                .font(.title3)
                                .frame(width: 80)
                                .foregroundColor(user.weight == nil ? .gray : .primary)
                            Button(action: {
                                if let currentWeight = user.weight {
                                    user.weight = currentWeight + 1
                                }
                            }){
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                        .padding(.horizontal)
                    }
                    if selectedMetric {
                        // Metric Weight (kg)
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { user.weight ?? 70 },
                                    set: { user.weight = $0 }
                                ),
                                in: 40...200,
                                step: 0.5
                            )
                            .accentColor(.blue)
                            
                        }
                        .padding(.horizontal)
                    } else {
                        // Imperial Weight (lbs)
                        let lbs = Binding(
                            get: { Int((user.weight ?? 70) * 2.20462) },
                            set: { user.weight = Double($0) / 2.20462 }
                        )
                        
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { Double(lbs.wrappedValue) },
                                    set: { lbs.wrappedValue = Int($0) }
                                ),
                                in: 88...440,
                                step: 1
                            )
                            .accentColor(.blue)
                            
                            Text("\(lbs.wrappedValue) фунт")
                                .font(.title3)
                                .frame(width: 80)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Picker("Систем", selection: $selectedMetric) {
                    Text("см/кг").tag(true)
                    Text("фут/фунт").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                // BMI Display
                if let bmi = calculateBMI() {
                    VStack(spacing: 10) {
                        Text("Биеийн жингийн индекс (BMI): \(String(format: "%.1f", bmi))")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(bmiCategory(bmi: bmi))
                            .font(.subheadline)
                            .foregroundColor(bmiColor(bmi: bmi))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
            }
            .padding(.vertical)
        }
        .animation(.easeInOut, value: selectedMetric)
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
    Step3HeightWeightView(user: .constant(User(id: "", firstName: "", lastName: "", email: "")))
}
