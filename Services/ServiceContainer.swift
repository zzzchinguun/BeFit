//
//  ServiceContainer.swift
//  BeFit
//
//  Created by AI Assistant on 5/8/25.
//

import Foundation
import SwiftUI

/// A container for all services to handle dependency injection
class ServiceContainer {
    // MARK: - Shared Instance
    
    /// Shared instance of the service container (singleton)
    static let shared = ServiceContainer()
    
    // MARK: - Services
    
    /// Authentication service
    lazy var authService: AuthServiceProtocol = AuthService()
    
    /// Meal service
    lazy var mealService: MealServiceProtocol = MealService()
    
    /// Notification view model (can be accessed directly)
    @MainActor lazy var notificationViewModel: NotificationViewModel = ViewModelFactory.createNotificationViewModel()
    
    // Add more services as needed
    
    // MARK: - Init
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Method to register services with the SwiftUI environment
    func registerServices() {
        // Create environment objects when needed
    }
}

/// Property wrapper to easily inject services into objects
@propertyWrapper
struct Inject<T> {
    let wrappedValue: T
    
    init(_ keyPath: KeyPath<ServiceContainer, T>) {
        self.wrappedValue = ServiceContainer.shared[keyPath: keyPath]
    }
} 