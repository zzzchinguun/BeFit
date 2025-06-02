import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var user: User
    @Published var currentStep = 1
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) async {
        self.authViewModel = authViewModel
        self.user = authViewModel.currentUser ?? User.MOCK_USER
    }
    
    func saveOnboardingData() async throws {
        try await authViewModel.updateUserFitnessData(
            age: user.age,
            weight: user.weight,
            height: user.height,
            sex: user.sex,
            activityLevel: user.activityLevel,
            bodyFatPercentage: user.bodyFatPercentage,
            goalWeight: user.goalWeight,
            daysToComplete: user.daysToComplete,
            goalStartDate: Date(),
            goal: user.goal,
            tdee: user.tdee,
            goalCalories: user.goalCalories,
            macros: user.macros
        )
    }
}
