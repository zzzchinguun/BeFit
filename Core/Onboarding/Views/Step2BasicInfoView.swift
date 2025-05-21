import SwiftUI

struct Step2BasicInfoView: View {
    @Binding var user: User
    
    let genderOptions = ["Male", "Female", "Other"]
    let activityLevels = [
        "Суугаа амьдралын хэв маяг": "Бараг дасгал хийдэггүй",
        "Хөнгөн идэвхтэй": "Хөнгөн дасгал 7 хоногт 1-3 удаа",
        "Дунд зэрэг идэвхтэй": "Дунд зэрэг дасгал 7 хоногт 3-5 удаа",
        "Идэвхтэй": "Хүчтэй дасгал 7 хоногт 6-7 удаа",
        "Маш идэвхтэй": "Хүнд дасгал болон биеийн хүчний ажил"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Age Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Таны нас")
                        .font(.headline)
                    
                    HStack {
                        TextField("18", value: $user.age, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(user.age == nil ? .gray : .primary)
                        
                        Stepper("", value: Binding(
                            get: { user.age ?? 18 },
                            set: { user.age = $0 }
                        ), in: 13...100)
                    }
                }
                
                // Gender Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Хүйс")
                        .font(.headline)
                    
                    HStack {
                        ForEach(genderOptions, id: \.self) { gender in
                            Button {
                                user.sex = gender
                            } label: {
                                if gender == "Other"{
                                    Text("Бусад")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(user.sex == gender ? Color.blue : Color(.secondarySystemBackground))
                                        .foregroundColor(user.sex == gender ? .white : .primary)
                                        .cornerRadius(8)
                                } else {
                                    Text(gender == "Male" ? "Эрэгтэй" : "Эмэгтэй")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(user.sex == gender ? Color.blue : Color(.secondarySystemBackground))
                                        .foregroundColor(user.sex == gender ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                            .buttonStyle(PlainButtonStyle()) // Add this to ensure buttons are tappable
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensures alignment
                }
                
                // Activity Level Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Хөдөлгөөний идэвх сонгох")
                        .font(.headline)
                    
                    ForEach(Array(activityLevels.keys.sorted()), id: \.self) { level in
                        Button {
                            user.activityLevel = level
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(level)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(activityLevels[level] ?? "")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if user.activityLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(user.activityLevel == level ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(user.activityLevel == level ? Color.blue : Color.clear, lineWidth: 1)
                                    )
                            )
                        }
                        .foregroundColor(.primary)
                        .buttonStyle(PlainButtonStyle()) // Add this to ensure buttons are tappable
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    // Create a mutable instance of User for use with the binding
    struct PreviewWrapper: View {
        @State private var user = User(
            id: UUID().uuidString,
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            age: nil,
            weight: nil,
            height: nil,
            sex: nil,
            activityLevel: nil
        )
        
        var body: some View {
            Step2BasicInfoView(user: $user)
                .previewDisplayName("Basic Info View")
        }
    }
    
    return PreviewWrapper()
}
