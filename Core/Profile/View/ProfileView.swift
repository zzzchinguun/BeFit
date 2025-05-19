//
//  ProfileView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/14/25.
//  Updated by AI Assistant on 5/8/25 for MVVM architecture
//

import SwiftUI

struct ProfileView: View {
    // MARK: - View Model
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ViewModelFactory.createProfileViewModel()
    @StateObject private var weightLogViewModel = ViewModelFactory.createWeightLogViewModel()
    @State private var showWeightLogSheet = false
    
    // MARK: - Body
    
    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack(path: $viewModel.navigationPath) {
                VStack(spacing: 0) {
                    // Header with profile info
                    headerView(user: user)
                    
                    if viewModel.needsOnboarding {
                        Button {
                            viewModel.startOnboarding()
                        } label: {
                            AnimatedPreferencesButton {
                                viewModel.startOnboarding()
                            }
                        }
                        .padding()
                    }
                    
                    if !weightLogViewModel.hasLoggedWeightToday {
                        Button {
                            showWeightLogSheet = true
                        } label: {
                            WeightLogButton {
                                showWeightLogSheet = true
                            }
                        }
                        .padding()
                    }
                    
                    TabView(selection: $viewModel.selectedTab) {
                        dashboardView(user: user)
                            .tag(0)
                        
                        ExercisesView()
                            .tag(1)
                        
                        progressView
                            .tag(2)
                            .onAppear {
                                // Refresh weight logs when the progress tab is shown
                                weightLogViewModel.fetchWeightLogs()
                            }
                            
                        profileDetailView(user: user)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    customTabBar
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .background(viewModel.isDarkMode ? Color.black : Color(.systemGroupedBackground))
                .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
                .navigationDestination(for: String.self) { route in
                    if route == "onboarding" {
                        OnboardingView()
                            .environmentObject(authViewModel)
                            .navigationBarBackButtonHidden()
                    }
                }
            }
            .onAppear {
                viewModel.checkOnboardingNeeded()
                weightLogViewModel.fetchWeightLogs()
            }
            .sheet(isPresented: $showWeightLogSheet) {
                WeightLogSheet(viewModel: weightLogViewModel)
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(user: User) -> some View {
        Button {
            viewModel.selectTab(3) // Updated to match the new tab index for profile
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(user.initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Сайн уу,")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(user.firstName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    withAnimation {
                        viewModel.selectTab(index)
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: viewModel.selectedTab == index ? 
                              viewModel.tabIcon(for: index) : 
                              viewModel.tabIconOutlined(for: index))
                            .font(.system(size: 22))
                        Text(viewModel.tabTitle(for: index))
                            .font(.caption)
                            .fontWeight(viewModel.selectedTab == index ? .semibold : .regular)
                    }
                    .foregroundColor(viewModel.selectedTab == index ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6) // Reduced padding height
                }
            }
        }
        .background(.thinMaterial)
    }
    
    // MARK: - Dashboard View
    
    private func dashboardView(user: User) -> some View {
        ScrollView{
            VStack(spacing: 20) {
                Text("Хянах самбар")
                    .font(.title)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    metricCard(title: "Одоогийн жин", value: "\(Int(user.weight ?? 0))кг", icon: "scalemass.fill")
                    metricCard(title: "Зорилтот жин", value: "\(Int(user.goalWeight ?? 0))кг", icon: "target")
                    metricCard(title: "Үлдсэн өдөр", value: "\(user.daysToComplete ?? 0)", icon: "calendar")
                    metricCard(title: "Өдрийн илчлэг", value: "\(Int(user.tdee ?? 0))", icon: "flame.fill")
                }
                .padding(.horizontal)
                
                Divider()
                
                // Meal tracking
                MealsView()
                
                // Add spacing at the bottom to prevent overlap with tab bar
                Spacer().frame(height: 80)
            }
        }
    }
    
    // MARK: - Metric Card
    
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
    
    // MARK: - Profile Detail View
    
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
                Toggle(isOn: $viewModel.isDarkMode) {
                    SettingsRowView(
                        imageName: viewModel.isDarkMode ? "moon.fill" : "sun.max.fill",
                        title: "Шөнийн горим",
                        tintColor: viewModel.isDarkMode ? .purple : .orange,
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
                    
                    Text("1.2.11")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Section("Бүртгэл") {
                Button {
                    Task {
                        authViewModel.signOut()
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
                    viewModel.showDeleteAccountConfirmation()
                } label: {
                    SettingsRowView(
                        imageName: "minus.circle.fill",
                        title: "Устгах",
                        tintColor: Color(.systemRed),
                        isDeleteButton: true
                    )
                    
                }
                .alert("Бүртгэл устгах", isPresented: $viewModel.showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            try? await authViewModel.deleteAccount()
                        }
                    }
                } message: {
                    Text("Та бүртгэлээ устгахдаа итгэлтэй байна уу? Энэ үйлдлийг буцаах боломжгүй.")
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        WeightProgressView(viewModel: weightLogViewModel)
    }
    
    // MARK: - Helpers
    
    /// Check if user has completed all necessary profile data
    private func checkUserDataCompleteness(_ user: User) {
        // If any essential fitness data is missing, force onboarding
        let hasIncompleteData = user.age == nil || 
                               user.weight == nil || 
                               user.height == nil ||
                               user.sex == nil ||
                               user.bodyFatPercentage == nil ||
                               user.goalWeight == nil ||
                               user.daysToComplete == nil
        
        if hasIncompleteData {
            // User has incomplete data, force onboarding
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            viewModel.checkOnboardingNeeded()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
