import SwiftUI

struct Step2BodyFatPercentageView: View {
    @Binding var user: User
    
    var body: some View {
        VStack {
            Text("Estimated body fat percentage")
                .font(.title)
                .padding()
            
            Picker("Body fat", selection: $user.bodyFatPercentage) {
                ForEach(0..<100) { bodyFat in
                    Text("\(bodyFat)").tag(Double(bodyFat))
                }
            }
            .pickerStyle(.wheel)
            .padding()
        }
    }
}