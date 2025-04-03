import Foundation

func calculateTDEE(user: User) -> (resultString: String, tdee: Double) {
    let weight = user.weight ?? 0
    let height = user.height ?? 0
    let age = user.age ?? 0
    let sex = user.sex ?? ""
    let activityLevel = user.activityLevel ?? ""
    let bodyFatPercentage = user.bodyFatPercentage ?? 0
    let goalWeight = user.goalWeight ?? 0
    let daysToComplete = user.daysToComplete ?? 90
    
    let bmr: Double = {
        if sex == "Male" {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }()
    
    let activityMultiplier: Double = {
        switch activityLevel {
        case "Sedentary": return 1.2
        case "Lightly Active": return 1.375
        case "Moderately Active": return 1.55
        case "Very Active": return 1.725
        default: return 1.375
        }
    }()
    
    let tdee = bmr * activityMultiplier
    let lbm = Double(weight) * (1 - (bodyFatPercentage / 100))
    let fm = Double(weight) - lbm
    
    let totalWeightLoss = Double(weight) - goalWeight
    let fatLoss = totalWeightLoss * 0.8
    let newFatMass = max(fm - fatLoss, 0)
    let newBodyFatPercentage = (newFatMass / goalWeight) * 100
    
    let metabolicAdaptationFactor = 0.95
    let adjustedTdee = tdee * metabolicAdaptationFactor
    
    let weeklyDeficit = (totalWeightLoss * 7700) / Double(daysToComplete) * 7
    let dailyDeficit = weeklyDeficit / 7
    
    let maxDeficit = tdee * 0.5
    let safeDailyDeficit = min(dailyDeficit, maxDeficit)
    
    let goalCalories = adjustedTdee - safeDailyDeficit
    
    let resultString = """
    Weight: \(Int(weight)) kg
    Fat Mass: \(Int(fm)) kg
    TDEE: \(Int(tdee)) kcal, BMR: \(Int(bmr)) kcal, LBM: \(Int(lbm)) kg
    Your body fat percentage will be \(String(format: "%.1f", newBodyFatPercentage))%
    You will need to eat \(Int(goalCalories)) calories (\(Int((safeDailyDeficit / tdee) * 100))% deficit) per day for \(daysToComplete) days to reach your goal.
    """
    
    return (resultString, tdee)
}

func calculateMaximumMuscularPotential(height: Double) -> String {
    let lbm = height - 100
    
    let weightAt5Percent = lbm / (1 - 0.05)
    let weightAt10Percent = lbm / (1 - 0.10)
    let weightAt15Percent = lbm / (1 - 0.15)
    
    let result = """
    According to Martin Berkhan's formula:
    - Your maximum muscular potential is \(String(format: "%.1f", weightAt5Percent)) kg at 5% body fat.
    - At 10% body fat, you'd weigh \(String(format: "%.1f", weightAt10Percent)) kg.
    - At 15% body fat, you'd weigh \(String(format: "%.1f", weightAt15Percent)) kg.
    These are good goals to aim for if you are bulking up!
    """
    
    return result
}