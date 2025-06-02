//
//  AsyncFoodImageView.swift
//  BeFit
//
//  Created by AI Assistant on 5/10/25.
//

import SwiftUI

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