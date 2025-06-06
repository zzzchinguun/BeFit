//
//  ModernFoodDetailView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import SwiftUI
import CoreImage

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
    @State private var isAdding = false
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
                    heroSection
                    
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
                
                // Initialize quantity with the food's serving size if not already set
                if quantity.isEmpty {
                    quantity = String(Int(food.servingSizeGrams))
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var heroSection: some View {
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
                if let currentUserId = AuthService.shared.getCurrentUserId(),
                   food.creatorUserId == currentUserId {
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
            guard !isAdding else { return }
            Task {
                isAdding = true
                await addToMealLog()
                showingAddedAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isPresented = false
                }
            }
        }) {
            HStack(spacing: 12) {
                if isAdding {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                
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
        .disabled(isAdding)
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
    
    // MARK: - Helper Functions
    
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
} 
