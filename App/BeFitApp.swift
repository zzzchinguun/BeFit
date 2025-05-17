//
//  BeFitApp.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI
import Firebase

@main
struct BeFitApp: App {
    // MARK: - Initialize Firebase
    
    // This initializes the Firebase app and begins loading user data in the background
    private let appInitializer = AppInitializer()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withInjectedEnvironment() // Injects all environment objects
        }
    }
}

// Helper class to handle app initialization
// This allows us to do setup work without requiring an async init in the App struct
class AppInitializer {
    init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
}
