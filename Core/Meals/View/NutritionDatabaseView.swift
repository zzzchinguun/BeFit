//
//  NutritionDatabaseView.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import SwiftUI
import Foundation
import CoreImage
import UIKit

// MARK: - Global Helper Functions

/// Global function for category colors that can be accessed by all structs
func categoryColor(_ category: FoodCategory) -> Color {
    switch category {
    case .meat: return Color.accentApp
    case .dairy: return Color.infoApp
    case .grains: return Color.warningApp
    case .fruits: return Color.successApp
    case .vegetables: return Color.primaryApp
    case .nuts: return Color.warningApp
    case .beverages: return Color.infoApp
    case .snacks: return Color.accentApp
    case .custom: return Color.primaryApp
    }
}

struct NutritionDatabaseView: View {
    @StateObject var viewModel = NutritionDatabaseViewModel()
    @State private var showAddFoodSheet = false
    @State private var showFoodDetailSheet = false
    @State private var showBarcodeScannerSheet = false
    @State private var selectedFood: NutritionData?
    @State private var searchText = ""
    @State private var hasLoaded = false // Add flag to prevent multiple loads
    @State private var pendingApprovalCache: [String: Bool] = [:] // Cache for pending approval results
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern header with search and filters
                VStack(spacing: 16) {
                    // Search bar with modern design
                    ModernSearchBar(text: $searchText, placeholder: isEnglishLanguage ? "Search foods..." : "Хоол хайх...", onBarcodeScan: {
                        showBarcodeScannerSheet = true
                    })
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchText = newValue
                        }
                    
