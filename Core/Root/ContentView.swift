//
//  ContentView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//  Updated by AI Assistant on 5/8/25 for MVVM architecture
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            Group {
                if authViewModel.userSession != nil {
                    ProfileView()
                } else {
                    LoginView()
                }
            }
            .background(colorScheme == .dark ? Color.neutralBackgroundDark : Color.neutralBackground)
            .onAppear {
                Task {
                    // Setup test user for development environment
                    authViewModel.setupTestUser()
                }
            }
            
            // Show splash screen on top if needed
            if isShowingSplash {
                SplashScreenView(isActive: $isShowingSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    ContentView()
        .withInjectedEnvironment()
}
