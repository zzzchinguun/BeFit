//
//  ExerciseViewModel.swift
//  BeFit
//
//  Created by AI Assistant on 4/25/25.
//

import Foundation
import Firebase
import FirebaseFirestore


class ExerciseViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var selectedCategory: ExerciseCategory?
    @Published var searchText: String = ""
    
    private let userService = UserService.shared
    
    init() {
        loadDefaultExercises()
        if let user = userService.currentUser {
            fetchUserCustomExercises(userId: user.id)
            fetchUserWorkoutLogs(userId: user.id)
        }
    }
    
    // MARK: - Exercise Methods
    
    private func loadDefaultExercises() {
        // Add default exercises with local identifiers
        var defaultExercises = Exercise.defaultExercises
        
        // Generate local IDs for default exercises since they aren't stored in Firestore
        // but need some form of identifier for referencing
        for i in 0..<defaultExercises.count {
            var exercise = defaultExercises[i]
            // Use a consistent ID format for default exercises using the name
            // This is only for local reference and avoids DocumentID conflicts
            let localId = "local-\(exercise.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
            exercise.id = localId
            defaultExercises[i] = exercise
        }
        
        self.exercises = defaultExercises
        self.filterExercises()
    }
    
    func fetchUserCustomExercises(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("exercises")
            .whereField("createdBy", isEqualTo: userId)
            .whereField("isCustom", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else {
                    print("Error fetching custom exercises: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let customExercises = documents.compactMap { try? $0.data(as: Exercise.self) }
                DispatchQueue.main.async {
                    // Make sure we don't add duplicates
                    let existingNames = Set(self.exercises.map { $0.name.lowercased() })
                    let newExercises = customExercises.filter { !existingNames.contains($0.name.lowercased()) }
                    
                    if !newExercises.isEmpty {
                        self.exercises.append(contentsOf: newExercises)
                        self.filterExercises()
                    }
                }
            }
    }
    
    func addCustomExercise(name: String, category: ExerciseCategory, completion: @escaping (Bool) -> Void) {
        guard let userId = userService.currentUser?.id else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let newExercise = Exercise(
            id: nil,
            name: name,
            category: category,
            isCustom: true,
            createdBy: userId
        )
        
        do {
            let ref = try db.collection("exercises").addDocument(from: newExercise)
            var savedExercise = newExercise
            savedExercise.id = ref.documentID
            
            DispatchQueue.main.async {
                self.exercises.append(savedExercise)
                self.filterExercises()
                completion(true)
            }
        } catch {
            print("Error adding custom exercise: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func deleteCustomExercise(exerciseId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("exercises").document(exerciseId).delete { error in
            if let error = error {
                print("Error deleting exercise: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.exercises.removeAll { $0.id == exerciseId }
                self.filterExercises()
                completion(true)
            }
        }
    }
    
    func filterExercises() {
        if let category = selectedCategory {
            filteredExercises = exercises.filter { $0.category == category }
        } else {
            filteredExercises = exercises
        }
        
        if !searchText.isEmpty {
            filteredExercises = filteredExercises.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // MARK: - Workout Log Methods
    
    func fetchUserWorkoutLogs(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("workoutLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents, error == nil else {
                    print("Error fetching workout logs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let logs = documents.compactMap { try? $0.data(as: WorkoutLog.self) }
                DispatchQueue.main.async {
                    self.workoutLogs = logs
                }
            }
    }
    
    func logWorkout(exerciseId: String, exerciseName: String, sets: [WorkoutSet], notes: String?, completion: @escaping (Bool) -> Void) {
        guard let userId = userService.currentUser?.id else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let workoutLog = WorkoutLog(
            id: nil,
            userId: userId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            date: Date(),
            sets: sets,
            notes: notes
        )
        
        do {
            let ref = try db.collection("workoutLogs").addDocument(from: workoutLog)
            var savedLog = workoutLog
            savedLog.id = ref.documentID
            
            DispatchQueue.main.async {
                self.workoutLogs.insert(savedLog, at: 0)
                completion(true)
            }
        } catch {
            print("Error logging workout: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func deleteWorkoutLog(logId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("workoutLogs").document(logId).delete { error in
            if let error = error {
                print("Error deleting workout log: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.workoutLogs.removeAll { $0.id == logId }
                completion(true)
            }
        }
    }
    
    func getExerciseLogHistory(exerciseId: String) -> [WorkoutLog] {
        return workoutLogs.filter { $0.exerciseId == exerciseId }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - User Methods
    
    /// Returns the current user ID if available
    func getCurrentUserId() -> String? {
        return userService.currentUser?.id
    }
    
    // MARK: - Progress Tracking
    
    func calculateMaxWeight(for exerciseId: String) -> Double {
        let exerciseLogs = getExerciseLogHistory(exerciseId: exerciseId)
        
        let maxWeightSet = exerciseLogs
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
            .max { $0.weight < $1.weight }
        
        return maxWeightSet?.weight ?? 0.0
    }
    
    func calculateMaxVolume(for exerciseId: String) -> Double {
        let exerciseLogs = getExerciseLogHistory(exerciseId: exerciseId)
        
        return exerciseLogs.map { $0.totalVolume }.max() ?? 0.0
    }
}

// UserService stub for getting the current user
class UserService {
    static let shared = UserService()
    var currentUser: User?
    
    private init() {
        // Listen for auth changes from Firebase and update currentUser
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserChange), name: Notification.Name("userSessionChanged"), object: nil)
        
        // Initialize with current user if available
        if let authData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: authData) {
            self.currentUser = user
        }
    }
    
    @objc private func handleUserChange(notification: Notification) {
        if let user = notification.object as? User {
            self.currentUser = user
            
            // Cache the user
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
        } else {
            self.currentUser = nil
            UserDefaults.standard.removeObject(forKey: "currentUser")
        }
    }
} 
