//
//  NutritionDatabaseView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import SwiftUI
import Foundation
import CoreImage

// MARK: - Global Helper Functions

/// Global function for category colors that can be accessed by all structs
//func categoryColor(_ category: FoodCategory) -> Color {
//    switch category {
//    case .meat: return Color.accentApp
//    case .dairy: return Color.infoApp
//    case .grains: return Color.warningApp
//    case .fruits: return Color.successApp
//    case .vegetables: return Color.primaryApp
//    case .nuts: return Color.warningApp
//    case .beverages: return Color.infoApp
//    case .snacks: return Color.accentApp
//    case .custom: return Color.primaryApp
//    }
//}

struct NutritionDatabaseView: View {
    @StateObject var viewModel = NutritionDatabaseViewModel()
    @State private var showAddFoodSheet = false
    @State private var showFoodDetailSheet = false
    @State private var showBarcodeScannerSheet = false
    @State private var selectedFood: NutritionData?
    @State private var searchText = ""
    @State private var hasLoaded = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
            .background(Color.adaptiveBackground(isDarkMode))
            .navigationTitle(isEnglishLanguage ? "Nutrition Library" : "Хоолны сан")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if hasLoaded {
                            reloadButton
                        }
                        addButton
                    }
                }
            }
            .sheet(isPresented: $showAddFoodSheet) {
                ModernAddCustomFoodView(viewModel: viewModel)
                    .onDisappear {
                        print("🔴 DEBUG: ModernAddCustomFoodView disappeared")
                    }
            }
            .sheet(isPresented: $showFoodDetailSheet) {
                if let selectedFood = selectedFood {
                    ModernFoodDetailView(food: selectedFood, viewModel: viewModel, isPresented: $showFoodDetailSheet)
                } else {
                    EmptyView()
                        .onAppear {
                            print("🔴 DEBUG: showFoodDetailSheet is true but selectedFood is nil!")
                        }
                }
            }
            .onChange(of: showAddFoodSheet) { _, newValue in
                print("🔴 DEBUG: showAddFoodSheet changed to: \(newValue)")
            }
            .onChange(of: showFoodDetailSheet) { _, isPresented in
                print("🔴 DEBUG: showFoodDetailSheet changed to: \(isPresented)")
                // Clear selected food when sheet is dismissed
                if !isPresented {
                    print("🔴 DEBUG: Clearing selectedFood because sheet was dismissed")
                    selectedFood = nil
                }
            }
            .onChange(of: showBarcodeScannerSheet) { _, newValue in
                print("🔴 DEBUG: showBarcodeScannerSheet changed to: \(newValue)")
            }
            .fullScreenCover(isPresented: $showBarcodeScannerSheet) {
                BarcodeScannerView(scannedCode: $viewModel.scannedBarcode, isScanning: $showBarcodeScannerSheet)
                    .onDisappear {
                        print("🔴 DEBUG: BarcodeScannerView disappeared")
                        handleBarcodeResult()
                    }
            }
            .refreshable {
                print("🔴 DEBUG: Refreshable triggered")
                viewModel.loadFoods()
            }
            .alert(isEnglishLanguage ? "Error" : "Алдаа", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                print("🔴 DEBUG: NutritionDatabaseView onAppear called")
                // Notify that a sheet is presented
                NotificationCenter.default.post(name: Notification.Name("sheetPresented"), object: nil)
                setupInitialState()
            }
            .onDisappear {
                print("🔴 DEBUG: NutritionDatabaseView onDisappear called")
                // Notify that the sheet is dismissed
                NotificationCenter.default.post(name: Notification.Name("sheetDismissed"), object: nil)
                cleanupState()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("refreshNutritionDatabase"))) { _ in
                print("🔴 DEBUG: Received refreshNutritionDatabase notification")
                handleRefreshNotification()
            }
            .onReceive(viewModel.$isLoading) { isLoading in
                print("🔴 DEBUG: ViewModel isLoading changed to: \(isLoading)")
            }
            .onReceive(viewModel.$foods) { foods in
                print("🔴 DEBUG: ViewModel foods count changed to: \(foods.count)")
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onAppear {
            print("🔴 DEBUG: NavigationStack onAppear called")
        }
        .onDisappear {
            print("🔴 DEBUG: NavigationStack onDisappear called - THIS INDICATES THE ENTIRE VIEW IS CLOSING")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ModernSearchBar(
                text: $searchText,
                placeholder: isEnglishLanguage ? "Search foods..." : "Хоол хайх...",
                onBarcodeScan: {
                    showBarcodeScannerSheet = true
                }
            )
            .onChange(of: searchText) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.searchText = newValue
                }
            }
            
            ModernCategorySelector(
                selectedCategory: $viewModel.selectedCategory,
                onCategorySelected: { category in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectCategory(category)
                    }
                }
            )
            
            if !viewModel.foods.isEmpty {
                ModernFoodStatsRow(
                    totalFoods: viewModel.foods.count,
                    filteredCount: viewModel.filteredFoods.count,
                    selectedCategory: viewModel.selectedCategory
                )
            }
        }
        .padding(.bottom, 16)
    }
    
    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredFoods.isEmpty {
                emptyStateView
            } else {
                foodsListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.primaryApp))
            
            Text(isEnglishLanguage ? "Loading nutrition database..." : "Хоолны өгөгдлийг ачааллаж байна...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground(isDarkMode))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryApp, Color.accentApp]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text(isEnglishLanguage ? "No Foods Found" : "Хоол олдсонгүй")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(isEnglishLanguage ? "Try adjusting your search or explore different categories" : "Хайлтаа өөрчилж эсвэл өөр ангилал сонгоно уу")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                showAddFoodSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(isEnglishLanguage ? "Add Custom Food" : "Шинэ хоол нэмэх")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryApp, Color.primaryApp.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.primaryApp.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground(isDarkMode))
    }
    
    private var foodsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredFoods) { food in
                    FoodRowView(food: food) {
                        selectFood(food)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.adaptiveBackground(isDarkMode))
    }
    
    private var reloadButton: some View {
        Button(action: {
            viewModel.loadFoods()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.primaryApp)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showAddFoodSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryApp, Color.primaryApp.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.primaryApp.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        print("🔴 DEBUG: setupInitialState() called")
        print("🔴 DEBUG: Current state - hasLoaded: \(hasLoaded), isLoading: \(viewModel.isLoading)")
        
        // Reset all sheet states first
        selectedFood = nil
        showFoodDetailSheet = false
        showAddFoodSheet = false
        showBarcodeScannerSheet = false
        searchText = ""
        
        print("🔴 DEBUG: Reset all sheet states")
        
        // Reset view model state
        viewModel.searchText = ""
        viewModel.selectedCategory = nil
        
        print("🔴 DEBUG: Reset view model state")
        
        // Only load foods once on first appear
        if !hasLoaded && !viewModel.isLoading {
            print("🔴 DEBUG: Starting initial load of nutrition database")
            hasLoaded = true
            viewModel.loadFoods()
        } else {
            print("🔴 DEBUG: Skipping load - hasLoaded: \(hasLoaded), isLoading: \(viewModel.isLoading)")
        }
        print("🔴 DEBUG: setupInitialState() completed")
    }
    
    private func cleanupState() {
        print("🔴 DEBUG: cleanupState() called")
        selectedFood = nil
        showFoodDetailSheet = false
        showAddFoodSheet = false
        showBarcodeScannerSheet = false
        print("🔴 DEBUG: cleanupState() completed")
    }
    
    private func handleRefreshNotification() {
        print("🔴 DEBUG: handleRefreshNotification() called")
        print("🔴 DEBUG: Current state - hasLoaded: \(hasLoaded), isLoading: \(viewModel.isLoading)")
        
        // Prevent refresh during initial loading to avoid conflicts
        guard hasLoaded && !viewModel.isLoading else {
            print("⚠️ DEBUG: Skipping refresh notification - view is still loading or hasn't completed initial load")
            return
        }
        
        print("🔄 DEBUG: Handling refresh notification - reloading foods")
        viewModel.loadFoods()
        print("🔴 DEBUG: handleRefreshNotification() completed")
    }
    
    private func selectFood(_ food: NutritionData) {
        print("🔴 DEBUG: selectFood() called for: \(food.name)")
        
        // Set the selected food first
        selectedFood = food
        print("🔴 DEBUG: selectedFood set to: \(food.name)")
        
        // Then show the sheet with a small delay to ensure state is properly set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            print("🔴 DEBUG: Setting showFoodDetailSheet to true")
            showFoodDetailSheet = true
        }
        print("🔴 DEBUG: selectFood() completed")
    }
    
    private func handleBarcodeResult() {
        print("🔴 DEBUG: handleBarcodeResult() called")
        if !viewModel.scannedBarcode.isEmpty {
            print("🔴 DEBUG: Processing barcode: \(viewModel.scannedBarcode)")
            if let food = viewModel.getFoodByBarcode(viewModel.scannedBarcode) {
                print("🔴 DEBUG: Found food for barcode, selecting: \(food.name)")
                selectFood(food)
            } else {
                print("🔴 DEBUG: No food found for barcode")
                viewModel.errorMessage = isEnglishLanguage ? 
                    "No food found with barcode: \(viewModel.scannedBarcode)" : 
                    "Баркодтой хоол олдсонгүй: \(viewModel.scannedBarcode)"
                viewModel.showErrorAlert = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🔴 DEBUG: Clearing scanned barcode")
                viewModel.scannedBarcode = ""
            }
        } else {
            print("🔴 DEBUG: No barcode to process")
        }
        print("🔴 DEBUG: handleBarcodeResult() completed")
    }
}

