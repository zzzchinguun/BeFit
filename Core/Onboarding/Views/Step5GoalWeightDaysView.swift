import SwiftUI

struct Step5GoalWeightDaysView: View {
    @Binding var user: User
    @State var showSheet: Bool = false
    
    var body: some View {
        VStack {
            Text("Weight loss goal")
                .font(.title)
                .padding()
            
            Text("Checkout your maximum muscular potential")
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .onTapGesture {
                    showSheet.toggle()
                }
            
            TextField("Goal Weight (kg)", value: $user.goalWeight, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .padding()
            
            TextField("Days to Complete", value: $user.daysToComplete, formatter: NumberFormatter())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            let tdeeResult = calculateTDEE(user: user)
            Text(tdeeResult.resultString)
                .padding()
                .onAppear {
                    user.tdee = tdeeResult.tdee
                }
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Maximum Muscular Potential")
                    .font(.title)
                    .bold()
                
                if let height = user.height {
                    Text(calculateMaximumMuscularPotential(height: height))
                        .font(.body)
                        .padding()
                } else {
                    Text("Please enter your height to calculate.")
                        .font(.body)
                        .padding()
                }

                Button("Close") {
                    showSheet.toggle()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}