//
//  DependencyInjection.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import SwiftUI

/// Property wrapper for injecting services
@propertyWrapper
struct InjectService<T> {
    let wrappedValue: T
    
    init(_ keyPath: KeyPath<ServiceContainer, T>) {
        self.wrappedValue = ServiceContainer.shared[keyPath: keyPath]
    }
}

/// A factory for creating main actor-isolated view models
struct ViewModelFactory {
    /// Creates an AuthViewModel on the main actor
    @MainActor
    static func createAuthViewModel() -> AuthViewModel {
        return AuthViewModel(authService: ServiceContainer.shared.authService)
    }
    
    /// Creates a MealViewModel on the main actor
    @MainActor
    static func createMealViewModel() -> MealViewModel {
        return MealViewModel(mealService: ServiceContainer.shared.mealService)
    }
    
    /// Creates a ProfileViewModel on the main actor
    @MainActor
    static func createProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(authService: ServiceContainer.shared.authService)
    }
    
    /// Creates a WeightLogViewModel on the main actor
    @MainActor
    static func createWeightLogViewModel() -> WeightLogViewModel {
        return WeightLogViewModel()
    }
    
    /// Creates a NotificationViewModel on the main actor
    @MainActor
    static func createNotificationViewModel() -> NotificationViewModel {
        return NotificationViewModel()
    }
    
    /// Creates a MealVerificationViewModel on the main actor
    @MainActor
    static func createMealVerificationViewModel() -> MealVerificationViewModel {
        return MealVerificationViewModel(mealVerificationService: ServiceContainer.shared.mealVerificationService)
    }
}

/// A SwiftUI view modifier that injects common environment objects into the view hierarchy
struct EnvironmentObjectsModifier: ViewModifier {
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var mealViewModel: MealViewModel
    @StateObject private var notificationViewModel: NotificationViewModel
    
    init() {
        // Use StateObject with the @MainActor-isolated factory methods
        // This is safe because SwiftUI's body method runs on the main actor
        self._authViewModel = StateObject(wrappedValue: ViewModelFactory.createAuthViewModel())
        self._mealViewModel = StateObject(wrappedValue: ViewModelFactory.createMealViewModel())
        self._notificationViewModel = StateObject(wrappedValue: ViewModelFactory.createNotificationViewModel())
    }
    
    func body(content: Content) -> some View {
        content
            .environmentObject(authViewModel)
            .environmentObject(mealViewModel)
            .environmentObject(notificationViewModel)
    }
}

extension View {
    /// Injects all common environment objects into the view
    func withInjectedEnvironment() -> some View {
        modifier(EnvironmentObjectsModifier())
    }
}

// Add a method to ServiceContainer for resolving async objects
extension ServiceContainer {
    /// Resolve a service from the container that can be accessed on any actor
    @MainActor
    func resolveAsync<T>(_ type: T.Type) throws -> T {
        switch type {
        case is NotificationViewModel.Type:
            return notificationViewModel as! T
        default:
            throw ServiceError.serviceNotFound(String(describing: type))
        }
    }
    
    /// Resolve a service from a nonisolated context by dispatching to the main actor
    nonisolated func resolveOnMainActor<T>(_ type: T.Type) async throws -> T {
        return try await MainActor.run {
            try self.resolveAsync(type)
        }
    }
    
    enum ServiceError: Error {
        case serviceNotFound(String)
    }
}