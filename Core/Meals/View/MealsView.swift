//
//  MealsView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/31/25.
//

import SwiftUI

struct MealsView: View {
    @StateObject var viewModel = MealViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddMealSheet = false
    @State private var showDeleteAlert = false
    @State private var showNutritionDatabase = false
    @State private var mealToDelete: Meal?
    @State private var addedMealId: String? = nil
    @State private var shouldHighlightNewMeal = false
    @State private var currentDetent: PresentationDetent = .medium
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    @State private var expandedMealId: String? = nil
    @State private var lastRefreshTime: Date = Date.distantPast
    
    // Debouncing constant
    private let refreshDebounceInterval: TimeInterval = 2.0 // 2 seconds
    
    var body: some View {
        VStack(spacing: 20) {
            nutritionHeaderView
            
            // Divider with "Today's Meals" label
            mealsSectionHeader
            
            // Meals list
            mealsList
        }
        .sheet(isPresented: $showAddMealSheet) {
            AddMealView(viewModel: viewModel, onInputFocus: {
                currentDetent = .large
                print("Focused")
            })
                .presentationDetents([.fraction(0.99), .medium, .large], selection: $currentDetent)
                .onDisappear {
                    // Fetch the newly added meal ID when sheet is dismissed
                    if !viewModel.dailyMeals.isEmpty, let lastMeal = viewModel.dailyMeals.first {
                        addedMealId = lastMeal.id
                    }
                    
                    // Remove excessive refresh - data should already be updated optimistically
                    // Task {
                    //     await viewModel.fetchMeals()
                    // }
                }
        }
        .alert("Хоол устгах", isPresented: $showDeleteAlert) {
            Button("Цуцлах", role: .cancel) { }
            Button("Устгах", role: .destructive) {
                if let meal = mealToDelete {
                    // Clear expanded state if deleting the currently expanded meal
                    if expandedMealId == meal.id {
                        expandedMealId = nil
                    }
                    
                    Task {
                        try? await viewModel.deleteMeal(meal)
                    }
                    
                    // Clear the meal reference
                    mealToDelete = nil
                }
            }
        } message: {
            if let meal = mealToDelete {
                Text("\(meal.name) устгахдаа итгэлтэй байна уу?")
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchMeals()
            }
        }
        .onChange(of: viewModel.dailyMeals) { _, newMeals in
            // Check if a new meal was added
            if !newMeals.isEmpty, let lastMeal = newMeals.first, lastMeal.id == addedMealId {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shouldHighlightNewMeal = true
                }
            }
            
            // Clear expanded state if the expanded meal no longer exists
            if let expandedId = expandedMealId {
                let expandedMealExists = newMeals.contains { $0.id == expandedId }
                if !expandedMealExists {
                    // Use immediate state change without animation to prevent conflicts
                    expandedMealId = nil
                }
            }
        }
        .refreshable {
            await viewModel.fetchMeals()
        }
        .sheet(isPresented: $showNutritionDatabase) {
            NutritionDatabaseView()
                .onDisappear {
                    // Remove excessive refresh - nutrition database adds optimistically update meals
                    // Task {
                    //     await viewModel.fetchMeals()
                    // }
                }
        }
    }
    
    // MARK: - Nutrition Header
    private var nutritionHeaderView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Таны зорилт ")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    // Refresh data manually with debouncing
                    let now = Date()
                    if now.timeIntervalSince(lastRefreshTime) >= refreshDebounceInterval {
                        lastRefreshTime = now
                        Task {
                            await viewModel.fetchMeals()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            
            // Daily calories card
            caloriesCard
            
            // Macros progress
            macrosProgressView
        }
        .padding(.horizontal)
    }
    
    // MARK: - Calories Card
    private var caloriesCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Авсан илчлэг")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(viewModel.calculateTodayTotals().calories)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .contentTransition(.numericText())
                    
                    Text("/ \(Int(authViewModel.currentUser?.tdee ?? 0))")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            caloriesCircleView
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
    
    // MARK: - Calories Circle
    private var caloriesCircleView: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundColor(.blue)
            
            Circle()
                .trim(from: 0.0, to: caloriesTodayPercentage)
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut, value: caloriesTodayPercentage)
            
            Text("\(Int(caloriesTodayPercentage * 100))%")
                .font(.system(.body, design: .rounded))
                .bold()
        }
        .frame(width: 70, height: 70)
    }
    
    // MARK: - Macros Progress View
    private var macrosProgressView: some View {
        Group {
            if let userMacros = authViewModel.currentUser?.macros {
                VStack(spacing: 10) {
                    MacroProgressView(
                        title: "Уураг",
                        current: viewModel.calculateTodayTotals().protein,
                        target: userMacros.protein,
                        color: .blue
                    )
                    .contentTransition(.interpolate)
                    
                    MacroProgressView(
                        title: "Нүүрс ус",
                        current: viewModel.calculateTodayTotals().carbs,
                        target: userMacros.carbs,
                        color: .green
                    )
                    .contentTransition(.interpolate)
                    
                    MacroProgressView(
                        title: "Өөх тос",
                        current: viewModel.calculateTodayTotals().fat,
                        target: userMacros.fat,
                        color: .red
                    )
                    .contentTransition(.interpolate)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .animation(.spring(), value: viewModel.todayNutrition)
            }
        }
    }
    
    // MARK: - Meals Section Header
    private var mealsSectionHeader: some View {
        HStack {
            Text("Өнөөдрийн хоол")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Button to open nutrition database
            Button {
                showNutritionDatabase = true
            } label: {
                HStack(spacing: 4) {
                    Text(isEnglishLanguage ? "Nutrition Database" : "Хоолны сан")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button {
                showAddMealSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Meals List
    private var mealsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.dailyMeals.isEmpty {
                emptyMealsView
            } else {
                mealsListView
            }
        }
    }
    
    // MARK: - Empty Meals View
    private var emptyMealsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
                .padding()
            
            Text("Өнөөдөр хоол нэмэгдээгүй байна")
                .font(.headline)
            
            Text("Анхны хоолоо нэмэхийн тулд + товчийг дарна уу")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Meals List View
    private var mealsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.dailyMeals) { meal in
                    mealRowView(for: meal)
                        .id("\(meal.id ?? UUID().uuidString)_\(meal.date.timeIntervalSince1970)") // Stable, unique identity
                }
            }
            .padding(.horizontal, 16) // Add proper horizontal padding
            .padding(.bottom, 100) // Extra bottom padding to prevent overlap with tab bar
        }
    }
    
    // MARK: - Meal Row Item
    private func mealRowView(for meal: Meal) -> some View {
        MealRowView(
            meal: meal, 
            viewModel: viewModel,
            onDelete: {
                // Clear expanded state if deleting the currently expanded meal
                if expandedMealId == meal.id {
                    expandedMealId = nil
                }
                mealToDelete = meal
                showDeleteAlert = true
            },
            expandedMealId: $expandedMealId
        )
        .overlay(
            // Simple highlight overlay without complex animations
            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 2)
                .foregroundColor(shouldHighlightNewMeal && meal.id == addedMealId ? .blue : .clear)
        )
        .scaleEffect(shouldHighlightNewMeal && meal.id == addedMealId ? 1.01 : 1.0)
        .onAppear {
            checkIfNewlyAddedMeal(meal)
        }
    }
    
    // MARK: - Check New Meal
    private func checkIfNewlyAddedMeal(_ meal: Meal) {
        if meal.id == addedMealId {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                shouldHighlightNewMeal = true
            }
            
            // Reset highlight after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    shouldHighlightNewMeal = false
                    addedMealId = nil
                }
            }
        }
    }
    
    private var caloriesTodayPercentage: CGFloat {
        let caloriesConsumed = viewModel.todayNutrition.calories
        let caloriesTarget = Int(authViewModel.currentUser?.tdee ?? 1)
        return min(CGFloat(caloriesConsumed) / CGFloat(caloriesTarget), 1.0)
    }
}

#Preview {
    MealsView()
        .environmentObject(AuthViewModel())
} 
