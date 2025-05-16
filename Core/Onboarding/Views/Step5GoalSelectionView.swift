import SwiftUI

struct Step5GoalSelectionView: View {
    @Binding var user: User
    
    let goals = [
        Goal(id: "weight_loss", title: "Жин хасах", description: "Биеийн жинг ба өөх бууруулах", icon: "arrow.down.circle.fill"),
        Goal(id: "muscle_gain", title: "Булчин нэмэх", description: "Булчин ба хүч чадал нэмэх", icon: "figure.strengthtraining.traditional.circle.fill"),
        Goal(id: "maintenance", title: "Жинг хадгалах", description: "Одоогийн жинг хадгалах", icon: "equal.circle.fill"),
        Goal(id: "recomposition", title: "Дахин бүтцэд оруулах", description: "Өөх багасгаж, булчин нэмэх", icon: "arrow.up.arrow.down.circle.fill"),
        Goal(id: "performance", title: "Гүйцэтгэлийг сайжруулах", description: "Атлетик гүйцэтгэл сайжруулах", icon: "figure.run.circle.fill")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(goals, id: \.id) { goal in
                    GoalCard(goal: goal, isSelected: user.goal == goal.title) {
                        withAnimation(.spring()) {
                            user.goal = goal.title
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, goals.last?.id == goal.id ? 20 : 0)
                }
            }
                        .padding(.top, 20)
        }
    }
}

struct Goal {
    let id: String
    let title: String
    let description: String
    let icon: String
}

struct GoalCard: View {
    let goal: Goal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2){
                HStack(spacing: 10) {
                    Image(systemName: goal.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                        .frame(width: 44, height: 44)
                    
                    Text(goal.title)
                        .foregroundColor(isSelected ? .white : .blue)
                        .font(.headline)
                        .fontWidth(.condensed)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .white : .blue)
                        .imageScale(.large)
                }
                HStack{
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .gray)
                        .padding(.leading, 10)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .animation(.spring(), value: isSelected)
    }
}

struct GoalCard_Previews: PreviewProvider {
    static var previews: some View {
        GoalCard(
            goal: Goal(
                id: "weight_loss",
                title: "Жин хасах",
                description: "Биеийн жинг ба өөхийг бууруулах",
                icon: "arrow.down.circle.fill"
            ),
            isSelected: true
        ) {}
    }
}

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    Step5GoalSelectionView(user: $previewUser)
        .environment(\.colorScheme, .dark)
}
