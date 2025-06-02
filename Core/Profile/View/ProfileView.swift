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
    @StateObject private var notificationViewModel = ViewModelFactory.createNotificationViewModel()
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showWeightLogSheet = false
    @State private var showNotificationsSheet = false
    @State private var showMealVerificationSheet = false
    
    // MARK: - Body
    
    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack(path: $viewModel.navigationPath) {
                VStack(spacing: 0) {
                    // Header with profile info
                    headerView(user: user)
                    
                    if viewModel.needsOnboarding && (user.goalWeight == nil || user.goalWeight == 0) {
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
                            .onAppear {
                                // Notify that we're switching to dashboard tab
                                NotificationCenter.default.post(name: Notification.Name("tabSwitched"), object: "dashboard")
                            }
                        
                        ExercisesView()
                            .tag(1)
                            .onAppear {
                                // Notify that we're switching to exercises tab
                                NotificationCenter.default.post(name: Notification.Name("tabSwitched"), object: "exercises")
                            }
                        
                        progressView
                            .tag(2)
                            .onAppear {
                                // Refresh weight logs when the progress tab is shown
                                weightLogViewModel.fetchWeightLogs()
                                // Notify that we're switching to progress tab
                                NotificationCenter.default.post(name: Notification.Name("tabSwitched"), object: "progress")
                            }
                            
                        profileDetailView(user: user)
                            .tag(3)
                            .onAppear {
                                // Notify that we're switching to profile tab
                                NotificationCenter.default.post(name: Notification.Name("tabSwitched"), object: "profile")
                            }
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
                
                // Auto-trigger onboarding for new users - only if they truly need onboarding
                // Use the same logic as the button display to ensure consistency
                if viewModel.needsOnboarding && (user.goalWeight == nil || user.goalWeight == 0) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.startOnboarding()
                    }
                }
            }
            .sheet(isPresented: $showWeightLogSheet) {
                WeightLogSheet(viewModel: weightLogViewModel)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsView(viewModel: notificationViewModel)
            }
            .sheet(isPresented: $showMealVerificationSheet) {
                MealVerificationView()
            }
        }
    }
    
    // MARK: - Header View
    
    private func headerView(user: User) -> some View {
        HStack {
            Button {
                viewModel.selectTab(3) // Tab index for profile
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
                    
                    VStack(alignment: .leading, spacing: -1) {
                        Text(languageManager.isEnglishLanguage ? "Hello," : "Сайн уу,")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text(user.firstName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button {
                showNotificationsSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    if notificationViewModel.unreadCount > 0 {
                        Text("\(notificationViewModel.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 2, y: -2)
                    }
                }
            }
        }
        .padding()
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
                Text(languageManager.isEnglishLanguage ? "Dashboard" : "Хянах самбар")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    metricCard(title: languageManager.isEnglishLanguage ? "Current Weight" : "Одоогийн жин", value: "\(Int(user.weight ?? 0))кг", icon: "scalemass.fill")
                    metricCard(title: languageManager.isEnglishLanguage ? "Target Weight" : "Зорилтот жин", value: "\(Int(user.goalWeight ?? 0))кг", icon: "target")
                    metricCard(title: languageManager.isEnglishLanguage ? "Days Remaining" : "Үлдсэн өдөр", value: "\(user.remainingDays)", icon: "calendar")
                    metricCard(title: languageManager.isEnglishLanguage ? "Daily Calories" : "Өдрийн илчлэг", value: "\(Int(user.goalCalories ?? user.tdee ?? 0))", icon: "flame.fill")
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
            
            // Super Admin Section (only for super admins)
            if MealVerificationService.shared.isUserSuperAdmin(user) {
                Section(languageManager.isEnglishLanguage ? "Super Admin" : "Супер админ") {
                    Button {
                        showMealVerificationSheet = true
                    } label: {
                        SettingsRowView(
                            imageName: "checkmark.shield.fill",
                            title: languageManager.isEnglishLanguage ? "Verify Meals" : "Хоол батлах",
                            tintColor: .orange,
                            isDeleteButton: false
                        )
                    }
                }
            }
            
            Section {
                // Dark mode picker instead of a simple toggle
                Picker(selection: $viewModel.appearanceMode) {
                    Text(languageManager.isEnglishLanguage ? "System" : "Системийн")
                        .tag(0)
                    Text(languageManager.isEnglishLanguage ? "Dark" : "Шөнийн")
                        .tag(1)
                    Text(languageManager.isEnglishLanguage ? "Light" : "Өдрийн")
                        .tag(2)
                } label: {
                    HStack {
                        Image(systemName: viewModel.appearanceMode == 0 ? "gearshape.fill" : (viewModel.isDarkMode ? "moon.fill" : "sun.max.fill"))
                            .foregroundColor(viewModel.appearanceMode == 0 ? .gray : (viewModel.isDarkMode ? .purple : .orange))
                            .imageScale(.medium)
                            .frame(width: 24, height: 24)
                        
                        Text(languageManager.isEnglishLanguage ? "Appearance" : "Харагдах байдал")
                    }
                }
                .onChange(of: viewModel.appearanceMode) { value in
                    switch value {
                    case 0:
                        viewModel.useSystemTheme()
                    case 1:
                        if !viewModel.isDarkMode {
                            viewModel.toggleDarkMode()
                        } else {
                            UserDefaults.standard.set(true, forKey: "isDarkMode")
                        }
                    case 2:
                        if viewModel.isDarkMode {
                            viewModel.toggleDarkMode()
                        } else {
                            UserDefaults.standard.set(false, forKey: "isDarkMode")
                        }
                    default:
                        break
                    }
                }
                
                Toggle(isOn: $languageManager.isEnglishLanguage) {
                    SettingsRowView(
                        imageName: "globe",
                        title: languageManager.isEnglishLanguage ? "English (Beta)" : "Монгол (Beta)",
                        tintColor: .blue,
                        isDeleteButton: false
                    )
                }
                
                Toggle(isOn: $languageManager.isExerciseEnglishLanguage) {
                    SettingsRowView(
                        imageName: "dumbbell.fill",
                        title: languageManager.isEnglishLanguage ? (languageManager.isExerciseEnglishLanguage ? "Exercise Names in English" : "Exercise Names in Mongolian") : (languageManager.isExerciseEnglishLanguage ? "Дасгалын нэр англиар" : "Дасгалын нэр монголоор"),
                        tintColor: .green,
                        isDeleteButton: false
                    )
                }
                
                Button {
                    viewModel.restartOnboarding()
                } label: {
                    SettingsRowView(
                        imageName: "arrow.triangle.2.circlepath",
                        title: languageManager.isEnglishLanguage ? "Restart body measurement" : "Биеийн үзүүлэлт шинэчлэх",
                        tintColor: .green,
                        isDeleteButton: false
                    )
                }
            }
            
            Section(languageManager.isEnglishLanguage ? "General" : "Ерөнхий") {
                HStack {
                    SettingsRowView(
                        imageName: "gear",
                        title: languageManager.isEnglishLanguage ? "Version" : "Хувилбар",
                        tintColor: Color(.systemGray),
                        isDeleteButton: false
                    )
                    Spacer()
                    
                    Text("1.2.11")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Section(languageManager.isEnglishLanguage ? "Account" : "Бүртгэл") {
                Button {
                    Task {
                        authViewModel.signOut()
                    }
                } label: {
                    SettingsRowView(
                        imageName: "arrow.left.circle.fill",
                        title: languageManager.isEnglishLanguage ? "Log Out" : "Гарах",
                        tintColor: Color(.systemGray),
                        isDeleteButton: false
                    )
                }
                
                Button {
                    viewModel.showDeleteAccountConfirmation()
                } label: {
                    SettingsRowView(
                        imageName: "minus.circle.fill",
                        title: languageManager.isEnglishLanguage ? "Delete Account" : "Устгах",
                        tintColor: Color(.systemRed),
                        isDeleteButton: true
                    )
                    
                }
                .alert(languageManager.isEnglishLanguage ? "Delete Account" : "Бүртгэл устгах", isPresented: $viewModel.showDeleteConfirmation) {
                    Button(languageManager.isEnglishLanguage ? "Cancel" : "Цуцлах", role: .cancel) { }
                    Button(languageManager.isEnglishLanguage ? "Delete" : "Устгах", role: .destructive) {
                        Task {
                            try? await authViewModel.deleteAccount()
                        }
                    }
                } message: {
                    Text(languageManager.isEnglishLanguage ? 
                         "Are you sure you want to delete your account? This action cannot be undone." : 
                         "Та бүртгэлээ устгахдаа итгэлтэй байна уу? Энэ үйлдлийг буцаах боломжгүй.")
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
    let mockAuthViewModel = AuthViewModel()
    mockAuthViewModel.currentUser = User.MOCK_USER
    
    return ProfileView()
        .environmentObject(mockAuthViewModel)
}
