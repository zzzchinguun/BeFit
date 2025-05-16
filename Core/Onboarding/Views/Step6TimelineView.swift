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
                            
                            Slider(
                                value: Binding(
                                    get: { user.goalWeight ?? user.weight ?? 70 },
                                    set: { user.goalWeight = $0 }
                                ),
                                in: 40...200,
                                step: 0.5
                            )
                            .accentColor(.blue)
                            
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
                            
                            Slider(
                                value: Binding(
                                    get: { Double(goalLbs.wrappedValue) },
                                    set: { goalLbs.wrappedValue = Int($0) }
                                ),
                                in: 88...440,
                                step: 1
                            )
                            .accentColor(.blue)
                            
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
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                
                // Timeline Section
                VStack(spacing: 20) {
                    Text("Хугацааны төлөвлөгөө")
                        .font(.headline)
                    
                    let weeks = Binding(
                        get: { (user.daysToComplete ?? 84) / 7 },
                        set: { user.daysToComplete = $0 * 7 }
                    )
                    
                    VStack(spacing: 15) {
                        Slider(value: Binding(
                            get: { Double(weeks.wrappedValue) },
                            set: { weeks.wrappedValue = Int($0) }
                        ), in: 4...52, step: 1)
                        .accentColor(.blue)
                        
                        HStack {
                            Text("\(weeks.wrappedValue) долоо хоног")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    if let currentWeight = user.weight,
                       let goalWeight = user.goalWeight,
                       let days = user.daysToComplete {
                        let weeklyChange = (goalWeight - currentWeight) / (Double(days) / 7)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Долоо хоног тутмын өөрчлөлт")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: abs(weeklyChange) < 0.5 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(abs(weeklyChange) < 0.5 ? .green : .orange)
                                
                                Text("Долоо хоногт \(abs(weeklyChange), specifier: "%.2f") кг")
                                    .font(.subheadline)
                            }
                            
                            if abs(weeklyChange) > 0.5 {
                                Text("Тогтвортой үр дүнд хүрэхийн тулд илүү урт хугацааг сонгоно уу")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
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
}
