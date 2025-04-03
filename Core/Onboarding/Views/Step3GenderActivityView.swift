import SwiftUI

struct Step3GenderActivityView: View {
    @Binding var user: User
    
    let activityLevels = ["Sedentary", "Lightly Active", "Moderately Active", "Very Active"]
    
    var body: some View {
        VStack {
            Text("Gender and Activity Level")
                .font(.title)
                .padding()
            
            Picker("Gender", selection: $user.sex) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Picker("Activity Level", selection: $user.activityLevel) {
                ForEach(activityLevels, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
        }
    }
}