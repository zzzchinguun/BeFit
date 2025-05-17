//
//  FirebaseService.swift
//  BeFit
//
//  Created by AI Assistant on 5/8/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Error types specific to Firebase operations
enum FirebaseError: Error {
    case authError(String)
    case databaseError(String)
    case networkError(String)
    case unknownError(String)
    
    var localizedDescription: String {
        switch self {
        case .authError(let message): return "Authentication error: \(message)"
        case .databaseError(let message): return "Database error: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        case .unknownError(let message): return "Unknown error: \(message)"
        }
    }
}

/// Base service for Firebase functionality
class FirebaseService {
    // MARK: - Properties
    let db = Firestore.firestore()
    var auth: Auth { Auth.auth() }
    
    // MARK: - Helper Methods
    
    /// Converts Firebase errors to app-specific errors
    func handleError(_ error: Error) -> FirebaseError {
        let nsError = error as NSError
        
        // For Firebase Authentication errors
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case AuthErrorCode.networkError.rawValue:
                return .networkError(error.localizedDescription)
            case AuthErrorCode.wrongPassword.rawValue, 
                 AuthErrorCode.invalidEmail.rawValue, 
                 AuthErrorCode.userNotFound.rawValue, 
                 AuthErrorCode.emailAlreadyInUse.rawValue:
                return .authError(error.localizedDescription)
            default:
                return .authError(error.localizedDescription)
            }
        }
        
        // For Firestore errors
        if nsError.domain == FirestoreErrorDomain {
            return .databaseError(error.localizedDescription)
        }
        
        // Default case
        return .unknownError(error.localizedDescription)
    }
    
    /// Gets the current user ID if available
    func getCurrentUserId() -> String? {
        return auth.currentUser?.uid
    }
} 