// MARK: - Food Row Component
struct FoodRowView: View {
    let food: NutritionData
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Modern food image with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                categoryColor(food.category).opacity(0.3),
                                categoryColor(food.category).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                AsyncFoodImageView(imageURL: food.imageURL, category: food.category, size: 60)
            }
            
            // Food details with improved typography
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let currentUserId = AuthService.shared.getCurrentUserId(),
                       food.creatorUserId == currentUserId {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundColor(Color.infoApp)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.infoApp.opacity(0.15))
                        )
                    }
                }
                
                HStack(spacing: 16) {
                    Label("\(Int(food.calories))", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(Color.warningApp)
                        .fontWeight(.medium)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(food.servingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if food.barcode != nil {
                        Image(systemName: "barcode")
                            .font(.caption)
                            .foregroundColor(Color.infoApp)
                    }
                }
            }
            
            Spacer()
            
            // Modern macro display and action button
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ModernMacroChip(value: String(Int(food.protein)), label: "У", color: Color.infoApp)
                    ModernMacroChip(value: String(Int(food.carbs)), label: "Н", color: Color.successApp)
                    ModernMacroChip(value: String(Int(food.fat)), label: "Ө", color: Color.accentApp)
                }
                
                Button(action: onTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.primaryApp)
                        .background(
                            Circle()
                                .fill(Color.primaryApp.opacity(0.1))
                                .frame(width: 32, height: 32)
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    (AuthService.shared.getCurrentUserId() == food.creatorUserId) ? Color.infoApp.opacity(0.5) : Color.clear,
                    lineWidth: (AuthService.shared.getCurrentUserId() == food.creatorUserId) ? 2 : 1
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    NutritionDatabaseView()
}
