import SwiftUI

struct Step6MacroView: View {
    @Binding var user: User
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedSplit = "Moderate carb"
    let macroSplits = ["Moderate carb": "30/35/35", "Lower carb": "40/40/20", "Higher carb": "30/20/50"]
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                if let tdee = user.tdee {
                    // TDEE Card
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
                    
                    // Macro Split Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Macro Split")
                            .font(.headline)
                        
                        Picker("Macro Split", selection: $selectedSplit) {
                            ForEach(Array(macroSplits.keys), id: \.self) { key in
                                Text(key)
                                    .tag(key)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Macro Input Fields
                    VStack(spacing: 15) {
                        macroInputField(title: "Protein", value: $protein, color: .blue, icon: "figure.strengthtraining.traditional")
                        macroInputField(title: "Carbs", value: $carbs, color: .green, icon: "leaf.fill")
                        macroInputField(title: "Fat", value: $fat, color: .yellow, icon: "drop.fill")
                    }
                    
                    // Save Button
                    Button(action: {
                        if let p = Double(protein), let c = Double(carbs), let f = Double(fat) {
                            user.macros = Macros(protein: Int(p), carbs: Int(c), fat: Int(f))
                        }
                    }) {
                        Text("Save Macros")
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("TDEE not calculated. Please go back to Step 5.")
                        .font(.headline)
                        .padding()
                }
            }
            .navigationTitle("Customize Macros")
        }
    }
    
    func macroInputField(title: String, value: Binding<String>, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            TextField(title, text: value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
        .padding(.horizontal)
    }
}
