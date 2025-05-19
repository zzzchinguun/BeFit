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
                            .fill(currentStep >= step ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: UIScreen.main.bounds.width / CGFloat(totalSteps + 1), height: 4)
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: currentStep == step ? 2 : 0)
                                    .scaleEffect(1.2)
                            )
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
                Step5GoalWeightDaysView(user: $user)
                    .tag(7)
                    .padding()
                    .focused($isAnyFieldFocused)
                Step7MacroView(user: $user)
                    .tag(8)
                    .padding()
                    .focused($isAnyFieldFocused)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .disabled(true)
            .gesture(DragGesture())
            
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
        .onChange(of: currentStep) { _ in
            validationMessage = nil
        }
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
        case 7: return "Таны тооцоолсон үр дүнг харуулж байна"
        case 8: return "Хооллолтын төлөвлөгөөгөө тохируулна уу"
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1: return true
        case 2: return user.age != nil && user.sex != nil
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
            if user.age == nil && user.sex == nil {
                return "Насаа болон хүйсээ оруулна уу"
            } else if user.age == nil {
                return "Насаа оруулна уу"
            } else if user.sex == nil {
                return "Хүйсээ сонгоно уу"
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
                    goal: user.goal,
                    tdee: user.tdee,
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
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
