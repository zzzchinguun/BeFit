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
                        Text("Биеийн өөхийг хэрхэн тооцоолох вэ?")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Body Fat Slider
                VStack(spacing: 15) {
                    HStack {
                        Text("Биеийн өөхний хувь")
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
                    Text("Лавлагаа")
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
        .onAppear{
            print(user.sex!)
        }
        .sheet(isPresented: $showingGuide) {
            BodyFatGuideView()
                .presentationDetents([.fraction(0.8)])
        }
    }
    
    private var bodyFatCategory: String {
        guard let bodyFat = user.bodyFatPercentage else { return "Биеийн өөхний хувийг сонгоно уу" }
        
        if user.sex == "Male" {
            switch bodyFat {
            case ..<6: return "Шаардлагатай өөх"
            case 6..<14: return "Тамирчны түвшин"
            case 14..<18: return "Фитнес"
            case 18..<25: return "Дундаж"
            default: return "Дундажаас дээш"
            }
        } else {
            switch bodyFat {
            case ..<16: return "Шаардлагатай өөх"
            case 16..<24: return "Тамирчны түвшин"
            case 24..<31: return "Фитнес"
            case 31..<39: return "Дундаж"
            default: return "Дундажаас дээш"
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
                ("Шаардлагатай өөх", "2-5%", .red),
                ("Тамирчны түвшин", "6-13%", .green),
                ("Фитнес", "14-17%", .blue),
                ("Дундаж", "18-24%", .orange),
                ("Дундажаас дээш", "25%+", .red)
            ]
        } else {
            return [
                ("Шаардлагатай өөх", "10-13%", .red),
                ("Тамирчны түвшин", "14-20%", .green),
                ("Фитнес", "21-24%", .blue),
                ("Дундаж", "25-31%", .orange),
                ("Дундажаас дээш", "32%+", .red)
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
                    Text("Биеийн өөхний хувийг хэрхэн тооцоолох вэ?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Group {
                        guideSection(
                            title: "Харааны үнэлгээ",
                            description: "Биеэ лавлагааны зургуудтай харьцуулах",
                            icon: "eye.fill"
                        )
                        
                        guideSection(
                            title: "Биеийн өөх хэмжигч",
                            description: "Арьсны нугалаа хэмжих зориулалттай хэмжигч ашиглах",
                            icon: "ruler.fill"
                        )
                        
                        guideSection(
                            title: "Био-цахилгаан эсэргүүцэл",
                            description: "Ухаалаг жин эсвэл гар төхөөрөмж ашиглах",
                            icon: "bolt.fill"
                        )
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Болсон") { dismiss() })
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

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    Step4BodyFatView(user: $previewUser)
        .environment(\.colorScheme, .dark)
}
