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
    Таны биеийн үзүүлэлтүүд:
    Одоогийн жин: \(Int(weight)) кг
    Өөхний жин: \(Int(fm)) кг
    Булчингийн масс: \(Int(lbm)) кг
    
    Энергийн хэрэглээ:
    Өдрийн нийт илчлэг (TDEE): \(Int(tdee)) ккал
    Суурь бодисын солилцоо (BMR): \(Int(bmr)) ккал
    
    Таны зорилго:
    Өөх тосны хувь \(String(format: "%.1f", newBodyFatPercentage))% болно
    \(daysToComplete) хоногийн турш өдөрт \(Int(goalCalories)) ккал
    (\(Int((safeDailyDeficit / tdee) * 100))% \(goalCalories > safeDailyDeficit ? "хасалт" : "нэмэлт")) хэрэгтэй.
    """
    
    return (resultString, tdee)
}

func calculateMaximumMuscularPotential(height: Double) -> String {
    let lbm = height - 100
    
    let weightAt5Percent = lbm / (1 - 0.05)
    let weightAt10Percent = lbm / (1 - 0.10)
    let weightAt15Percent = lbm / (1 - 0.15)
    
    let result = """
    Мартин Беркханы томьёоны дагуу:
    - 5% өөхтэй үед таны натурал булчингийн дээд боломж \(String(format: "%.1f", weightAt5Percent)) кг байна.
    - 10% өөхтэй үед таны жин \(String(format: "%.1f", weightAt10Percent)) кг байна.
    - 15% өөхтэй үед таны жин \(String(format: "%.1f", weightAt15Percent)) кг байна.
    Хэрэв та булчин нэмэх зорилготой бол эдгээр нь таны зорилго байж болно!
    """
    
    return result
}
