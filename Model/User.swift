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
    var goal: String?
    var tdee: Double?
    var macros: Macros?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: "\(firstName) \(lastName)") {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
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
        goal: "weight_loss",
        tdee: 2300.0,
        macros: Macros(protein: 140, carbs: 250, fat: 60)
    )
}