                    // Category filters with horizontal scroll
                    ModernCategorySelector(
                        selectedCategory: $viewModel.selectedCategory,
                        onCategorySelected: { category in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectCategory(category)
                            }
                        }
                    )
                    
                    // Quick stats with modern design
                    if !viewModel.foods.isEmpty {
                        ModernFoodStatsRow(
                            totalFoods: viewModel.foods.count,
                            filteredCount: viewModel.filteredFoods.count,
                            selectedCategory: viewModel.selectedCategory
                        )
                    }
                }
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.primaryApp.opacity(0.1),
                            Color.secondaryApp.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Content area
                Group {
                    if viewModel.isLoading {
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
                        
                    } else if viewModel.filteredFoods.isEmpty {
                        modernEmptyState
                    } else {
                        modernFoodsList
                    }
                }
            }
            .background(Color.adaptiveBackground(isDarkMode))
            .navigationTitle(isEnglishLanguage ? "Nutrition Library" : "Хоолны сан")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Only show reload button if already loaded to prevent initial double load
                        if hasLoaded {
                            Button(action: {
                                // Clear cache before reloading
                                pendingApprovalCache.removeAll()
                                hasLoaded = false
                                viewModel.loadFoods()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.primaryApp)
                            }
                        }
                        
                        modernAddButton
                    }
                }
            }
            .sheet(isPresented: $showAddFoodSheet) {
                ModernAddCustomFoodView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFoodDetailSheet) {
                if let food = selectedFood {
                    ModernFoodDetailView(food: food, viewModel: viewModel, isPresented: $showFoodDetailSheet)
                } else {
                    EmptyView()
                }
            }
            .fullScreenCover(isPresented: $showBarcodeScannerSheet) {
                BarcodeScannerView(scannedCode: $viewModel.scannedBarcode, isScanning: $showBarcodeScannerSheet)
                    .onDisappear {
                        handleBarcodeResult()
                    }
            }
            .refreshable {
                // Clear cache and reload
                pendingApprovalCache.removeAll()
                viewModel.loadFoods()
            }
            .alert(isEnglishLanguage ? "Error" : "Алдаа", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                // Only load once when view appears
                if !hasLoaded {
                    viewModel.loadFoods()
                    hasLoaded = true
                }
                // Reset selectedFood on appear to ensure clean state
                selectedFood = nil
            }
            .onDisappear {
                // Clean up when leaving
                selectedFood = nil
            }
            // Remove the problematic notification observers that cause multiple loads
            // .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            //     viewModel.loadFoods()
            // }
            // Only keep this one for explicit refreshes after custom food is added
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("refreshNutritionDatabase"))) { _ in
                // Clear cache and reload only if already loaded
                if hasLoaded {
                    pendingApprovalCache.removeAll()
                    viewModel.loadFoods()
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    // MARK: - Modern UI Components
    
    private var modernAddButton: some View {
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
    
    private var modernEmptyState: some View {
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
    
    private var modernFoodsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredFoods) { food in
                    modernFoodRow(food)
                        .onTapGesture {
                            // Ensure we clear any previous selection first
                            selectedFood = nil
                            
                            // Use a small delay to ensure state is updated
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedFood = food
                                showFoodDetailSheet = true
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.adaptiveBackground(isDarkMode))
    }
    
    private func modernFoodRow(_ food: NutritionData) -> some View {
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
                    
                    // Show pending approval indicator for unverified meals
                    if isPendingApproval(food) {
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
                
                Button(action: {
                    // Ensure we clear any previous selection first
                    selectedFood = nil
                    
                    // Use a small delay to ensure state is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedFood = food
                        showFoodDetailSheet = true
                    }
                }) {
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
                    isPendingApproval(food) ? Color.infoApp.opacity(0.5) : Color.clear,
                    lineWidth: isPendingApproval(food) ? 2 : 1
                )
        )
    }
    
    private func categoryButton(_ category: FoodCategory?, label: String) -> some View {
        Button(action: {
            viewModel.selectCategory(category)
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.selectedCategory == category ? 
                              LinearGradient(
                                gradient: Gradient(colors: [Color.primaryApp, Color.primaryApp.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                              ) :
                              LinearGradient(
                                gradient: Gradient(colors: [Color.secondaryApp.opacity(0.1), Color.secondaryApp.opacity(0.05)]),
                                startPoint: .leading,
                                endPoint: .trailing
                              )
                        )
                )
                .foregroundColor(viewModel.selectedCategory == category ? .white : Color.secondaryApp)
                .overlay(
                    Capsule()
                        .stroke(
                            viewModel.selectedCategory == category ? Color.clear : Color.secondaryApp.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
    }
    
    private func handleBarcodeResult() {
        if !viewModel.scannedBarcode.isEmpty {
            if let food = viewModel.getFoodByBarcode(viewModel.scannedBarcode) {
                // Clear previous selection first
                selectedFood = nil
                
                // Use a small delay to ensure state is updated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedFood = food
                    showFoodDetailSheet = true
                }
            } else {
                viewModel.errorMessage = isEnglishLanguage ? 
                    "No food found with barcode: \(viewModel.scannedBarcode)" : 
                    "Баркодтай хоол олдсонгүй: \(viewModel.scannedBarcode)"
                viewModel.showErrorAlert = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.scannedBarcode = ""
            }
        }
    }
    
    private func isPendingApproval(_ food: NutritionData) -> Bool {
        // Check cache first to prevent repeated calculations
        if let cachedResult = pendingApprovalCache[food.id] {
            return cachedResult
        }
        
        // Get current user ID for comparison
        guard let currentUserId = AuthService.shared.getCurrentUserId() else {
            pendingApprovalCache[food.id] = false
            return false
        }
        
        // Check if this food was created by the current user and might be pending approval
        let userUnverifiedMeals = viewModel.nutritionDataService.userUnverifiedMeals.value
        
        // Only log once per food to prevent console spam
        if pendingApprovalCache[food.id] == nil {
            print("🔍 Checking isPendingApproval for food: \(food.name) (ID: \(food.id))")
        }
        
        // First check: Is this food in the user's unverified meals list?
        let isInUnverifiedList = userUnverifiedMeals.contains { unverifiedMeal in
            let unverifiedNutritionData = unverifiedMeal.toNutritionData()
            return unverifiedNutritionData.id == food.id || 
                   (unverifiedMeal.name == food.name && unverifiedMeal.barcode == food.barcode)
        }
        
        // Second check: Was this food created by the current user?
        let isCreatedByCurrentUser = food.creatorUserId == currentUserId
        
        // Show pending approval indicator if:
        // 1. The food is in the user's unverified meals list, OR
        // 2. The food was created by the current user (regardless of verification status)
        let isPending = isInUnverifiedList || isCreatedByCurrentUser
        
        // Cache the result to prevent repeated calculations
        pendingApprovalCache[food.id] = isPending
        
        // Only log the result once per food
        if pendingApprovalCache.count == 1 || food.id.hasSuffix("001") { // Log occasionally for debugging
            print("🔍 isPendingApproval result for \(food.name): \(isPending)")
        }
        
        return isPending
    }
}

// MARK: - Modern Components

struct ModernMacroChip: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(width: 28, height: 28)
        .background(
            Circle()
                .fill(color.opacity(0.15))
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AsyncFoodImageView: View {
    let imageURL: String?
    let category: FoodCategory
    let size: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: category.icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(categoryColor(category))
                    .frame(width: size, height: size)
                    .background(categoryColor(category).opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        isLoading && !loadFailed ? 
                        ProgressView()
                            .scaleEffect(0.5)
                            .opacity(0.7) : nil
                    )
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        guard let imageURL = imageURL,
              !imageURL.isEmpty,
              !loadFailed,
              image == nil,
              !isLoading else { return }
        
        isLoading = true
        
        Task {
            let randomDelay = Double.random(in: 0.1...0.3)
            try? await Task.sleep(nanoseconds: UInt64(randomDelay * 1_000_000_000))
            
            guard !Task.isCancelled else {
                await MainActor.run { 
                    isLoading = false 
                }
                return
            }
            
            do {
                if let imageData = await ServiceContainer.shared.imageStorageService.getImage(with: imageURL),
                   let loadedImage = UIImage(data: imageData) {
                    
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.loadFailed = true
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadFailed = true
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Modern Add Custom Food View
struct ModernAddCustomFoodView: View {
    @ObservedObject var viewModel: NutritionDatabaseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedCategory: FoodCategory = .custom
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    @State private var sugar = ""
    @State private var servingSize = ""
    @State private var servingDescription = ""
    @State private var barcode = ""
    @State private var imageData: Data? = nil
    @State private var isScanning = false
    @State private var showSubmissionAlert = false
    @State private var submissionMessage = ""
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    private var calculatedCalories: Int {
        let proteinGrams = Double(protein) ?? 0
        let carbsGrams = Double(carbs) ?? 0
        let fatGrams = Double(fat) ?? 0
        
        return Int((proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9))
    }
    
    var formIsValid: Bool {
        !name.isEmpty &&
        !protein.isEmpty &&
        !carbs.isEmpty &&
        !fat.isEmpty &&
        !servingSize.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 16) {
                        Text(isEnglishLanguage ? "Create Custom Food" : "Хувийн хоол үүсгэх")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(isEnglishLanguage ? "Add your own food to the nutrition library" : "Хоолны санд өөрийн хоол нэмэх")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Image picker section
                    VStack(spacing: 12) {
                        Text(isEnglishLanguage ? "Photo" : "Зураг")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ImagePickerView(imageData: $imageData)
                    }
                    .padding(.horizontal, 20)
                    
                    // Basic information
                    modernFormSection(title: isEnglishLanguage ? "Basic Information" : "Үндсэн мэдээлэл") {
                        VStack(spacing: 16) {
                            modernTextField(
                                title: isEnglishLanguage ? "Food Name" : "Хоолны нэр",
                                text: $name,
                                placeholder: isEnglishLanguage ? "Enter food name..." : "Хоолны нэр оруулах...",
                                icon: "fork.knife"
                            )
                            
                            modernCategoryPicker
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Barcode (Optional)" : "Баркод (Заавал биш)",
                                text: $barcode,
                                placeholder: isEnglishLanguage ? "Scan or enter barcode..." : "Баркод скан хийх эсвэл оруулах...",
                                icon: "barcode",
                                keyboardType: .numberPad,
                                trailingButton: {
                                    Button(action: {
                                        isScanning = true
                                    }) {
                                        Image(systemName: "barcode.viewfinder")
                                            .foregroundColor(Color.primaryApp)
                                    }
                                }
                            )
                        }
                    }
                    
                    // Nutrition information
                    modernFormSection(title: isEnglishLanguage ? "Nutrition Per Serving" : "Тэжээллэг чанар") {
                        VStack(spacing: 16) {
                            // Auto-calculated calories display
                            modernCaloriesDisplay
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Protein (g)" : "Уураг (г)",
                                text: $protein,
                                placeholder: "0",
                                icon: "figure.arms.open",
                                keyboardType: .decimalPad
                            )
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Carbohydrates (g)" : "Нүүрс ус (г)",
                                text: $carbs,
                                placeholder: "0",
                                icon: "leaf.fill",
                                keyboardType: .decimalPad
                            )
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Fat (g)" : "Өөх тос (г)",
                                text: $fat,
                                placeholder: "0",
                                icon: "drop.fill",
                                keyboardType: .decimalPad
                            )
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Fiber (g)" : "Эслэг (г)",
                                text: $fiber,
                                placeholder: "0",
                                icon: "leaf.arrow.circlepath",
                                keyboardType: .decimalPad
                            )
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Sugar (g)" : "Сахар (г)",
                                text: $sugar,
                                placeholder: "0",
                                icon: "cube.fill",
                                keyboardType: .decimalPad
                            )
                        }
                    }
                    
                    // Serving information
                    modernFormSection(title: isEnglishLanguage ? "Serving Information" : "Хэмжээний мэдээлэл") {
                        VStack(spacing: 16) {
                            modernTextField(
                                title: isEnglishLanguage ? "Serving Size (g)" : "Хэмжээ (г)",
                                text: $servingSize,
                                placeholder: "100",
                                icon: "scalemass.fill",
                                keyboardType: .decimalPad
                            )
                            
                            modernTextField(
                                title: isEnglishLanguage ? "Description" : "Тайлбар",
                                text: $servingDescription,
                                placeholder: isEnglishLanguage ? "e.g., '1 cup', '1 piece'" : "ж.нь., '1 аяга', '1 ширхэг'",
                                icon: "text.alignleft"
                            )
                        }
                    }
                    
                    // Save button
                    Button(action: saveFood) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text(isEnglishLanguage ? "Save to Library" : "Санд хадгалах")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: formIsValid ? 
                                    [Color.primaryApp, Color.primaryApp.opacity(0.8)] :
                                    [Color.gray, Color.gray.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: (formIsValid ? Color.primaryApp : Color.gray).opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!formIsValid)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.adaptiveBackground(isDarkMode))
            .navigationTitle(isEnglishLanguage ? "Add Food" : "Хоол нэмэх")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEnglishLanguage ? "Cancel" : "Цуцлах") {
                        dismiss()
                    }
                    .foregroundColor(Color.accentApp)
                }
            }
            .fullScreenCover(isPresented: $isScanning) {
                BarcodeScannerView(scannedCode: $barcode, isScanning: $isScanning)
            }
            .onChange(of: isScanning) { scanning in
                if scanning {
                    // Start scanning
                }
            }
            .onAppear {
                // Add notification observers
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("customFoodSubmitted"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let foodName = notification.object as? String {
                        submissionMessage = isEnglishLanguage ? 
                            "\(foodName) has been submitted for admin verification" :
                            "\(foodName) хоол админд шалгуулахаар илгээгдлээ"
                        showSubmissionAlert = true
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("customFoodSavedLocally"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let foodName = notification.object as? String {
                        submissionMessage = isEnglishLanguage ? 
                            "\(foodName) has been saved locally" :
                            "\(foodName) хоол локал санд хадгалагдлаа"
                        showSubmissionAlert = true
                    }
                }
            }
            .alert(isEnglishLanguage ? "Food Submitted" : "Хоол илгээгдлээ", isPresented: $showSubmissionAlert) {
                Button(isEnglishLanguage ? "OK" : "За") {
                    dismiss()
                }
            } message: {
                Text(submissionMessage)
            }
        }
    }
    
    private var modernCaloriesDisplay: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color.warningApp)
                Text(isEnglishLanguage ? "Calories (Auto-calculated)" : "Калори (Автомат тооцоо)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Text("\(calculatedCalories)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.warningApp)
                
                Text("ккал")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(isEnglishLanguage ? "P: 4 • C: 4 • F: 9 cal/g" : "У: 4 • Н: 4 • Ө: 9 кал/г")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.warningApp.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.warningApp.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var modernCategoryPicker: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(Color.primaryApp)
                Text(isEnglishLanguage ? "Category" : "Ангилал")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FoodCategory.allCases) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.title2)
                                    .foregroundColor(selectedCategory == category ? .white : categoryColor(category))
                                
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .lineLimit(1)
                            }
                            .frame(width: 80, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedCategory == category ? 
                                          categoryColor(category) : 
                                          categoryColor(category).opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedCategory == category ? Color.clear : categoryColor(category).opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func modernFormSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCard(isDarkMode))
                .shadow(
                    color: isDarkMode ? Color.clear : Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isDarkMode ? Color.white.opacity(0.1) : Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func modernTextField<TrailingContent: View>(
        title: String,
        text: Binding<String>,
        placeholder: String,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        @ViewBuilder trailingButton: () -> TrailingContent = { EmptyView() }
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.primaryApp)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .font(.body)
                
                trailingButton()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDarkMode ? Color.neutralBackgroundDark.opacity(0.8) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primaryApp.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func saveFood() {
        var imageURL: String? = nil
        if let imageData = imageData {
            imageURL = ServiceContainer.shared.imageStorageService.saveImage(imageData)
        }
        
        viewModel.addCustomFood(
            name: name,
            category: selectedCategory,
            calories: Double(calculatedCalories),
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            fiber: Double(fiber) ?? 0,
            sugar: Double(sugar) ?? 0,
            servingSizeGrams: Double(servingSize) ?? 0,
            servingDescription: servingDescription.isEmpty ? "\(servingSize)г" : servingDescription,
            imageURL: imageURL,
            barcode: barcode.isEmpty ? nil : barcode
        )
        
        // Don't dismiss immediately - let the notification handle it
    }
}

