//
//  ProfileView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/14/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showOnboarding = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        if let user = viewModel.currentUser {
            NavigationStack {
                VStack(spacing: 0) {
                    if hasCompletedOnboarding {
                        Button(action: { showOnboarding = true }) {
                            AnimatedPreferencesButton{
                            showOnboarding = true
                        }
                        }
                        .padding()
                    }
                    
                    TabView(selection: $selectedTab) {
                        profileDetailView(user: user)
                            .tag(0)
                        
                        dashboardView(user: user)
                            .tag(1)
                        
                        progressView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    customTabBar
                }
                .navigationBarTitleDisplayMode(.inline)
                .background(isDarkMode ? Color.black : Color(.systemGroupedBackground))
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
                    .presentationDetents([.medium, .large])
                    .environmentObject(viewModel)
            }
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.system(size: 24))
                        Text(tabTitle(for: index))
                            .font(.caption)
                            .fontWeight(selectedTab == index ? .bold : .regular)
                    }
                    .foregroundColor(selectedTab == index ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(.thinMaterial)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "person.circle.fill"
        case 1: return "chart.bar.fill"
        case 2: return "arrow.up.right.circle.fill"
        default: return ""
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Profile"
        case 1: return "Dashboard"
        case 2: return "Progress"
        default: return ""
        }
    }
    
    private func dashboardView(user: User) -> some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                metricCard(title: "Current Weight", value: "\(Int(user.weight ?? 0))kg", icon: "scalemass.fill")
                metricCard(title: "Goal Weight", value: "\(Int(user.goalWeight ?? 0))kg", icon: "target")
                metricCard(title: "Days Left", value: "\(user.daysToComplete ?? 0)", icon: "calendar")
                metricCard(title: "Daily Calories", value: "\(Int(user.tdee ?? 0))", icon: "flame.fill")
            }
            .padding()
        }
    }
    
    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    private func profileDetailView(user: User) -> some View {
        List {
            Section {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.firstName + " " + user.lastName)
                            .font(.headline)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle(isOn: $isDarkMode) {
                    SettingsRowView(
                        imageName: isDarkMode ? "moon.fill" : "sun.max.fill",
                        title: "Шөнийн горим",
                        tintColor: isDarkMode ? .purple : .orange,
                        isDeleteButton: false
                    )
                }
            }
            
            Section("Ерөнхий") {
                HStack {
                    SettingsRowView(
                        imageName: "gear",
                        title: "Хувилбар",
                        tintColor: Color(.systemGray),
                        isDeleteButton: false
                    )
                    Spacer()
                    
                    Text("1.1.25")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Section("Бүртгэл") {
                Button {
                    Task {
                        viewModel.signOut()
                    }
                } label: {
                    SettingsRowView(
                        imageName: "arrow.left.circle.fill",
                        title: "Гарах",
                        tintColor: Color(.systemGray),
                        isDeleteButton: false
                    )
                }
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    SettingsRowView(
                        imageName: "minus.circle.fill",
                        title: "Устгах",
                        tintColor: Color(.systemRed),
                        isDeleteButton: true
                    )
                    
                }
                .alert("Бүртгэл устгах", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            try? await viewModel.deleteAccount()
                        }
                    }
                } message: {
                    Text("Та бүртгэлээ устгахдаа итгэлтэй байна уу? Энэ үйлдлийг буцаах боломжгүй.")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var progressView: some View {
        VStack(spacing: 20) {
            Text("Progress")
                .font(.title)
                .fontWeight(.bold)
            
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Progress Chart Coming Soon")
                        .foregroundColor(.blue)
                )
                .padding()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
