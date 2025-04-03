import SwiftUI

struct Step6TimelineView: View {
    @Binding var user: User
    @State private var selectedMetric = true // true for metric, false for imperial
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Goal Weight Section
                VStack(spacing: 20) {
                    Text("Target Weight")
                        .font(.headline)
                    
                    // Metric Toggle
                    Picker("System", selection: $selectedMetric) {
                        Text("Metric (kg)").tag(true)
                        Text("Imperial (lbs)").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    // Weight Selection
                    VStack(spacing: 15) {
                        if selectedMetric {
                            // Metric Weight
                            HStack {
                                Text("Target:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(String(format: "%.1f", user.goalWeight ?? user.weight ?? 70)) kg")
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
                            
                            // Weight Change Indicator
                            if let currentWeight = user.weight, let goalWeight = user.goalWeight {
                                let difference = goalWeight - currentWeight
                                HStack {
                                    Image(systemName: difference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(difference > 0 ? .green : .blue)
                                    Text("\(abs(difference), specifier: "%.1f") kg to \(difference > 0 ? "gain" : "lose")")
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
                                Text("Target:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(goalLbs.wrappedValue) lbs")
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
                            
                            // Weight Change Indicator
                            if let currentWeight = user.weight, let goalWeight = user.goalWeight {
                                let differenceLbs = Int((goalWeight - currentWeight) * 2.20462)
                                HStack {
                                    Image(systemName: differenceLbs > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .foregroundColor(differenceLbs > 0 ? .green : .blue)
                                    Text("\(abs(differenceLbs)) lbs to \(differenceLbs > 0 ? "gain" : "lose")")
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
                    Text("Timeline")
                        .font(.headline)
                    
                    let weeks = Binding(
                        get: { (user.daysToComplete ?? 84) / 7 },
                        set: { user.daysToComplete = $0 * 7 }
                    )
                    
                    // Timeline Slider
                    VStack(spacing: 15) {
                        Slider(value: Binding(
                            get: { Double(weeks.wrappedValue) },
                            set: { weeks.wrappedValue = Int($0) }
                        ), in: 4...52, step: 1)
                        .accentColor(.blue)
                        
                        HStack {
                            Text("\(weeks.wrappedValue) weeks")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Weekly Progress Breakdown
                    if let currentWeight = user.weight,
                       let goalWeight = user.goalWeight,
                       let days = user.daysToComplete {
                        let weeklyChange = (goalWeight - currentWeight) / (Double(days) / 7)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weekly Progress")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: abs(weeklyChange) < 0.5 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(abs(weeklyChange) < 0.5 ? .green : .orange)
                                
                                Text("\(abs(weeklyChange), specifier: "%.2f") kg per week")
                                    .font(.subheadline)
                            }
                            
                            if abs(weeklyChange) > 0.5 {
                                Text("Consider a longer timeline for sustainable results")
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