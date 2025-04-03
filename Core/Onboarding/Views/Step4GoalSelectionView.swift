import SwiftUI

struct Step4GoalSelectionView: View {
    @Binding var user: User
    
    let goalOptions = ["Gain Weight", "Recomposition", "Lose Weight", "Maintain Weight", "Lose Body-fat"]
    
    var body: some View {
        VStack {
            Text("Select Your Goal")
                .font(.title)
                .padding()
            
            Picker("Goal", selection: $user.goal) {
                ForEach(goalOptions, id: \.self) { goal in
                    Text(goal).tag(goal)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
        }
    }
}