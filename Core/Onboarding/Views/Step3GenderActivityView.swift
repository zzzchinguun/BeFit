import SwiftUI

struct Step3GenderActivityView: View {
    @Binding var user: User
    
    let activityLevels = ["Суугаа амьдралын хэв маяг", "Хөнгөн идэвхтэй", "Дунд идэвхтэй", "Идэвхтэй"]
    
    var body: some View {
        VStack {
            Text("Хөдөлгөөний түвшин ба хүйсээ сонгоно уу")
                .font(.title)
                .padding()
            
            Picker("Хүйс", selection: $user.sex) {
                Text("Эрэгтэй").tag("Male")
                Text("Эмэгтэй").tag("Female")
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

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    return Step3GenderActivityView(user: $previewUser)
}



