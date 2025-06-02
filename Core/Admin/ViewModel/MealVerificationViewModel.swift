//
//  MealVerificationViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import Combine

@MainActor
class MealVerificationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var unverifiedMeals: [UnverifiedMeal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingVerificationAlert = false
    @Published var showingRejectionAlert = false
    @Published var selectedMeal: UnverifiedMeal?
    @Published var rejectionReason = ""
    
    // MARK: - Services
    
    private let mealVerificationService: MealVerificationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(mealVerificationService: MealVerificationServiceProtocol = MealVerificationService.shared) {
        self.mealVerificationService = mealVerificationService
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to unverified meals
        mealVerificationService.unverifiedMeals
            .receive(on: RunLoop.main)
            .sink { [weak self] meals in
                self?.unverifiedMeals = meals
            }
            .store(in: &cancellables)
        
        // Subscribe to loading state
        mealVerificationService.isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Subscribe to error messages
        mealVerificationService.errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetch unverified meals
    func fetchUnverifiedMeals() async {
        await mealVerificationService.fetchUnverifiedMeals()
    }
    
    /// Show verification confirmation for a meal
    func showVerificationConfirmation(for meal: UnverifiedMeal) {
        selectedMeal = meal
        showingVerificationAlert = true
    }
    
    /// Show rejection confirmation for a meal
    func showRejectionConfirmation(for meal: UnverifiedMeal) {
        selectedMeal = meal
        rejectionReason = ""
        showingRejectionAlert = true
    }
    
    /// Verify the selected meal
    func verifySelectedMeal() async {
        guard let meal = selectedMeal else { return }
        
        do {
            try await mealVerificationService.verifyMeal(meal)
            showingVerificationAlert = false
            selectedMeal = nil
        } catch {
            errorMessage = "Failed to verify meal: \(error.localizedDescription)"
        }
    }
    
    /// Reject the selected meal
    func rejectSelectedMeal() async {
        guard let meal = selectedMeal else { return }
        
        do {
            let reason = rejectionReason.isEmpty ? nil : rejectionReason
            try await mealVerificationService.rejectMeal(meal, reason: reason)
            showingRejectionAlert = false
            selectedMeal = nil
            rejectionReason = ""
        } catch {
            errorMessage = "Failed to reject meal: \(error.localizedDescription)"
        }
    }
    
    /// Check if user is super admin
    func isUserSuperAdmin(_ user: User) -> Bool {
        return mealVerificationService.isUserSuperAdmin(user)
    }
} 
