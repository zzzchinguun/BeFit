//
//  ModernAddCustomFoodView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 5/10/25.
//

import SwiftUI

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
                setupNotificationObservers()
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
    
    private func setupNotificationObservers() {
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
    
    // MARK: - UI Components
    
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
    }
} 
