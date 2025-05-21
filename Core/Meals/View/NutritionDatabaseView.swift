//
//  NutritionDatabaseView.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import SwiftUI

struct NutritionDatabaseView: View {
    @StateObject var viewModel = NutritionDatabaseViewModel()
    @State private var showAddFoodSheet = false
    @State private var showFoodDetailSheet = false
    @State private var showBarcodeScannerSheet = false
    @State private var selectedFood: NutritionData?
    @State private var searchText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All category button
                        categoryButton(nil, label: isEnglishLanguage ? "All" : "Бүгд")
                        
                        // Category buttons
                        ForEach(FoodCategory.allCases) { category in
                            categoryButton(category, label: category.rawValue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                // Search bar with barcode button
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        
                    TextField(isEnglishLanguage ? "Search foods..." : "Хоол хайх...", text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchText = newValue
                        }
                        
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        showBarcodeScannerSheet = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if viewModel.filteredFoods.isEmpty {
                    ContentUnavailableView {
                        Label(
                            isEnglishLanguage ? "No Foods Found" : "Хоол олдсонгүй",
                            systemImage: "fork.knife"
                        )
                    } description: {
                        Text(isEnglishLanguage ? "Try adjusting your search or category filter." : "Хайлт эсвэл ангиллаа өөрчилнө үү.")
                    } actions: {
                        Button(isEnglishLanguage ? "Add Custom Food" : "Шинэ хоол нэмэх") {
                            showAddFoodSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredFoods) { food in
                            foodRow(food)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedFood = food
                                    showFoodDetailSheet = true
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(isEnglishLanguage ? "Nutrition Database" : "Хоолны өгөгдөл")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddFoodSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFoodSheet) {
                AddCustomFoodView(viewModel: viewModel)
            }
            .sheet(isPresented: $showFoodDetailSheet) {
                if let food = selectedFood {
                    FoodDetailView(viewModel: viewModel, food: food)
                }
            }
            .fullScreenCover(isPresented: $showBarcodeScannerSheet) {
                BarcodeScannerView(scannedCode: $viewModel.scannedBarcode, isScanning: $showBarcodeScannerSheet)
                    .onDisappear {
                        // Check if a barcode was scanned
                        if !viewModel.scannedBarcode.isEmpty {
                            // Look up food by barcode
                            if let food = viewModel.getFoodByBarcode(viewModel.scannedBarcode) {
                                selectedFood = food
                                showFoodDetailSheet = true
                            } else {
                                viewModel.errorMessage = isEnglishLanguage ? 
                                    "No food found with barcode: \(viewModel.scannedBarcode)" : 
                                    "Баркодтай хоол олдсонгүй: \(viewModel.scannedBarcode)"
                                viewModel.showErrorAlert = true
                            }
                            
                            // Reset the scanned barcode
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.scannedBarcode = ""
                            }
                        }
                    }
            }
            .refreshable {
                viewModel.loadFoods()
            }
            .alert(isEnglishLanguage ? "Error" : "Алдаа", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.loadFoods()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    // MARK: - Helper Views
    
    /// Category button
    private func categoryButton(_ category: FoodCategory?, label: String) -> some View {
        Button(action: {
            viewModel.selectCategory(category)
        }) {
            Text(label)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.selectedCategory == category ? Color.accentApp : Color.secondaryApp.opacity(0.2))
                )
                .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                .fontWeight(viewModel.selectedCategory == category ? .semibold : .regular)
        }
    }
    
    /// Food row
    private func foodRow(_ food: NutritionData) -> some View {
        HStack(spacing: 15) {
            // Food thumbnail or icon
            AsyncFoodImageView(imageURL: food.imageURL, category: food.category, size: 36)
            
            // Title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    Label("\(Int(food.calories))ккал", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(food.servingDescription)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if food.barcode != nil {
                        Image(systemName: "barcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Nutrition values
            HStack(spacing: 12) {
                MacroCircleSmall(value: String(Int(food.protein)), label: "У", color: .blue)
                MacroCircleSmall(value: String(Int(food.carbs)), label: "Н", color: .green)
                MacroCircleSmall(value: String(Int(food.fat)), label: "Ө", color: .red)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    /// Category color
    private func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
        case .meat: return .red
        case .dairy: return .blue
        case .grains: return .brown
        case .fruits: return .orange
        case .vegetables: return .green
        case .nuts: return .yellow
        case .beverages: return .cyan
        case .snacks: return .purple
        case .custom: return .accentApp
        }
    }
}

// MARK: - Macro Circle Small Component
struct MacroCircleSmall: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(width: 28, height: 28)
        .background(color.opacity(0.1))
        .clipShape(Circle())
    }
}

// MARK: - Add Custom Food View
struct AddCustomFoodView: View {
    @ObservedObject var viewModel: NutritionDatabaseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedCategory: FoodCategory = .custom
    @State private var calories = ""
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
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    // Inject ImageStorageService
    @State private var imageStorageService: ImageStorageServiceProtocol = ServiceContainer.shared.imageStorageService
    
    var formIsValid: Bool {
        !name.isEmpty &&
        !calories.isEmpty &&
        !protein.isEmpty &&
        !carbs.isEmpty &&
        !fat.isEmpty &&
        !servingSize.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(isEnglishLanguage ? "Food Details" : "Хоолны мэдээлэл")) {
                    TextField(isEnglishLanguage ? "Food Name" : "Хоолны нэр", text: $name)
                    
                    Picker(isEnglishLanguage ? "Category" : "Ангилал", selection: $selectedCategory) {
                        ForEach(FoodCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    // Image picker
                    HStack {
                        Text(isEnglishLanguage ? "Photo" : "Зураг")
                        Spacer()
                        ImagePickerView(imageData: $imageData)
                    }
                    
                    // Barcode field with scanner button
                    HStack {
                        TextField(isEnglishLanguage ? "Barcode (optional)" : "Баркод (заавал биш)", text: $barcode)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            isScanning = true
                        }) {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text(isEnglishLanguage ? "Nutrition per Serving" : "Тэжээллэг чанар")) {
                    HStack {
                        Text("🔥")
                        TextField(isEnglishLanguage ? "Calories" : "Калори", text: $calories)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("🥩")
                        TextField(isEnglishLanguage ? "Protein (g)" : "Уураг (г)", text: $protein)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("🌾")
                        TextField(isEnglishLanguage ? "Carbs (g)" : "Нүүрс ус (г)", text: $carbs)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("🧈")
                        TextField(isEnglishLanguage ? "Fat (g)" : "Өөх тос (г)", text: $fat)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("🌿")
                        TextField(isEnglishLanguage ? "Fiber (g)" : "Эслэг (г)", text: $fiber)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("🍯")
                        TextField(isEnglishLanguage ? "Sugar (g)" : "Сахар (г)", text: $sugar)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text(isEnglishLanguage ? "Serving Information" : "Хэмжээ")) {
                    HStack {
                        Text("⚖️")
                        TextField(isEnglishLanguage ? "Serving Size (g)" : "Хэмжээ (г)", text: $servingSize)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("📏")
                        TextField(isEnglishLanguage ? "Description (e.g., '1 cup')" : "Тайлбар (ж.нь., '1 аяга')", text: $servingDescription)
                    }
                }
            }
            .navigationTitle(isEnglishLanguage ? "Add Custom Food" : "Шинэ хоол нэмэх")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEnglishLanguage ? "Cancel" : "Цуцлах") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglishLanguage ? "Save" : "Хадгалах") {
                        saveFood()
                    }
                    .disabled(!formIsValid)
                }
            }
            .fullScreenCover(isPresented: $isScanning) {
                BarcodeScannerView(scannedCode: $barcode, isScanning: $isScanning)
            }
        }
    }
    
    private func saveFood() {
        // Save image if present and get URL
        var imageURL: String? = nil
        if let imageData = imageData {
            imageURL = imageStorageService.saveImage(imageData)
        }
        
        viewModel.addCustomFood(
            name: name,
            category: selectedCategory,
            calories: Double(calories) ?? 0,
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
        
        dismiss()
    }
}

