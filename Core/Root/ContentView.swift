//
//  ContentView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//  
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isShowingSplash = true
    @State private var hasTriedTestUser = false
    @State private var forceReset = false
    @State private var refreshID = UUID() // Add a refresh ID to force view refresh
    
    var body: some View {
        ZStack {
            Group {
                if authViewModel.userSession != nil && !forceReset {
                    ProfileView()
                        .id(refreshID) // Force refresh with ID change
                        .onAppear {
                            // Verify that user data exists
                            if authViewModel.currentUser == nil {
                                print("⚠️ User session exists but no user data, forcing reset")
                                resetAuthState()
                            }
                            
                            // Safety timer - if Profile view appears and stays for 2 seconds with no user data, force reset
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if authViewModel.currentUser == nil && authViewModel.userSession != nil {
                                    print("🚨 Safety timer triggered - user data still nil after 2 seconds")
                                    resetAuthState()
                                }
                            }
                        }
                } else {
                    LoginView()
                        .id(refreshID) // Force refresh with ID change
                }
            }
            .background(colorScheme == .dark ? Color.neutralBackgroundDark : Color.neutralBackground)
            .onAppear {
                if !hasTriedTestUser {
                    Task {
                        // Setup test user for development environment only on first appear
                        authViewModel.setupTestUser()
                        hasTriedTestUser = true
                    }
                }
            }
            .onChange(of: authViewModel.userSession) { oldValue, newValue in
                // Force view update when user session changes directly
                print("User session changed directly: \(newValue != nil ? "logged in" : "logged out")")
                refreshID = UUID() // Generate new ID to force refresh
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("userSessionChanged"))) { _ in
                // Force view update when user session changes
                print("User session changed notification received")
                refreshID = UUID() // Generate new ID to force refresh
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("forceAuthReset"))) { _ in
                // Emergency reset triggered from anywhere in the app
                print("🔄 Force auth reset notification received")
                resetAuthState()
            }
            
            // Show splash screen on top if needed
            if isShowingSplash {
                SplashScreenView(isActive: $isShowingSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
    
    private func resetAuthState() {
        // Set force reset flag
        forceReset = true
        
        // Create a new refreshID to force view refresh
        refreshID = UUID()
        
        // Clear Firebase Auth state completely
        try? Auth.auth().signOut()
        
        // Reset view model state after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            authViewModel.userSession = nil
            authViewModel.currentUser = nil
            
            // Reset force flag after another short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                forceReset = false
                refreshID = UUID() // Generate new ID to force another refresh
            }
        }
    }
}

#Preview {
    ContentView()
        .withInjectedEnvironment()
}
