//
//  User.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/14/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    
    // Onboarding data
    var age: Int?
    var weight: Double?
    var height: Double?
    var sex: String?
    var activityLevel: String?
    var bodyFatPercentage: Double?
    var goalWeight: Double?
    var daysToComplete: Int?
    var goalStartDate: Date? // New field to track when the goal was started
    var goal: String?
    var tdee: Double?
    var goalCalories: Double? // Daily calorie target (TDEE adjusted for deficit/surplus)
    var macros: Macros?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: "\(firstName) \(lastName)") {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
    }
    
    // MARK: - Computed Properties for Goal Tracking
    
    /// Calculate the actual remaining days based on start date and total days
    var remainingDays: Int {
        guard let startDate = goalStartDate,
              let totalDays = daysToComplete else { return daysToComplete ?? 0 }
        
        let daysPassed = Calendar.current.dateComponents([.day], 
                                                       from: Calendar.current.startOfDay(for: startDate), 
                                                       to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return max(0, totalDays - daysPassed)
    }
    
    /// Calculate how many days have passed since the goal started
    var daysPassed: Int {
        guard let startDate = goalStartDate else { return 0 }
        
        return Calendar.current.dateComponents([.day], 
                                             from: Calendar.current.startOfDay(for: startDate), 
                                             to: Calendar.current.startOfDay(for: Date())).day ?? 0
    }
    
    /// Calculate the progress percentage (0.0 to 1.0)
    var goalProgressPercentage: Double {
        guard let totalDays = daysToComplete, totalDays > 0 else { return 0.0 }
        
        let progress = Double(daysPassed) / Double(totalDays)
        return min(1.0, max(0.0, progress)) // Clamp between 0 and 1
    }
    
    /// Check if the goal has expired (remaining days = 0)
    var isGoalExpired: Bool {
        return remainingDays <= 0 && goalStartDate != nil
    }
    
    /// Get the estimated goal completion date
    var goalEndDate: Date? {
        guard let startDate = goalStartDate,
              let totalDays = daysToComplete else { return nil }
        
        return Calendar.current.date(byAdding: .day, value: totalDays, to: startDate)
    }
}

struct Macros: Codable {
    var protein: Int
    var carbs: Int
    var fat: Int
}

extension User {
    static var MOCK_USER = User(
        id: NSUUID().uuidString,
        firstName: "Chinguun",
        lastName: "Khongor",
        email: "test@gmail.com",
        age: 25,
        weight: 70.0,
        height: 175.0,
        sex: "male",
        activityLevel: "moderate",
        bodyFatPercentage: 15.0,
        goalWeight: 65.0,
        daysToComplete: 60,
        goalStartDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()), // Started 10 days ago
        goal: "weight_loss",
        tdee: 2300.0,
        goalCalories: 1800.0, // Example goal calories (TDEE - deficit)
        macros: Macros(protein: 140, carbs: 250, fat: 60)
    )
}