// MARK: - Food Detail View
struct FoodDetailView: View {
    @ObservedObject var viewModel: NutritionDatabaseViewModel
    let food: NutritionData
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: String = "100"
    @State private var selectedMealType: MealType = .lunch
    @State private var showingAddedAlert = false
    @State private var foodImage: UIImage? = nil
    @State private var showBarcodeSheet = false
    @State private var barcodeImage: UIImage? = nil
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    
    // Inject ImageStorageService
    private let imageStorageService: ImageStorageServiceProtocol = ServiceContainer.shared.imageStorageService
    
    var calculatedNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let weight = Double(quantity) ?? food.servingSizeGrams
        return food.valuesForWeight(weight)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with image, name and category
                    VStack(spacing: 12) {
                        // Food image if available
                        if let image = foodImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Image(systemName: food.category.icon)
                                        .foregroundColor(categoryColor(food.category))
                                    
                                    Text(food.category.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Barcode button if available
                            if food.barcode != nil {
                                Button {
                                    generateBarcodeImage()
                                    showBarcodeSheet = true
                                } label: {
                                    Image(systemName: "barcode")
                                        .font(.system(size: 22))
                                        .foregroundColor(.accentApp)
                                        .frame(width: 44, height: 44)
                                        .background(Color.accentApp.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quantity selector
                    VStack(spacing: 10) {
                        Text(isEnglishLanguage ? "Quantity (grams)" : "Хэмжээ (грамм)")
                            .font(.headline)
                        
                        HStack {
                            Button(action: {
                                let current = Double(quantity) ?? 100
                                if current > 10 {
                                    quantity = String(Int(current - 10))
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentApp)
                            }
                            
                            TextField("100", text: $quantity)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button(action: {
                                let current = Double(quantity) ?? 100
                                quantity = String(Int(current + 10))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentApp)
                            }
                        }
                        
                        Text(isEnglishLanguage ? "Standard serving: \(food.servingDescription)" : "Стандарт хэмжээ: \(food.servingDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    
                    // Nutrition info
                    VStack(spacing: 15) {
                        Text(isEnglishLanguage ? "Nutrition Information" : "Тэжээллэг чанар")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Calories
                        NutritionRow(
                            label: isEnglishLanguage ? "Calories" : "Калори",
                            value: String(format: "%.0f", calculatedNutrition.calories),
                            unit: "ккал",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        Divider()
                        
                        // Protein
                        NutritionRow(
                            label: isEnglishLanguage ? "Protein" : "Уураг",
                            value: String(format: "%.1f", calculatedNutrition.protein),
                            unit: "г",
                            icon: "figure.arms.open",
                            color: .blue
                        )
                        
                        // Carbs
                        NutritionRow(
                            label: isEnglishLanguage ? "Carbohydrates" : "Нүүрс ус",
                            value: String(format: "%.1f", calculatedNutrition.carbs),
                            unit: "г",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        // Fat
                        NutritionRow(
                            label: isEnglishLanguage ? "Fat" : "Өөх тос",
                            value: String(format: "%.1f", calculatedNutrition.fat),
                            unit: "г",
                            icon: "drop.fill",
                            color: .red
                        )
                        
                        if food.fiber > 0 {
                            // Fiber
                            NutritionRow(
                                label: isEnglishLanguage ? "Fiber" : "Эслэг",
                                value: String(format: "%.1f", food.fiber * (Double(quantity) ?? 100) / food.servingSizeGrams),
                                unit: "г",
                                icon: "leaf.arrow.circlepath",
                                color: .mint
                            )
                        }
                        
                        if food.sugar > 0 {
                            // Sugar
                            NutritionRow(
                                label: isEnglishLanguage ? "Sugar" : "Сахар",
                                value: String(format: "%.1f", food.sugar * (Double(quantity) ?? 100) / food.servingSizeGrams),
                                unit: "г",
                                icon: "cube.fill",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Meal type selector
                    VStack(spacing: 10) {
                        Text(isEnglishLanguage ? "Add to Meal" : "Хоол нэмэх")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker(isEnglishLanguage ? "Meal Type" : "Хоолны төрөл", selection: $selectedMealType) {
                            ForEach(MealType.allCases) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    // Add to log button
                    Button(action: {
                        Task {
                            await addToMealLog()
                            showingAddedAlert = true
                            
                            // Dismiss after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }) {
                        Text(isEnglishLanguage ? "Add to Meal Log" : "Бүртгэлд нэмэх")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentApp)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .padding(.vertical)
            }
            .navigationTitle(isEnglishLanguage ? "Food Details" : "Хоолны мэдээлэл")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglishLanguage ? "Done" : "Дуусгах") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showingAddedAlert {
                    VStack {
                        Text(isEnglishLanguage ? "Added to Meal Log" : "Бүртгэлд нэмэгдлээ")
                            .font(.headline)
                            .padding()
                            .background(Color.green.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: showingAddedAlert)
                    .zIndex(100)
                }
            }
            .sheet(isPresented: $showBarcodeSheet) {
                if let barcodeImage = barcodeImage {
                    VStack(spacing: 20) {
                        Text(isEnglishLanguage ? "Barcode" : "Баркод")
                            .font(.headline)
                        
                        Text(food.barcode ?? "")
                            .font(.title3)
                            .monospaced()
                        
                        Image(uiImage: barcodeImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .padding()
                        
                        Button(isEnglishLanguage ? "Done" : "Дуусгах") {
                            showBarcodeSheet = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                    .presentationDetents([.medium])
                }
            }
            .task {
                await loadFoodImage()
            }
        }
    }
    
    private func loadFoodImage() async {
        if let imageURL = food.imageURL {
            if let imageData = await imageStorageService.getImage(with: imageURL),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    self.foodImage = image
                }
            }
        }
    }
    
    private func generateBarcodeImage() {
        guard let barcode = food.barcode else { return }
        
        // Generate barcode image from string
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
    
    /// Category color
    private func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
        case .meat: return .red
        case .dairy: return .blue
        case .grains: return .brown
        case .fruits: return .orange
        case .vegetables: return .green
        case .nuts: return .yellow
        case .beverages: return .cyan
        case .snacks: return .purple
        case .custom: return .accentApp
        }
    }
}

// MARK: - Nutrition Row
struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .fontWeight(.semibold)
        }
    }
}

struct AsyncFoodImageView: View {
    let imageURL: String?
    let category: FoodCategory
    let size: CGFloat
    
    @State private var image: UIImage?
    
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
                    .font(.system(size: size * 0.5))
                    .foregroundColor(categoryColor(category))
                    .frame(width: size, height: size)
                    .background(categoryColor(category).opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .task {
            if let imageURL = imageURL {
                if let imageData = await ServiceContainer.shared.imageStorageService.getImage(with: imageURL),
                   let loadedImage = UIImage(data: imageData) {
                    image = loadedImage
                }
            }
        }
    }
    
    private func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
        case .meat: return .red
        case .dairy: return .blue
        case .grains: return .brown
        case .fruits: return .orange
        case .vegetables: return .green
        case .nuts: return .yellow
        case .beverages: return .cyan
        case .snacks: return .purple
        case .custom: return .accentApp
        }
    }
}

#Preview {
    NutritionDatabaseView()
} 
