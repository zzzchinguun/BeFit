import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class WeightLogViewModel: ObservableObject {
    @Published var weightLogs: [WeightLog] = []
    @Published var isLoggingWeight: Bool = false
    @Published var isLoadingLogs: Bool = false
    @Published var newWeight: Double = 70.0
    @Published var weightNote: String = ""
    @Published var errorMessage: String? = nil
    
    private let userService: UserService = UserService.shared
    
    init() {
        if let user = userService.currentUser {
            fetchWeightLogs()
        }
        
        // Add observer for user session changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSessionChange),
            name: Notification.Name("userSessionChanged"),
            object: nil
        )
        
        // Add observer for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleUserSessionChange(_ notification: Notification) {
        if let _ = notification.object as? User {
            // User logged in
            fetchWeightLogs()
        } else {
            // User logged out
            DispatchQueue.main.async {
                self.weightLogs = []
            }
        }
    }
    
    @objc private func handleAppBecameActive() {
        if userService.currentUser != nil {
            fetchWeightLogs()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if user has logged weight today
    var hasLoggedWeightToday: Bool {
        WeightLog.hasLoggedToday(logs: weightLogs)
    }
    
    /// Log a new weight entry
    func logWeight(weight: Double, note: String?, completion: @escaping (Bool) -> Void) {
        guard let userId = userService.currentUser?.id else {
            errorMessage = "User not logged in"
            completion(false)
            return
        }
        
        isLoggingWeight = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let weightLog = WeightLog(
            id: nil,
            userId: userId,
            weight: weight,
            date: Date(),
            note: note
        )
        
        do {
            let ref = try db.collection("weightLogs").addDocument(from: weightLog)
            var savedLog = weightLog
            savedLog.id = ref.documentID
            
            DispatchQueue.main.async {
                self.weightLogs.insert(savedLog, at: 0)
                
                // Update user's current weight if it's different
                if let currentWeight = self.userService.currentUser?.weight, currentWeight != weight {
                    Task {
                        try? await self.updateUserWeight(weight: weight)
                    }
                }
                
                self.isLoggingWeight = false
                completion(true)
            }
        } catch {
            print("Error logging weight: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoggingWeight = false
                self.errorMessage = "Failed to log weight: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    /// Update user's current weight
    private func updateUserWeight(weight: Double) async throws {
        guard let userId = userService.currentUser?.id else { return }
        
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "weight": weight
        ])
    }
    
    /// Fetch weight logs for current user
    func fetchWeightLogs() {
        guard let userId = userService.currentUser?.id else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoadingLogs = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("weightLogs")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoadingLogs = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to fetch logs: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.errorMessage = "No documents found"
                        return
                    }
                    
                    let logs = documents.compactMap { try? $0.data(as: WeightLog.self) }
                    self.weightLogs = logs
                }
            }
    }
    
    /// Reset form
    func resetForm() {
        newWeight = userService.currentUser?.weight ?? 70.0
        weightNote = ""
        errorMessage = nil
    }
}