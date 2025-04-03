//
//  ContentView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        Group{
            if viewModel.userSession != nil {
                ProfileView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
