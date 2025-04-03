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
    @StateObject var viewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
