import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentStep = 1
    @State private var user = User(id: "", firstName: "", lastName: "", email: "")
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isLoading = false
    @State private var validationMessage: String? = nil
    @FocusState private var isAnyFieldFocused: Bool
    
    let totalSteps = 8
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Progress
            VStack(spacing: 8) {
                // Step Progress Indicators
                HStack(spacing: 6) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(getStepColor(for: step))
                            .frame(width: UIScreen.main.bounds.width / CGFloat(totalSteps + 1), height: 4)
                            .overlay(
                                Capsule()
                                    .stroke(currentStep == step ? Color.blue.opacity(0.3) : Color.clear, lineWidth: currentStep == step ? 2 : 0)
                                    .scaleEffect(1.2)
                            )
                            .onTapGesture {
                                withAnimation {
                                    dismissKeyboard()
                                    // Only allow navigation to completed steps or the next available step
                                    if step <= getMaxAllowedStep() {
                                        currentStep = step
                                        validationMessage = nil
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)
                
                // Step Title
                Text(stepTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top)
                
                // Step Description
                Text(stepDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .background(
                Color(.secondarySystemBackground)
                    .ignoresSafeArea(edges: .top)
            )
            
            // Content
            TabView(selection: $currentStep) {
                Step1WelcomeView(user: $user)
                    .tag(1)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step2BasicInfoView(user: $user)
                    .tag(2)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step3HeightWeightView(user: $user)
                    .tag(3)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step4BodyFatView(user: $user)
                    .tag(4)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step5GoalSelectionView(user: $user)
                    .tag(5)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step6TimelineView(user: $user)
                    .tag(6)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step7MacroView(user: $user)
                    .tag(7)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step5GoalWeightDaysView(user: $user)
                    .tag(8)
                    .padding()
                    .focused($isAnyFieldFocused)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentStep) { oldValue, newValue in
                // Prevent TabView from changing to invalid steps via swipe
                let maxAllowed = getMaxAllowedStep()
                if newValue > maxAllowed {
                    currentStep = oldValue
                } else {
                    // Clear validation message when moving to a valid step
                    validationMessage = nil
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Validation message if needed
            if let message = validationMessage {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.bottom, 8)
            }
            
            // Navigation Buttons
            HStack {
                if currentStep > 1 {
                    Button(action: {
                        withAnimation {
                            dismissKeyboard()
                            currentStep -= 1
                            validationMessage = nil
                        }
                    }) {
                        HStack{
                            Image(systemName: "chevron.left")
                            Text("Буцах")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.0))
                        .overlay(
                            Capsule()
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .clipShape(Capsule())
                } else {
                    Button(action: dismiss.callAsFunction) {
                        HStack {
                            Image(systemName: "chevron.left.chevron.left.dotted")
                            Text("Алгасах")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.0))
                        .overlay(
                            Capsule()
                                .stroke(Color.blue, lineWidth: 1)
                        )
                    }
                    .clipShape(Capsule())
                    
                }
                
                Spacer()
                
                if currentStep < totalSteps {
                    Button(action: {
                        withAnimation {
                            dismissKeyboard()
                            if validateCurrentStep() {
                                currentStep += 1
                                validationMessage = nil
                            } else {
                                validationMessage = getValidationMessage()
                            }
                        }
                    }) {
                        HStack {
                            Text("Дараах")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            canProceed ? Color.blue : Color.gray.opacity(0.5)
                        )
                        .clipShape(Capsule())
                    }
                } else {
                    Button(action: {
                        dismissKeyboard()
                        saveData()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Дуусгах")
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canProceed ? Color.green : Color.gray.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .disabled(isLoading || !canProceed)
                }
            }
            .padding()
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func dismissKeyboard() {
        isAnyFieldFocused = false
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 1: return "BeFit тавтай морил"
        case 2: return "Үндсэн мэдээлэл"
        case 3: return "Биеийн хэмжилтүүд"
        case 4: return "Биеийн бүтэц"
        case 5: return "Таны зорилго"
        case 6: return "Хугацааны төлөвлөлт"
        case 7: return "Таны тооцоолсон үр дүн"
        case 8: return "Хоолны тохиргоо"
        default: return ""
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 1: return "Таны фитнесс аяллыг тохируулъя"
        case 2: return "Бидэнд өөрийнхөө тухай хэлнэ үү"
        case 3: return "Таны одоогийн байдлыг ойлгоход туслаарай"
        case 4: return "Таны биеийн бүтэц хэмжиж үзье"
        case 5: return "Та ямар зорилго тавьж байна вэ?"
        case 6: return "Өөрийн зорилтот хугацааг тохируулна уу"
        case 7: return "Хооллолтын төлөвлөгөөгөө тохируулна уу"
        case 8: return "Таны тооцоолсон үр дүнг харуулж байна"
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return true
        case 2: return user.age != nil && user.sex != nil && user.activityLevel != nil
        case 3: return user.height != nil && user.weight != nil
        case 4: return user.bodyFatPercentage != nil
        case 5: return user.goal != nil
        case 6: return user.goalWeight != nil && user.daysToComplete != nil
        case 7: return true
        case 8: return user.macros != nil
        default: return false
        }
    }
    
    private func validateCurrentStep() -> Bool {
        return canProceed
    }
    
    private func getValidationMessage() -> String {
        switch currentStep {
        case 2:
            var missing: [String] = []
            if user.age == nil { missing.append("нас") }
            if user.sex == nil { missing.append("хүйс") }
            if user.activityLevel == nil { missing.append("идэвхийн түвшин") }
            
            if missing.count == 3 {
                return "Нас, хүйс болон идэвхийн түвшинээ оруулна уу"
            } else if missing.count == 2 {
                return "Та \(missing[0]) болон \(missing[1])ээ оруулна уу"
            } else if missing.count == 1 {
                return "Та \(missing[0])аа оруулна уу"
            }
        case 3:
            if user.height == nil && user.weight == nil {
                return "Өндөр болон жингээ оруулна уу"
            } else if user.height == nil {
                return "Өндрөө оруулна уу"
            } else if user.weight == nil {
                return "Жингээ оруулна уу"
            }
        case 4:
            return "Биеийн өөхний хувиа оруулна уу"
        case 5:
            return "Зорилгоо сонгоно уу"
        case 6:
            if user.goalWeight == nil && user.daysToComplete == nil {
                return "Зорилтот жин болон хугацааг оруулна уу"
            } else if user.goalWeight == nil {
                return "Зорилтот жингээ оруулна уу"
            } else if user.daysToComplete == nil {
                return "Зорилтот хугацааг оруулна уу"
            }
        case 8:
            return "Хоолны тохиргоогоо сонгоно уу"
        default:
            return "Бүх талбаруудыг гүйцээ бөглөнө үү"
        }
        
        return "Бүх талбаруудыг гүйцээ бөглөнө үү"
    }
    
    private func saveData() {
        isLoading = true
        Task {
            do {
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
                
                // Explicitly set the onboarding completion flag
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                
                dismiss()
            } catch {
                isLoading = false
            }
        }
    }
    
    private func getMaxAllowedStep() -> Int {
        // Users can only progress to the next step if current step is valid
        var maxStep = 1
        
        // Step 1 is always accessible
        maxStep = 1
        
        // Step 2 is accessible after Step 1 is complete (always true for Step 1)
        maxStep = 2
        
        // Step 3 is accessible only if Step 2 is complete
        if user.age != nil && user.sex != nil && user.activityLevel != nil {
            maxStep = 3
        }
        
        // Step 4 is accessible only if Step 3 is complete
        if maxStep >= 3 && user.height != nil && user.weight != nil {
            maxStep = 4
        }
        
        // Step 5 is accessible only if Step 4 is complete
        if maxStep >= 4 && user.bodyFatPercentage != nil {
            maxStep = 5
        }
        
        // Step 6 is accessible only if Step 5 is complete
        if maxStep >= 5 && user.goal != nil {
            maxStep = 6
        }
        
        // Step 7 is accessible only if Step 6 is complete
        if maxStep >= 6 && user.goalWeight != nil && user.daysToComplete != nil {
            maxStep = 7
        }
        
        // Step 8 is accessible only if Step 7 is complete
        if maxStep >= 7 {
            maxStep = 8
        }
        
        return maxStep
    }
    
    private func getStepColor(for step: Int) -> Color {
        let maxAllowed = getMaxAllowedStep()
        
        if step <= maxAllowed {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
