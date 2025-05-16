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
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var mealViewModel = MealViewModel()

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(mealViewModel)
        }
    }
}
