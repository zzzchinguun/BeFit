//
//  Exercise.swift
//  BeFit
//
//  Created by Chinguun Khongor on 4/25/25.
//

import Foundation
import FirebaseFirestore

struct Exercise: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    let name: String
    let category: ExerciseCategory
    let isCustom: Bool
    let createdBy: String? // userId for custom exercises
    
    // Mongolian name for the exercise
    var mongolianName: String {
        switch name {
        // Compound exercises
        case "Deadlift":
            return "Үндсэн таталт"
        case "Back Squat":
            return "Үндсэн суулт"
        case "Front Squat":
            return "Урд талдаа штангтай суух"
        case "Bench Press":
            return "Цээж шахах"
        case "Incline Bench Press":
            return "Налуу хэвтэж шахах"
        case "Decline Bench Press":
            return "Урвуу хэвтэж шахах"
        case "Overhead Press":
            return "Штанг дээшээ түлхэх"
        case "Pull-Up":
            return "Суниах"
        case "Chin-Up":
            return "Эр суниалт"
        case "Dip":
            return "Суга турник суниалт"
        case "Push-Up":
            return "Газар суниах"
        case "Barbell Row":
            return "Нуруун штангийн таталт"
        case "Dumbbell Row":
            return "Гантель мөр"
            
        // Lower Body
        case "Lunge":
            return "Урагшлах"
        case "Leg Press":
            return "Хөл түлхэх"
        case "Romanian Deadlift":
            return "Румын дэдлифт"
        case "Leg Curl":
            return "Хөлний нугалах"
        case "Leg Extension":
            return "Хөлний сунгах"
        case "Calf Raise":
            return "Шилбэ"
        case "Hip Thrust":
            return "Ташааны түлхэлт"
        case "Bulgarian Split Squat":
            return "Болгар хувах скуат"
            
        // Upper Body - Push
        case "Incline Dumbbell Press":
            return "Налуу дамбелийн түлхэх"
        case "Cable Chest Fly":
            return "Кабелийн цээжийн нисэх"
        case "Arnold Press":
            return "Арнольд түлхэлт"
        case "Lateral Raise":
            return "Хажуугийн өргөх"
        case "Triceps Pushdown":
            return "Гурван толгойн доошлуулах"
        case "Overhead Triceps Extension":
            return "Толгой дээр гурван толгойн"
            
        // Upper Body - Pull
        case "Lat Pulldown":
            return "Нурууны өргөн таталт"
        case "Seated Cable Row":
            return "Суугаад кабел татах"
        case "Face Pull":
            return "Нүүр рүү татах"
        case "Barbell Curl":
            return "Штанг 2 толгой"
        case "Dumbbell Curl":
            return "Гантель 2 толгой"
        case "Hammer Curl":
            return "Алх барилт 2 толгой"
            
        // Core
        case "Plank":
            return "Планк"
            
        default:
            return name // Return original name if no translation available
        }
    }
    
    // Get localized name based on language preference
    func localizedName(isEnglish: Bool = false) -> String {
        return isEnglish ? name : mongolianName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case compound = "Compound"
    case lowerBody = "Lower Body"
    case upperBodyPush = "Upper Body - Push"
    case upperBodyPull = "Upper Body - Pull"
    case core = "Core"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    // Mongolian names for exercise categories
    var mongolianName: String {
        switch self {
        case .compound:
            return "Цогц дасгал"
        case .lowerBody:
            return "Хөлний дасгал"
        case .upperBodyPush:
            return "Түлхэх дасгал"
        case .upperBodyPull:
            return "Татах дасгал"
        case .core:
            return "Хэвлийн дасгал"
        case .custom:
            return "Миний дасгал"
        }
    }
    
    // Get localized name based on language preference
    func localizedName(isEnglish: Bool = false) -> String {
        return isEnglish ? self.rawValue : self.mongolianName
    }
}

struct WorkoutSet: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let reps: Int
    let weight: Double // in kg
    let isCompleted: Bool
    
    static func == (lhs: WorkoutSet, rhs: WorkoutSet) -> Bool {
        lhs.id == rhs.id && 
        lhs.reps == rhs.reps && 
        lhs.weight == rhs.weight && 
        lhs.isCompleted == rhs.isCompleted
    }
}

struct WorkoutLog: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let exerciseId: String
    let exerciseName: String
    let date: Date
    var sets: [WorkoutSet]
    let notes: String?
    
    var totalVolume: Double {
        return sets.filter { $0.isCompleted }.reduce(0) { $0 + (Double($1.reps) * $1.weight) }
    }
}

// Default exercise list
extension Exercise {
    static let defaultExercises: [Exercise] = [
        // Compound
        Exercise(id: nil, name: "Deadlift", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Back Squat", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Front Squat", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Bench Press", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Incline Bench Press", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Decline Bench Press", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Overhead Press", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Pull-Up", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Chin-Up", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Dip", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Push-Up", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Barbell Row", category: .compound, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Dumbbell Row", category: .compound, isCustom: false, createdBy: nil),
        
        // Lower Body
        Exercise(id: nil, name: "Lunge", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Leg Press", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Romanian Deadlift", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Leg Curl", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Leg Extension", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Calf Raise", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Hip Thrust", category: .lowerBody, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Bulgarian Split Squat", category: .lowerBody, isCustom: false, createdBy: nil),
        
        // Upper Body - Push
        Exercise(id: nil, name: "Incline Dumbbell Press", category: .upperBodyPush, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Cable Chest Fly", category: .upperBodyPush, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Arnold Press", category: .upperBodyPush, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Lateral Raise", category: .upperBodyPush, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Triceps Pushdown", category: .upperBodyPush, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Overhead Triceps Extension", category: .upperBodyPush, isCustom: false, createdBy: nil),
        
        // Upper Body - Pull
        Exercise(id: nil, name: "Lat Pulldown", category: .upperBodyPull, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Seated Cable Row", category: .upperBodyPull, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Face Pull", category: .upperBodyPull, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Barbell Curl", category: .upperBodyPull, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Dumbbell Curl", category: .upperBodyPull, isCustom: false, createdBy: nil),
        Exercise(id: nil, name: "Hammer Curl", category: .upperBodyPull, isCustom: false, createdBy: nil),
        
        // Core
        Exercise(id: nil, name: "Plank", category: .core, isCustom: false, createdBy: nil)
    ]
    
    // Example workout logs
    static let sampleWorkoutLogs: [WorkoutLog] = [
        WorkoutLog(
            id: nil,
            userId: "user123",
            exerciseId: "benchpress",
            exerciseName: "Bench Press",
            date: Date(),
            sets: [
                WorkoutSet(id: nil, reps: 8, weight: 60.0, isCompleted: true),
                WorkoutSet(id: nil, reps: 8, weight: 65.0, isCompleted: true),
                WorkoutSet(id: nil, reps: 6, weight: 70.0, isCompleted: true)
            ],
            notes: "Feeling strong today"
        )
    ]
} 