// MARK: - Modern Food Detail View
struct ModernFoodDetailView: View {
    let food: NutritionData
    let viewModel: NutritionDatabaseViewModel
    @Binding var isPresented: Bool
    @State private var quantity = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var barcodeImage: UIImage?
    @State private var foodImage: UIImage? = nil
    @State private var showBarcodeSheet = false
    @State private var showingAddedAlert = false
    @State private var pendingApprovalCache: [String: Bool] = [:] // Move cache here
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var calculatedNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let weight = Double(quantity) ?? food.servingSizeGrams
        return food.valuesForWeight(weight)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section with image and title
                    VStack(spacing: 16) {
                        // Food image with modern design
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
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
                                .frame(height: 200)
                            
                            if let image = foodImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                Image(systemName: food.category.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(categoryColor(food.category))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Food info
                        VStack(spacing: 12) {
                            Text(food.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            // Show pending approval status if applicable
                            if isPendingApproval(food) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color.infoApp)
                                    
                                    Text(isEnglishLanguage ? "Created by You" : "Таны үүсгэсэн хоол")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.infoApp)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.infoApp.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.infoApp.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Image(systemName: food.category.icon)
                                        .foregroundColor(categoryColor(food.category))
                                    Text(food.category.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if food.barcode != nil {
                                    Button {
                                        generateBarcodeImage()
                                        showBarcodeSheet = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "barcode")
                                                .foregroundColor(Color.infoApp)
                                            Text(isEnglishLanguage ? "View Barcode" : "Баркод харах")
                                                .font(.subheadline)
                                                .foregroundColor(Color.infoApp)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Quantity selector with modern design
                    modernQuantitySection
                    
                    // Nutrition information with cards
                    modernNutritionSection
                    
                    // Meal type selector
                    modernMealTypeSection
                    
                    // Add to meal log button
                    modernAddButton
                }
                .padding(.vertical)
            }
            .background(Color.adaptiveBackground(isDarkMode))
            .navigationTitle(isEnglishLanguage ? "Food Details" : "Хоолны дэлгэрэнгүй")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglishLanguage ? "Done" : "Дуусгах") {
                        isPresented = false
                    }
                    .foregroundColor(Color.accentApp)
                }
            }
            .overlay {
                if showingAddedAlert {
                    modernSuccessAlert
                }
            }
            .sheet(isPresented: $showBarcodeSheet) {
                modernBarcodeSheet
            }
            .task {
                await loadFoodImage()
            }
        }
    }
    
    private var modernQuantitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isEnglishLanguage ? "Quantity" : "Хэмжээ")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Button(action: {
                        let current = Double(quantity) ?? 100
                        if current > 10 {
                            quantity = String(Int(current - 10))
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.accentApp)
                    }
                    
                    VStack(spacing: 4) {
                        TextField("100", text: $quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryApp)
                            .frame(maxWidth: 100)
                        
                        Text("грамм")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryApp.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryApp.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Button(action: {
                        let current = Double(quantity) ?? 100
                        quantity = String(Int(current + 10))
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.primaryApp)
                    }
                }
                
                Text(isEnglishLanguage ? "Standard serving: \(food.servingDescription)" : "Стандарт хэмжээ: \(food.servingDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCard(isDarkMode))
                .shadow(
                    color: isDarkMode ? Color.clear : Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isDarkMode ? Color.white.opacity(0.1) : Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
    }
    
    private var modernNutritionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isEnglishLanguage ? "Nutrition Information" : "Тэжээллэг чанар")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                modernNutritionCard(
                    title: isEnglishLanguage ? "Calories" : "Калори",
                    value: String(format: "%.0f", calculatedNutrition.calories),
                    unit: "ккал",
                    icon: "flame.fill",
                    color: Color.warningApp
                )
                
                modernNutritionCard(
                    title: isEnglishLanguage ? "Protein" : "Уураг",
                    value: String(format: "%.1f", calculatedNutrition.protein),
                    unit: "г",
                    icon: "figure.arms.open",
                    color: Color.infoApp
                )
                
                modernNutritionCard(
                    title: isEnglishLanguage ? "Carbs" : "Нүүрс ус",
                    value: String(format: "%.1f", calculatedNutrition.carbs),
                    unit: "г",
                    icon: "leaf.fill",
                    color: Color.successApp
                )
                
                modernNutritionCard(
                    title: isEnglishLanguage ? "Fat" : "Өөх тос",
                    value: String(format: "%.1f", calculatedNutrition.fat),
                    unit: "г",
                    icon: "drop.fill",
                    color: Color.accentApp
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func modernNutritionCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text("\(value) \(unit)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var modernMealTypeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isEnglishLanguage ? "Add to Meal" : "Хоолонд нэмэх")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MealType.allCases) { mealType in
                    Button(action: {
                        selectedMealType = mealType
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: mealType.icon)
                                .font(.title2)
                                .foregroundColor(selectedMealType == mealType ? .white : mealTypeColor(mealType))
                            
                            Text(mealType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedMealType == mealType ? .white : .primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMealType == mealType ? 
                                      mealTypeColor(mealType) : 
                                      mealTypeColor(mealType).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedMealType == mealType ? Color.clear : mealTypeColor(mealType).opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCard(isDarkMode))
                .shadow(
                    color: isDarkMode ? Color.clear : Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isDarkMode ? Color.white.opacity(0.1) : Color.clear,
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
    }
    
    private var modernAddButton: some View {
        Button(action: {
            Task {
                await addToMealLog()
                showingAddedAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isPresented = false
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                
                Text(isEnglishLanguage ? "Add to Meal Log" : "Хоолны бүртгэлд нэмэх")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.primaryApp, Color.primaryApp.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.primaryApp.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var modernSuccessAlert: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.successApp)
            
            Text(isEnglishLanguage ? "Added to Meal Log!" : "Хоолны бүртгэлд нэмэгдлээ!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.adaptiveCard(isDarkMode))
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingAddedAlert)
        .zIndex(100)
    }
    
    private var modernBarcodeSheet: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if let barcodeImage = barcodeImage {
                    VStack(spacing: 20) {
                        Text(isEnglishLanguage ? "Product Barcode" : "Бүтээгдэхүүний баркод")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(food.barcode ?? "")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .monospaced()
                        
                        Image(uiImage: barcodeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.adaptiveCard(isDarkMode))
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                        
                        Button(action: {
                            showBarcodeSheet = false
                        }) {
                            Text(isEnglishLanguage ? "Done" : "Дуусгах")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.primaryApp, Color.primaryApp.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding(32)
            .background(Color.adaptiveBackground(isDarkMode))
            .navigationTitle(isEnglishLanguage ? "Barcode" : "Баркод")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
        }
    }
    
    // Helper functions
    private func loadFoodImage() async {
        if let imageURL = food.imageURL {
            if let imageData = await ServiceContainer.shared.imageStorageService.getImage(with: imageURL),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    self.foodImage = image
                }
            }
        }
    }
    
    private func isPendingApproval(_ food: NutritionData) -> Bool {
        // Check cache first to prevent repeated calculations
        if let cachedResult = pendingApprovalCache[food.id] {
            return cachedResult
        }
        
        // Get current user ID for comparison
        guard let currentUserId = AuthService.shared.getCurrentUserId() else {
            pendingApprovalCache[food.id] = false
            return false
        }
        
        // Check if this food was created by the current user and might be pending approval
        let userUnverifiedMeals = viewModel.nutritionDataService.userUnverifiedMeals.value
        
        // Only log once per food to prevent console spam
        if pendingApprovalCache[food.id] == nil {
            print("🔍 Checking isPendingApproval for food: \(food.name) (ID: \(food.id))")
        }
        
        // First check: Is this food in the user's unverified meals list?
        let isInUnverifiedList = userUnverifiedMeals.contains { unverifiedMeal in
            let unverifiedNutritionData = unverifiedMeal.toNutritionData()
            return unverifiedNutritionData.id == food.id || 
                   (unverifiedMeal.name == food.name && unverifiedMeal.barcode == food.barcode)
        }
        
        // Second check: Was this food created by the current user?
        let isCreatedByCurrentUser = food.creatorUserId == currentUserId
        
        // Show pending approval indicator if:
        // 1. The food is in the user's unverified meals list, OR
        // 2. The food was created by the current user (regardless of verification status)
        let isPending = isInUnverifiedList || isCreatedByCurrentUser
        
        // Cache the result to prevent repeated calculations
        pendingApprovalCache[food.id] = isPending
        
        // Only log the result once per food
        if pendingApprovalCache.count == 1 || food.id.hasSuffix("001") { // Log occasionally for debugging
            print("🔍 isPendingApproval result for \(food.name): \(isPending)")
        }
        
        return isPending
    }
    
    private func generateBarcodeImage() {
        guard let barcode = food.barcode else { return }
        
        if let data = barcode.data(using: .ascii),
           let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                let context = CIContext()
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    barcodeImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
    
    private func addToMealLog() async {
        let weight = Double(quantity) ?? food.servingSizeGrams
        await viewModel.addFoodToMealLog(food: food, weight: weight, mealType: selectedMealType)
    }
    
    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return Color.warningApp
        case .lunch: return Color.infoApp
        case .dinner: return Color.accentApp
        case .snack: return Color.successApp
        }
    }
}

// MARK: - Modern Search Bar
struct ModernSearchBar: View {
    @Binding var text: String
    var placeholder: String
    var onBarcodeScan: (() -> Void)?
    @FocusState private var isSearchFocused: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isSearchFocused ? Color.primaryApp : .gray)
                    .font(.system(size: 18, weight: .medium))
                    
                TextField(placeholder, text: $text)
                    .font(.body)
                    .focused($isSearchFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDarkMode ? Color.neutralBackgroundDark.opacity(0.8) : Color.white)
                    .stroke(isSearchFocused ? Color.primaryApp.opacity(0.5) : Color.primaryApp.opacity(0.3), lineWidth: 1)
            )
            
            // Barcode scanner button
            Button(action: {
                onBarcodeScan?()
            }) {
                Image(systemName: "barcode.viewfinder")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentApp, Color.accentApp.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.accentApp.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Modern Category Selector
struct ModernCategorySelector: View {
    @Binding var selectedCategory: FoodCategory?
    let onCategorySelected: (FoodCategory?) -> Void
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryButton(nil, label: isEnglishLanguage ? "All" : "Бүгд")
                
                ForEach(FoodCategory.allCases) { category in
                    categoryButton(category, label: category.rawValue)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func categoryButton(_ category: FoodCategory?, label: String) -> some View {
        Button(action: {
            onCategorySelected(category)
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(selectedCategory == category ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedCategory == category ? Color.primaryApp : Color.secondaryApp.opacity(0.2))
                )
                .foregroundColor(selectedCategory == category ? .white : Color.secondaryApp)
                .overlay(
                    Capsule()
                        .stroke(
                            selectedCategory == category ? Color.clear : Color.secondaryApp.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Modern Food Stats Row
struct ModernFoodStatsRow: View {
    let totalFoods: Int
    let filteredCount: Int
    let selectedCategory: FoodCategory?
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: isEnglishLanguage ? "Total" : "Нийт",
                value: "\(totalFoods)",
                icon: "fork.knife",
                color: Color.primaryApp
            )
            
            StatCard(
                title: isEnglishLanguage ? "Showing" : "Харагдаж буй",
                value: "\(filteredCount)",
                icon: "eye",
                color: Color.infoApp
            )
            
            if let category = selectedCategory {
                StatCard(
                    title: isEnglishLanguage ? "Category" : "Ангилал",
                    value: String(category.rawValue.prefix(8)),
                    icon: category.icon,
                    color: categoryColor(category)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NutritionDatabaseView()
} 
