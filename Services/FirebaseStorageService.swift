import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

class FirebaseStorageService: ImageStorageServiceProtocol {
    private let storage = Storage.storage()
    private let localBackup = ImageStorageService.shared
    
    func saveImage(_ imageData: Data) -> String {
        let imageId = UUID().uuidString
        
        // Always save to local storage as backup immediately
        let localId = localBackup.saveImage(imageData)
        
        // Check if user is authenticated before uploading to Firebase
        guard Auth.auth().currentUser != nil else {
            print("Warning: User not authenticated, saving to local storage only")
            return imageId
        }
        
        // Upload to Firebase asynchronously in background
        Task {
            await uploadImageToFirebase(imageData: imageData, imageId: imageId)
        }
        
        return imageId
    }
    
    private func uploadImageToFirebase(imageData: Data, imageId: String) async {
        // Double-check authentication
        guard Auth.auth().currentUser != nil else {
            print("Error: Cannot upload to Firebase - user not authenticated")
            return
        }
        
        let storageRef = storage.reference().child("foodImages/\(imageId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await storageRef.putData(imageData, metadata: metadata)
            print("Image uploaded successfully to Firebase: \(imageId)")
        } catch let error as NSError {
            print("Error uploading image to Firebase: \(error.localizedDescription)")
            
            // Check if it's an authentication error
            if error.domain.contains("StorageError") && error.code == 401 {
                print("Authentication error - user needs to sign in again")
                return
            }
            
            // Retry once after 3 seconds for network errors
            if error.domain.contains("NSURLError") || error.localizedDescription.contains("network") {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                do {
                    _ = try await storageRef.putData(imageData, metadata: metadata)
                    print("Image upload retry successful: \(imageId)")
                } catch {
                    print("Image upload retry failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getImage(with id: String) async -> Data? {
        // Return nil immediately for empty or invalid IDs
        guard !id.isEmpty else { 
            return nil 
        }
        
        // Check if user is authenticated for Firebase access
        guard Auth.auth().currentUser != nil else {
            // Only try local storage if user not authenticated
            return await localBackup.getImage(with: id)
        }
        
        let storageRef = storage.reference().child("foodImages/\(id).jpg")
        
        do {
            // Try to get from Firebase first
            let downloadURL = try await storageRef.downloadURL()
            let (data, _) = try await URLSession.shared.data(from: downloadURL)
            return data
        } catch {
            // Check if it's a "not found" error - these are common and expected
            let nsError = error as NSError
            let isNotFoundError = nsError.domain.contains("StorageError") && nsError.code == 404
            let isAuthError = nsError.domain.contains("StorageError") && nsError.code == 401
            
            if !isNotFoundError && !isAuthError {
                // Only log non-404 and non-auth errors
                print("Error downloading image from Firebase: \(error.localizedDescription)")
            }
            
            // Try to get from local storage as fallback
            if let localData = await localBackup.getImage(with: id) {
                return localData
            }
            
            // Only log missing image once to reduce spam
            if !isNotFoundError && !isAuthError {
                print("Image not found in local backup either: \(id)")
            }
            return nil
        }
    }
    
    func deleteImage(with id: String) async {
        // Check if user is authenticated for Firebase access
        guard Auth.auth().currentUser != nil else {
            // Only delete from local storage if user not authenticated
            await localBackup.deleteImage(with: id)
            return
        }
        
        let storageRef = storage.reference().child("foodImages/\(id).jpg")
        
        // Delete from Firebase
        do {
            try await storageRef.delete()
            print("Image deleted from Firebase: \(id)")
        } catch {
            print("Error deleting image from Firebase: \(error.localizedDescription)")
        }
        
        // Also delete from local storage
        await localBackup.deleteImage(with: id)
    }
} 