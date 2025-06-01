//
//  MealVerificationView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/8/25.
//

import SwiftUI

struct MealVerificationView: View {
    @StateObject private var viewModel = MealVerificationViewModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                headerView
                
                // Content
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.unverifiedMeals.isEmpty {
                        emptyStateView
                    } else {
                        mealsListView
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEnglishLanguage ? "Meal Verification" : "Хоол батлах")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEnglishLanguage ? "Close" : "Хаах") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.fetchUnverifiedMeals()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchUnverifiedMeals()
                }
            }
            .alert(isEnglishLanguage ? "🟢 APPROVE Meal" : "🟢 Хоол БАТЛАХ", isPresented: $viewModel.showingVerificationAlert) {
                Button(isEnglishLanguage ? "Cancel" : "Цуцлах", role: .cancel) { }
                Button(isEnglishLanguage ? "✅ APPROVE" : "✅ БАТЛАХ") {
                    Task {
                        await viewModel.verifySelectedMeal()
                    }
                }
            } message: {
                if let meal = viewModel.selectedMeal {
                    Text(isEnglishLanguage ? 
                         "Are you sure you want to APPROVE '\(meal.name)'? This will make it available to all users." :
                         "'\(meal.name)' хоолыг БАТЛАХДАА итгэлтэй байна уу? Энэ нь бүх хэрэглэгчдэд харагдах болно.")
                }
            }
            .alert(isEnglishLanguage ? "🔴 REJECT Meal" : "🔴 Хоол ТАТГАЛЗАХ", isPresented: $viewModel.showingRejectionAlert) {
                Button(isEnglishLanguage ? "Cancel" : "Цуцлах", role: .cancel) { }
                Button(isEnglishLanguage ? "❌ REJECT" : "❌ ТАТГАЛЗАХ", role: .destructive) {
                    Task {
                        await viewModel.rejectSelectedMeal()
                    }
                }
            } message: {
                VStack {
                    if let meal = viewModel.selectedMeal {
                        Text(isEnglishLanguage ? 
                             "Are you sure you want to REJECT '\(meal.name)'?" :
                             "'\(meal.name)' хоолыг ТАТГАЛЗАХДАА итгэлтэй байна уу?")
                    }
                    
                    TextField(isEnglishLanguage ? "Reason (optional)" : "Шалтгаан (заавал биш)", 
                             text: $viewModel.rejectionReason)
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(isEnglishLanguage ? "Super Admin" : "Супер админ")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(isEnglishLanguage ? "Meal Verification Panel" : "Хоол батлах самбар")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(viewModel.unverifiedMeals.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Text(isEnglishLanguage ? 
                 "Review and approve user-submitted meals to make them available in the nutrition database." :
                 "Хэрэглэгчдийн илгээсэн хоолыг шалгаж, хоолны санд нэмэхийг зөвшөөрнө үү.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(isEnglishLanguage ? "Loading unverified meals..." : "Батлагдаагүй хоолыг ачааллаж байна...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text(isEnglishLanguage ? "All Caught Up!" : "Бүгд шалгагдлаа!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(isEnglishLanguage ? 
                     "No unverified meals found. All user submissions have been reviewed." :
                     "Батлагдаагүй хоол байхгүй. Бүх хэрэглэгчийн илгээсэн хоол шалгагдсан байна.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Meals List View
    
    private var mealsListView: some View {
        List {
            ForEach(viewModel.unverifiedMeals) { meal in
                UnverifiedMealRow(
                    meal: meal,
                    onVerify: { viewModel.showVerificationConfirmation(for: meal) },
                    onReject: { viewModel.showRejectionConfirmation(for: meal) }
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Unverified Meal Row

struct UnverifiedMealRow: View {
    let meal: UnverifiedMeal
    let onVerify: () -> Void
    let onReject: () -> Void
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with meal name and creator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(isEnglishLanguage ? 
                         "Created by: \(meal.createdByEmail)" :
                         "Үүсгэсэн: \(meal.createdByEmail)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                categoryBadge
            }
            
            // Nutrition info
            HStack(spacing: 16) {
                nutritionItem(
                    icon: "flame.fill",
                    label: isEnglishLanguage ? "Cal" : "Кал",
                    value: "\(meal.calories)",
                    color: .orange
                )
                
                nutritionItem(
                    icon: "p.circle.fill",
                    label: isEnglishLanguage ? "Pro" : "Уураг",
                    value: "\(meal.protein)g",
                    color: .blue
                )
                
                nutritionItem(
                    icon: "c.circle.fill",
                    label: isEnglishLanguage ? "Carb" : "Нүүрс",
                    value: "\(meal.carbs)g",
                    color: .green
                )
                
                nutritionItem(
                    icon: "f.circle.fill",
                    label: isEnglishLanguage ? "Fat" : "Өөх",
                    value: "\(meal.fat)g",
                    color: .red
                )
            }
            
            // Serving info if available
            if let servingSize = meal.servingSizeGrams,
               let servingDescription = meal.servingDescription {
                Text(isEnglishLanguage ? 
                     "Serving: \(servingDescription) (\(String(format: "%.0f", servingSize))g)" :
                     "Порц: \(servingDescription) (\(String(format: "%.0f", servingSize))г)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Date created
            Text(isEnglishLanguage ? 
                 "Submitted: \(meal.dateCreated.formatted(date: .abbreviated, time: .shortened))" :
                 "Илгээсэн: \(meal.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onVerify) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(isEnglishLanguage ? "Verify" : "Батлах")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(Capsule())
                }
                
                Button(action: onReject) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text(isEnglishLanguage ? "Reject" : "Татгалзах")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .clipShape(Capsule())
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var categoryBadge: some View {
        Text(meal.category.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(categoryColor.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor.opacity(0.15))
            .clipShape(Capsule())
    }
    
    private var categoryColor: Color {
        switch meal.category {
        case .meat: return .red
        case .dairy: return .blue
        case .grains: return .orange
        case .fruits: return .pink
        case .vegetables: return .green
        case .nuts: return .brown
        case .beverages: return .cyan
        case .snacks: return .purple
        case .custom: return .gray
        }
    }
    
    private func nutritionItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MealVerificationView()
} 