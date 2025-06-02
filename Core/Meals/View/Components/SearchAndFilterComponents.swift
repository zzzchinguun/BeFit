//
//  SearchAndFilterComponents.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import SwiftUI

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