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
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.6), radius: 8, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                    )
                }
                .scaleEffect(showingGuide ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: showingGuide)
                
                // Body Fat Slider
                VStack(spacing: 15) {
                    HStack {
                        Text("Биеийн өөхний хувь")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(user.bodyFatPercentage ?? 15))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(user.bodyFatPercentage == nil ? .gray : .blue)
                    }
                    
                    // Enhanced slider with buttons
                    VStack(spacing: 10) {
                        HStack(spacing: 15) {
                            Button(action: {
                                let current = user.bodyFatPercentage ?? 15
                                if current > 5 {
                                    user.bodyFatPercentage = current - 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(spacing: 5) {
                                Slider(
                                    value: Binding(
                                        get: { user.bodyFatPercentage ?? 15 },
                                        set: { user.bodyFatPercentage = $0 }
                                    ),
                                    in: 5...50,
                                    step: 1
                                )
                                .accentColor(.blue)
                                .frame(height: 44)
                                
                                // Visual scale
                                HStack {
                                    Text("5%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("25%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("50%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: {
                                let current = user.bodyFatPercentage ?? 15
                                if current < 50 {
                                    user.bodyFatPercentage = current + 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
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
            print(user.sex ?? "No sex selected")
        }
        .sheet(isPresented: $showingGuide) {
            BodyFatGuideView(user: user)
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

// BodyFat Guide View with reference images
struct BodyFatGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Биеийн Өөхний Лавлагаа")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Доорх зурагнуудаас хамгийн ойр өөрийн биеийн бүтэцтэй тааруулан харьцуулна уу")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Reference images based on gender
                    if let sex = user.sex {
                        VStack(spacing: 15) {
                            Text(sex == "Female" ? "Эмэгтэйчүүдийн хувьд" : "Эрэгтэйчүүдийн хувьд")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            // Body fat reference image
                            Image(sex == "Female" ? "female-bf-reference" : "male-bf-reference")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                                .shadow(radius: 10)
                        }
                    } else {
                        // Show placeholder when sex is not selected yet
                        VStack(spacing: 15) {
                            Text("Жин ба хүйс мэдээллээ оруулсны дараа лавлагаа харагдана")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "person.crop.circle.dashed")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Хэрхэн тооцоолох вэ?")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        guideSection(
                            title: "Тусгал ашиглана уу",
                            description: "Тусгалын өмнө зогсоод өөрийн биеийг анхааралтай харна уу",
                            icon: "eye.circle"
                        )
                        
                        guideSection(
                            title: "Хэвлийн мужийг харна уу",
                            description: "Хэвлийн булчин, хажууд талын өөх хуримтлалыг харьцуулна уу",
                            icon: "figure.walk"
                        )
                        
                        guideSection(
                            title: "Мөр, гарын өөхийг харна уу",
                            description: "Мөр, бугуй, гарын мужид хуримтлагдсан өөхийг анхаарна уу",
                            icon: "hand.raised.fill"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Хаах") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
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
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    Step4BodyFatView(user: $previewUser)
        .environment(\.colorScheme, .dark)
}
