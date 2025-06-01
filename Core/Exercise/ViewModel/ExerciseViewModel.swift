//
//  ExerciseViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 4/25/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth


class ExerciseViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var selectedCategory: ExerciseCategory?
    @Published var searchText: String = ""
    @Published var errorMessage: String?
    
    private let userService = UserService.shared
    
    init() {
        loadDefaultExercises()
        
        // Check if user is authenticated
        if let user = userService.currentUser {
            fetchUserCustomExercises(userId: user.id)
            fetchUserWorkoutLogs(userId: user.id)
        } else {
            // No authenticated user - only show default exercises
            print("No authenticated user found. Only showing default exercises.")
            
            // Try to refresh auth state - maybe we have a Firebase session but lost the local user
            userService.tryRefreshAuth()
        }
        
        // Add observer for user session changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSessionChange),
            name: Notification.Name("userSessionChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleUserSessionChange(_ notification: Notification) {
        if let user = notification.object as? User {
            // User logged in
            fetchUserCustomExercises(userId: user.id)
            fetchUserWorkoutLogs(userId: user.id)
        } else {
            // User logged out
            DispatchQueue.main.async {
                self.workoutLogs = []
                self.exercises = Exercise.defaultExercises
                self.filterExercises()
            }
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
                guard let self = self else { return }
                
                if let error = error {
                    let errorMsg = "Error fetching custom exercises: \(error.localizedDescription)"
                    print(errorMsg)
                    
                    // Check if it's an authentication error
                    let nsError = error as NSError
                    if nsError.domain == FirestoreErrorDomain && 
                       (nsError.code == FirestoreErrorCode.permissionDenied.rawValue ||
                        nsError.code == FirestoreErrorCode.unauthenticated.rawValue) {
                        // Try to refresh authentication
                        userService.tryRefreshAuth()
                    }
                    
                    // Update published error message
                    DispatchQueue.main.async {
                        self.errorMessage = errorMsg
                        
                        // Also post notification for views that might be listening
                        NotificationCenter.default.post(
                            name: Notification.Name("exerciseError"), 
                            object: errorMsg
                        )
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No custom exercises found")
                    return
                }
                
                let customExercises = documents.compactMap { document -> Exercise? in
                    do {
                        return try document.data(as: Exercise.self)
                    } catch {
                        let decodingError = "Error decoding exercise: \(error.localizedDescription)"
                        print(decodingError)
                        
                        DispatchQueue.main.async {
                            self.errorMessage = decodingError
                        }
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    // Clear any previous error
                    self.errorMessage = nil
                    
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
                guard let self = self else { return }
                
                if let error = error {
                    let errorMsg = "Error fetching workout logs: \(error.localizedDescription)"
                    print(errorMsg)
                    
                    DispatchQueue.main.async {
                        self.errorMessage = errorMsg
                        
                        // Check if it's an index error
                        if error.localizedDescription.contains("requires an index") {
                            // Try fetching without ordering as a fallback
                            self.fetchWorkoutLogsWithoutOrdering(userId: userId)
                        } else {
                            // Notify about the error
                            NotificationCenter.default.post(
                                name: Notification.Name("exerciseError"), 
                                object: errorMsg
                            )
                        }
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                let logs = documents.compactMap { try? $0.data(as: WorkoutLog.self) }
                DispatchQueue.main.async {
                    self.workoutLogs = logs
                    // Clear any error if the fetch was successful
                    self.errorMessage = nil
                }
            }
    }
    
    private func fetchWorkoutLogsWithoutOrdering(userId: String) {
        let db = Firestore.firestore()
        
        db.collection("workoutLogs")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    let errorMsg = "Error fetching workout logs without ordering: \(error.localizedDescription)"
                    print(errorMsg)
                    
                    DispatchQueue.main.async {
                        self.errorMessage = errorMsg
                        
                        // Notify about the error
                        NotificationCenter.default.post(
                            name: Notification.Name("exerciseError"), 
                            object: errorMsg
                        )
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                let logs = documents.compactMap { try? $0.data(as: WorkoutLog.self) }
                    .sorted { $0.date > $1.date } // Sort in memory instead
                
                DispatchQueue.main.async {
                    self.workoutLogs = logs
                    // Clear any error if the fetch was successful
                    self.errorMessage = nil
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
    
    // MARK: - Navigation State Management
    
    /// Reset navigation state to prevent conflicts when switching between features
    func resetNavigationState() {
        print("🔄 ExerciseViewModel: Resetting navigation state")
        
        // Clear any error states
        errorMessage = nil
        
        // Reset search and filters
        searchText = ""
        selectedCategory = nil
        
        // Re-filter exercises with clean state
        filterExercises()
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - User Management
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
    
    // Try to refresh authentication state with Firebase
    func tryRefreshAuth() {
        // Check Firebase auth state directly
        if let uid = Auth.auth().currentUser?.uid {
            // We have a Firebase authenticated user, but no local user object
            // This might happen if the app was force closed or cache was cleared
            
            // Notify the AuthService to refresh user data from Firestore
            NotificationCenter.default.post(
                name: Notification.Name("requestUserRefresh"),
                object: uid
            )
        }
    }
} 
