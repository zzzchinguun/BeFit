import SwiftUI

struct Step1AgeWeightHeightView: View {
    @Binding var user: User
    
    var body: some View {
        VStack {
            Text("Enter your details")
                .font(.title)
                .padding()
            
            TextField("Age", value: $user.age, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            TextField("Weight (kg)", value: $user.weight, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
            
            TextField("Height (cm)", value: $user.height, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
        }
    }
}
