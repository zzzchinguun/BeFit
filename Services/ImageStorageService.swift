//
//  ImageStorageService.swift
//  BeFit
//
//  Created by AI Assistant on 5/11/25.
//

import Foundation
import UIKit
import Combine

protocol ImageStorageServiceProtocol {
    func saveImage(_ imageData: Data) -> String
    func getImage(with id: String) async -> Data?
    func deleteImage(with id: String) async
}

class ImageStorageService: ImageStorageServiceProtocol {
    // File manager for disk operations
    private let fileManager = FileManager.default
    
    // Directory for storing images
    private var imagesDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsDirectory.appendingPathComponent("FoodImages")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
        
        return imagesDirectory
    }
    
    // MARK: - Public Methods
    
    /// Save image to disk and return its identifier
    func saveImage(_ imageData: Data) -> String {
        let imageId = UUID().uuidString
        let imageURL = imagesDirectory.appendingPathComponent(imageId)
        
        do {
            try imageData.write(to: imageURL)
            return imageId
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return ""
        }
    }
    
    /// Get image data from disk by ID
    func getImage(with id: String) async -> Data? {
        let imageURL = imagesDirectory.appendingPathComponent(id)
        return try? Data(contentsOf: imageURL)
    }
    
    /// Delete image from disk
    func deleteImage(with id: String) async {
        let imageURL = imagesDirectory.appendingPathComponent(id)
        try? fileManager.removeItem(at: imageURL)
    }
}

// Factory extension for creating instances
extension ImageStorageService {
    static let shared = ImageStorageService()
} 