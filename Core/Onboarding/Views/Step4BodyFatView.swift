import SwiftUI

struct Step4BodyFatView: View {
    @Binding var user: User
    @State private var showingGuide = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Visual Body Fat Guide Button
                Button {
                    showingGuide = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("How to Estimate Body Fat?")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Body Fat Slider
                VStack(spacing: 15) {
                    HStack {
                        Text("Body Fat Percentage")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(user.bodyFatPercentage ?? 15))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { user.bodyFatPercentage ?? 15 },
                            set: { user.bodyFatPercentage = $0 }
                        ),
                        in: 5...50,
                        step: 1
                    )
                    .accentColor(.blue)
                    
                    // Category Indicator
                    HStack {
                        Text(bodyFatCategory)
                            .font(.subheadline)
                            .foregroundColor(categoryColor)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                
                // Category Ranges
                VStack(spacing: 15) {
                    Text("Reference Ranges")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    ForEach(bodyFatRanges, id: \.category) { range in
                        HStack {
                            Circle()
                                .fill(range.color)
                                .frame(width: 10, height: 10)
                            Text(range.category)
                                .font(.subheadline)
                            Spacer()
                            Text(range.range)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
            }
            .padding()
        }
        .sheet(isPresented: $showingGuide) {
            BodyFatGuideView()
        }
    }
    
    private var bodyFatCategory: String {
        guard let bodyFat = user.bodyFatPercentage else { return "Select your body fat %" }
        
        if user.sex == "Male" {
            switch bodyFat {
            case ..<6: return "Essential Fat"
            case 6..<14: return "Athletic"
            case 14..<18: return "Fitness"
            case 18..<25: return "Average"
            default: return "Above Average"
            }
        } else {
            switch bodyFat {
            case ..<16: return "Essential Fat"
            case 16..<24: return "Athletic"
            case 24..<31: return "Fitness"
            case 31..<39: return "Average"
            default: return "Above Average"
            }
        }
    }
    
    private var categoryColor: Color {
        guard let bodyFat = user.bodyFatPercentage else { return .gray }
        
        if user.sex == "Male" {
            switch bodyFat {
            case ..<6: return .red
            case 6..<14: return .green
            case 14..<18: return .blue
            case 18..<25: return .orange
            default: return .red
            }
        } else {
            switch bodyFat {
            case ..<16: return .red
            case 16..<24: return .green
            case 24..<31: return .blue
            case 31..<39: return .orange
            default: return .red
            }
        }
    }
    
    private var bodyFatRanges: [(category: String, range: String, color: Color)] {
        if user.sex == "Male" {
            return [
                ("Essential Fat", "2-5%", .red),
                ("Athletic", "6-13%", .green),
                ("Fitness", "14-17%", .blue),
                ("Average", "18-24%", .orange),
                ("Above Average", "25%+", .red)
            ]
        } else {
            return [
                ("Essential Fat", "10-13%", .red),
                ("Athletic", "14-20%", .green),
                ("Fitness", "21-24%", .blue),
                ("Average", "25-31%", .orange),
                ("Above Average", "32%+", .red)
            ]
        }
    }
}

struct BodyFatGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Guide content...
                    Text("How to Estimate Body Fat Percentage")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Group {
                        guideSection(
                            title: "Visual Assessment",
                            description: "Compare your body to reference images",
                            icon: "eye.fill"
                        )
                        
                        guideSection(
                            title: "Body Fat Calipers",
                            description: "Use calipers to measure skin folds",
                            icon: "ruler.fill"
                        )
                        
                        guideSection(
                            title: "Bioelectrical Impedance",
                            description: "Use smart scales or handheld devices",
                            icon: "bolt.fill"
                        )
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func guideSection(title: String, description: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}