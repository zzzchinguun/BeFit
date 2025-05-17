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
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                ProfileView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            Task {
                // Setup test user for development environment
                authViewModel.setupTestUser()
            }
        }
    }
}

#Preview {
    ContentView()
        .withInjectedEnvironment()
}
