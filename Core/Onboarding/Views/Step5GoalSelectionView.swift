import SwiftUI

struct Step5GoalSelectionView: View {
    @Binding var user: User
    
    let goals = [
        Goal(id: "weight_loss", title: "Weight Loss", description: "Reduce body weight and fat", icon: "arrow.down.circle.fill"),
        Goal(id: "muscle_gain", title: "Muscle Gain", description: "Build muscle and strength", icon: "figure.strengthtraining.traditional"),
        Goal(id: "maintenance", title: "Maintenance", description: "Maintain current weight", icon: "equal.circle.fill"),
        Goal(id: "recomposition", title: "Recomposition", description: "Loss fat & gain muscle", icon: "arrow.up.arrow.down.circle.fill"),
        Goal(id: "performance", title: "Performance", description: "Improve athletic performance", icon: "figure.run.circle.fill")
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
                }
            }
            .padding()
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
            HStack(spacing: 15) {
                Image(systemName: goal.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.headline)
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .blue)
                    .imageScale(.large)
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
                title: "Weight Loss",
                description: "Reduce body weight and fat",
                icon: "arrow.down.circle.fill"
            ),
            isSelected: true
        ) {}
    }
}
