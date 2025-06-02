import Foundation

struct FitnessCalculations {
    
    // MARK: - BMR Calculation using Mifflin-St Jeor equation (most accurate)
    static func calculateBMR(weight: Double, height: Double, age: Int, sex: String) -> Double {
        if sex == "Male" {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
    }
    
    // MARK: - TDEE Calculation (Legion Athletics Method)
    static func calculateTDEE(user: User) -> (resultString: String, tdee: Double, goalCalories: Double)? {
        guard let weight = user.weight,
              let height = user.height,
              let age = user.age,
              let activityLevel = user.activityLevel,
              let bodyFatPercentage = user.bodyFatPercentage,
              let goalWeight = user.goalWeight,
              let daysToComplete = user.daysToComplete,
              let goal = user.goal else { return nil }
        
        // Use Mifflin-St Jeor Equation (more accurate than Harris-Benedict)
        let bmr: Double
        if user.sex == "Male" {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        
        // Activity level multipliers (Legion Athletics values - adjusted)
        let activityMultiplier: Double
        switch activityLevel {
        case "Суугаа амьдралын хэв маяг": activityMultiplier = 1.2
        case "Хөнгөн идэвхтэй": activityMultiplier = 1.375
        case "Дунд зэрэг идэвхтэй": activityMultiplier = 1.5  // Slightly lower than standard
        case "Идэвхтэй": activityMultiplier = 1.7
        case "Маш идэвхтэй": activityMultiplier = 1.9
        default: activityMultiplier = 1.375
        }
        
        let tdee = bmr * activityMultiplier
        
        // Calculate body composition
        let leanBodyMass = calculateLeanBodyMass(weight: weight, bodyFatPercentage: bodyFatPercentage)
        let fatMass = calculateFatMass(weight: weight, bodyFatPercentage: bodyFatPercentage)
        
        var resultString = """
        === ТАНЫ БИЕИЙН ҮЗҮҮЛЭЛТ ===
        Нас: \(age) нас
        Жин: \(String(format: "%.1f", weight)) кг
        Өндөр: \(String(format: "%.1f", height)) см
        Биеийн өөх: \(String(format: "%.1f", bodyFatPercentage))%
        Идэвхийн түвшин: \(activityLevel)
        
        === МЕТАБОЛИЗМЫН ТООЦООЛОЛ ===
        Үндсэн метаболизм (BMR): \(Int(bmr)) ккал/өдөр
        Нийт өдрийн зарцуулалт (TDEE): \(Int(tdee)) ккал/өдөр
        
        === БИЕИЙН НАЙРЛАГА ===
        Булчингийн масс: \(String(format: "%.1f", leanBodyMass)) кг
        Өөхний масс: \(String(format: "%.1f", fatMass)) кг
        """
        
        let weightDifference = goalWeight - weight
        var goalCalories = tdee // Default to maintenance if no weight change
        
        if goal == "Жин хасах" || weightDifference < 0 {
            // Legion Athletics Weight Loss Method
            let totalWeightLoss = abs(weightDifference)
            let weeksToComplete = Double(daysToComplete) / 7.0
            let weeklyWeightLoss = totalWeightLoss / weeksToComplete
            
            // Calculate calorie deficit needed (Legion method)
            // They use 7700 calories per kg but account for metabolic adaptation
            let totalCalorieDeficitNeeded = totalWeightLoss * 7700
            let dailyCalorieDeficit = totalCalorieDeficitNeeded / Double(daysToComplete)
            
            // Legion's target calories (what they recommend to reach goal)
            let targetCalories = Int(tdee - dailyCalorieDeficit)
            goalCalories = Double(targetCalories) // Store the goal calories
            let deficitPercentage = (dailyCalorieDeficit / tdee) * 100
            
            // Legion's conservative recommendations  
            let maxRecommendedDeficit: Double
            if user.sex == "Male" {
                maxRecommendedDeficit = min(tdee * 0.22, 600) // Max 22% or 600 calories
            } else {
                maxRecommendedDeficit = min(tdee * 0.37, 660) // Females can handle higher deficit %
            }
            
            let recommendedCalories = Int(tdee - maxRecommendedDeficit)
            let recommendedDeficitPercentage = (maxRecommendedDeficit / tdee) * 100
            
            // Body fat calculation (Legion method)
            // They appear to use a more aggressive fat loss assumption
            let currentFatMass = weight * (bodyFatPercentage / 100)
            
            // Legion seems to assume about 85-90% of weight loss is fat
            let fatLossRatio: Double
            if weeklyWeightLoss <= 0.5 {
                fatLossRatio = 0.85  // Adjusted to match Legion
            } else if weeklyWeightLoss <= 0.75 {
                fatLossRatio = 0.80
            } else if weeklyWeightLoss <= 1.0 {
                fatLossRatio = 0.75
            } else {
                fatLossRatio = 0.70
            }
            
            let expectedFatLoss = totalWeightLoss * fatLossRatio
            let finalFatMass = currentFatMass - expectedFatLoss
            let finalBodyFat = (finalFatMass / goalWeight) * 100
            
            resultString += """
            
            === ЖИНГ ХАСАХ ТӨЛӨВЛӨГӨӨ ===
            Хасах жин: \(String(format: "%.1f", totalWeightLoss)) кг
            Хугацаа: \(daysToComplete) өдөр (\(Int(weeksToComplete)) долоо хоног)
            
            === КАЛОРИЙН ЗОРИЛТ ===
            Зорилгод хүрэхийн тулд: \(targetCalories) ккал (\(Int(deficitPercentage))% дефицит)
            Эрүүл зөвшөөрөл: \(recommendedCalories) ккал (\(Int(recommendedDeficitPercentage))% дефицит)
            Долоо хоногийн жингийн хасалт: \(String(format: "%.2f", weeklyWeightLoss)) кг
            
            === УРЬДЧИЛСАН ҮР ДҮН ===
            Зорилтод хүрсэний дараах жин: \(String(format: "%.1f", goalWeight)) кг
            Зорилтод хүрсэний дараах биеийн өөх: \(String(format: "%.0f", max(finalBodyFat, 5.0)))%
            """
            
            if weeklyWeightLoss > 1.0 {
                resultString += """
                
                ⚠️ АНХААРУУЛГА: Хэт хурдан жин хасах нь 
                булчингийн алдагдалд хүргэж болзошгүй.
                Эрүүл зөвлөмж: 7 хоногт 0.5-1.0кг хасах
                """
            }
            
            if deficitPercentage > 30 {
                resultString += """
                
                ⚠️ Агрессив дефицит: Энэ нь маш том калорийн дефицит байна.
                Булчингийн алдагдал, метаболизмын уналт болж болзошгүй.
                """
            }
        } else if goal == "Жин нэмэх" && weightDifference > 0 {
            // Weight Gain Logic
            let weeklyGain = weightDifference / (Double(daysToComplete) / 7.0)
            let calorieSurplus = weeklyGain * 7700 / 7 // Daily surplus needed
            let targetCalories = Int(tdee + calorieSurplus)
            goalCalories = Double(targetCalories) // Store the goal calories
            
            // Estimate muscle vs fat gain (assumes good training and nutrition)
            let muscleGainRatio: Double = weeklyGain <= 0.5 ? 0.75 : 0.5 // 75% muscle if slow gain
            let expectedMuscleGain = weightDifference * muscleGainRatio
            let expectedFatGain = weightDifference * (1 - muscleGainRatio)
            
            let projectedLBM = leanBodyMass + expectedMuscleGain
            let projectedFM = fatMass + expectedFatGain
            let projectedBodyFat = (projectedFM / goalWeight) * 100
            
            resultString += """
            
            === ЖИНГ НЭМЭХ ТӨЛӨВЛӨГӨӨ ===
            Нэмэх жин: \(String(format: "%.1f", weightDifference)) кг
            Хугацаа: \(daysToComplete) өдөр (\(Int(Double(daysToComplete)/7)) долоо хоног)
            
            === КАЛОРИЙН ЗОРИЛТ ===
            Өдрийн калори: \(targetCalories) ккал
            Калорийн илүү: +\(Int(calorieSurplus)) ккал
            Долоо хоногийн жингийн нэмэгдэл: \(String(format: "%.2f", weeklyGain)) кг
            
            === УРЬДЧИЛСАН ҮР ДҮН ===
            Урьдчилсан булчин: +\(String(format: "%.1f", expectedMuscleGain)) кг
            Урьдчилсан өөх: +\(String(format: "%.1f", expectedFatGain)) кг
            Зорилтод хүрсэний дараах биеийн өөх: \(String(format: "%.1f", projectedBodyFat))%
            """
            
            if weeklyGain > 0.5 {
                resultString += """
                
                ⚠️ АНХААРУУЛГА: Хэт хурдан жин нэмэх нь 
                өөхний хуримтлалыг ихэсгэж болзошгүй.
                Эрүүл зөвлөмж: 7 хоногт 0.25-0.5кг нэмэх
                """
            }
        }
        
        return (resultString: resultString, tdee: tdee, goalCalories: goalCalories)
    }
    
    // MARK: - Body Composition Calculations
    static func calculateLeanBodyMass(weight: Double, bodyFatPercentage: Double) -> Double {
        return weight * (1 - (bodyFatPercentage / 100))
    }
    
    static func calculateFatMass(weight: Double, bodyFatPercentage: Double) -> Double {
        return weight * (bodyFatPercentage / 100)
    }
    
    // MARK: - Weight Loss Calculations (More accurate method)
    static func calculateOptimalCalorieDeficit(
        currentWeight: Double,
        goalWeight: Double,
        daysToComplete: Int,
        tdee: Double,
        bodyFatPercentage: Double
    ) -> (targetCalories: Int, deficitPercentage: Double, weeklyWeightLoss: Double, minCalories: Int, maxDeficit: Int, projectedBodyFat: Double) {
        
        let totalWeightLoss = currentWeight - goalWeight
        let weeksToComplete = Double(daysToComplete) / 7.0
        
        // Calculate current body composition
        let currentLBM = calculateLeanBodyMass(weight: currentWeight, bodyFatPercentage: bodyFatPercentage)
        let currentFM = calculateFatMass(weight: currentWeight, bodyFatPercentage: bodyFatPercentage)
        
        // Calculate weekly weight loss rate
        let weeklyWeightLoss = totalWeightLoss / weeksToComplete
        
        // More accurate body fat calculation
        // Assume 70-80% of weight loss comes from fat when in moderate deficit
        let fatLossRatio: Double
        if abs(weeklyWeightLoss) <= 0.5 {
            fatLossRatio = 0.85 // 85% fat loss - optimal rate
        } else if abs(weeklyWeightLoss) <= 0.75 {
            fatLossRatio = 0.75 // 75% fat loss - acceptable
        } else if abs(weeklyWeightLoss) <= 1.0 {
            fatLossRatio = 0.70 // 70% fat loss - aggressive
        } else {
            fatLossRatio = 0.60 // 60% fat loss - too aggressive
        }
        
        // Calculate projected body composition at goal weight
        let totalFatLoss = totalWeightLoss * fatLossRatio
        let totalMuscleLosList = totalWeightLoss - totalFatLoss
        
        let projectedFM = currentFM - totalFatLoss
        let projectedLBM = currentLBM - totalMuscleLosList
        let projectedBodyFat = (projectedFM / goalWeight) * 100
        
        // Simpler calorie calculation: 1 kg fat = 7700 calories
        // Use primarily fat loss for calorie calculation since that's the main component
        let totalCalorieDeficitNeeded = totalFatLoss * 7700
        let dailyDeficit = totalCalorieDeficitNeeded / Double(daysToComplete)
        
        // Calculate minimum calories (BMR * 1.2 as absolute minimum)
        let bmrEstimate = tdee / getActivityMultiplier(activityLevel: "Дунд зэрэг идэвхтэй") // Use moderate as base
        let minCalories = Int(bmrEstimate * 1.2)
        
        // Calculate maximum safe deficit (25% of TDEE for aggressive but safe deficit)
        let maxDeficitFromTDEE = tdee * 0.25
        let maxDeficit = min(maxDeficitFromTDEE, 750) // Cap at 750 calories per day
        
        // Determine target calories
        let targetCalories: Double
        let actualDeficit: Double
        
        if dailyDeficit <= maxDeficit {
            // Safe deficit rate
            targetCalories = tdee - dailyDeficit
            actualDeficit = dailyDeficit
        } else {
            // Cap at maximum safe deficit
            targetCalories = tdee - maxDeficit
            actualDeficit = maxDeficit
        }
        
        // Ensure we don't go below minimum calories
        let finalTargetCalories = max(targetCalories, Double(minCalories))
        let finalDeficit = tdee - finalTargetCalories
        
        let deficitPercentage = (finalDeficit / tdee) * 100
        let adjustedWeeklyLoss = (finalDeficit * 7) / 7700
        
        return (
            targetCalories: Int(finalTargetCalories),
            deficitPercentage: deficitPercentage,
            weeklyWeightLoss: adjustedWeeklyLoss,
            minCalories: minCalories,
            maxDeficit: Int(maxDeficit),
            projectedBodyFat: max(projectedBodyFat, 5.0) // Minimum realistic body fat for males
        )
    }
    
    // Helper function to get activity multiplier
    static func getActivityMultiplier(activityLevel: String) -> Double {
        switch activityLevel {
        case "Суугаа амьдралын хэв маяг": return 1.2
        case "Хөнгөн идэвхтэй": return 1.375
        case "Дунд зэрэг идэвхтэй": return 1.55
        case "Идэвхтэй": return 1.725
        case "Маш идэвхтэй": return 1.9
        default: return 1.375
        }
    }
    
    // MARK: - Macronutrient Calculations
    static func calculateMacros(
        targetCalories: Int,
        weight: Double,
        goal: String,
        bodyFatPercentage: Double
    ) -> Macros {
        
        let leanBodyMass = calculateLeanBodyMass(weight: weight, bodyFatPercentage: bodyFatPercentage)
        
        // Protein: 1.6-2.2g per kg of body weight (higher for cutting)
        let proteinPerKg: Double
        switch goal {
        case "Жин хасах":
            proteinPerKg = 2.2 // Higher protein for muscle preservation during cut
        case "Жин нэмэх":
            proteinPerKg = 1.8 // Moderate protein for bulking
        default:
            proteinPerKg = 2.0 // Maintenance
        }
        
        let proteinGrams = Int(weight * proteinPerKg)
        let proteinCalories = proteinGrams * 4
        
        // Fat: 0.8-1.2g per kg body weight (minimum for hormone production)
        let fatPerKg: Double = bodyFatPercentage > 15 ? 0.8 : 1.0
        let fatGrams = Int(weight * fatPerKg)
        let fatCalories = fatGrams * 9
        
        // Carbs: Fill remaining calories
        let remainingCalories = targetCalories - proteinCalories - fatCalories
        let carbsGrams = max(Int(remainingCalories / 4), 0)
        
        return Macros(protein: proteinGrams, carbs: carbsGrams, fat: fatGrams)
    }
}

func calculateMaximumMuscularPotential(height: Double) -> String {
    // Martin Berkhan's formula for maximum muscular potential
    let lbm = height - 100
    
    let weightAt5Percent = lbm / (1 - 0.05)
    let weightAt10Percent = lbm / (1 - 0.10)
    let weightAt15Percent = lbm / (1 - 0.15)
    
    let result = """
    💪 Натурал булчингийн дээд боломж:
    
    📏 Мартин Беркханы томьёо (өндөр - 100):
    • Булчингийн масс: \(String(format: "%.1f", lbm)) кг
    
    🎯 Боломжит жин:
    • 5% биеийн өөх: \(String(format: "%.1f", weightAt5Percent)) кг
    • 10% биеийн өөх: \(String(format: "%.1f", weightAt10Percent)) кг  
    • 15% биеийн өөх: \(String(format: "%.1f", weightAt15Percent)) кг
    
    ⚠️ Анхаарал:
    • Эдгээр тоо нь таны генетикийн дээд хязгаар
    • 2-5 жил тогтмол дасгал хийсний дараа хүрэх боломжтой
    • Хувь хүнээс хамаарч өөр байж болно
    """
    
    return result
}
