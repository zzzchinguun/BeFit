//
//  ProfileViewModel.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isDarkMode: Bool = UserDefaults.standard.object(forKey: "isDarkMode") != nil ? UserDefaults.standard.bool(forKey: "isDarkMode") : false
    @Published var appearanceMode: Int = UserDefaults.standard.object(forKey: "isDarkMode") == nil ? 0 : (UserDefaults.standard.bool(forKey: "isDarkMode") ? 1 : 2)
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
        
        // Update the dark mode value based on system settings if needed
        if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
            isDarkMode = isSystemInDarkMode()
        }
        
        // Set up observer for system appearance changes
        setupAppearanceObserver()
    }
    
    // Detect system appearance
    private func isSystemInDarkMode() -> Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    // Set up observer for system appearance changes
    private func setupAppearanceObserver() {
        // Only observe system changes if user hasn't set a preference
        if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .sink { [weak self] _ in
                    // Update theme based on system setting when app becomes active
                    if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
                        self?.isDarkMode = self?.isSystemInDarkMode() ?? false
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Methods
    
    /// Toggle dark mode setting and save user preference
    func toggleDarkMode() {
        isDarkMode.toggle()
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        appearanceMode = isDarkMode ? 1 : 2 // Dark = 1, Light = 2
    }
    
    /// Use system theme by removing user preference
    func useSystemTheme() {
        // Remove user preference and use system setting
        UserDefaults.standard.removeObject(forKey: "isDarkMode")
        isDarkMode = isSystemInDarkMode()
        appearanceMode = 0 // System mode
    }
    
    /// Restart onboarding manually
    func restartOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        checkOnboardingNeeded()
        startOnboarding()
    }
    
    /// Change selected tab
    func selectTab(_ tab: Int) {
        // Only change if it's a different tab
        if selectedTab != tab {
            print("🔄 ProfileViewModel: Switching from tab \(selectedTab) to tab \(tab)")
            
            // Clear navigation path when switching tabs to prevent conflicts
            if !navigationPath.isEmpty {
                navigationPath = NavigationPath()
            }
            
            selectedTab = tab
            
            // Add small delay to ensure state is properly updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Force UI update if needed
                self.objectWillChange.send()
            }
        }
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
        let languageManager = LanguageManager.shared
        if languageManager.isEnglishLanguage {
            switch index {
            case 0: return "Dashboard"
            case 1: return "Exercises"
            case 2: return "Progress"
            case 3: return "Profile"
            default: return ""
            }
        } else {
            switch index {
            case 0: return "Дашборд"
            case 1: return "Дасгалууд"
            case 2: return "Хөгжил"
            case 3: return "Профайл"
            default: return ""
            }
        }
    }
} 
