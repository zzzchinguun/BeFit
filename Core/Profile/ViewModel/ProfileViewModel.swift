//
//  ProfileViewModel.swift
//  BeFit
//
//  Created by AI Assistant on 5/8/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "isDarkMode")
    @Published var showDeleteConfirmation: Bool = false
    @Published var needsOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @Published var selectedTab: Int = 0
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Services
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(authService: AuthServiceProtocol = ServiceContainer.shared.authService) {
        self.authService = authService
    }
    
    // MARK: - Methods
    
    /// Toggle dark mode setting
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
    }
    
    /// Change selected tab
    func selectTab(_ tab: Int) {
        selectedTab = tab
    }
    
    /// Show delete confirmation
    func showDeleteAccountConfirmation() {
        showDeleteConfirmation = true
    }
    
    /// Start the onboarding process
    func startOnboarding() {
        navigationPath.append("onboarding")
    }
    
    /// Check if onboarding is needed on app launch
    func checkOnboardingNeeded() {
        // Refresh the flag from UserDefaults to get the latest value
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        needsOnboarding = !hasCompletedOnboarding
        
        // Disable automatic navigation to onboarding
        // if needsOnboarding {
        //     navigationPath.append("onboarding")
        // }
    }
    
    /// Get tab icon
    func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "chart.bar.fill"
        case 1: return "dumbbell.fill"
        case 2: return "arrow.up.right.circle.fill"
        case 3: return "person.circle.fill"
        default: return ""
        }
    }
    
    /// Get outlined tab icon
    func tabIconOutlined(for index: Int) -> String {
        switch index {
        case 0: return "chart.bar"
        case 1: return "dumbbell"
        case 2: return "arrow.up.right.circle"
        case 3: return "person.circle"
        default: return ""
        }
    }
    
    /// Get tab title
    func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Дашборд"
        case 1: return "Дасгалууд"
        case 2: return "Хөгжил"
        case 3: return "Профайл"
        default: return ""
        }
    }
} 
