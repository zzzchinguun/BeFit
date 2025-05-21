import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageService: ImageStorageServiceProtocol {
    private let storage = Storage.storage()
    private let localBackup = ImageStorageService.shared
    
    func saveImage(_ imageData: Data) -> String {
        let imageId = UUID().uuidString
        let storageRef = storage.reference().child("foodImages/\(imageId).jpg")
        
        // Always save to local storage as backup
        let localId = localBackup.saveImage(imageData)
        
        // Upload the image data to Firebase
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Start the upload task
        let uploadTask = storageRef.putData(imageData, metadata: metadata)
        
        // Use a semaphore to make this synchronous
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadTask.observe(.success) { _ in
            print("Image uploaded successfully to Firebase: \(imageId)")
            semaphore.signal()
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Error uploading image to Firebase: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        
        // Wait for completion with timeout (5 seconds)
        let waitResult = semaphore.wait(timeout: .now() + 5)
        if waitResult == .timedOut {
            print("Warning: Firebase image upload timed out. Will retry later.")
            
            // Queue the upload for retry in background
            DispatchQueue.global(qos: .background).async {
                let retryTask = storageRef.putData(imageData, metadata: metadata)
                print("Started background retry upload for image: \(imageId)")
            }
        }
        
        return imageId
    }
    
    func getImage(with id: String) async -> Data? {
        let storageRef = storage.reference().child("foodImages/\(id).jpg")
        
        do {
            // Try to get from Firebase first
            let downloadURL = try await storageRef.downloadURL()
            let (data, _) = try await URLSession.shared.data(from: downloadURL)
            print("Successfully downloaded image from Firebase: \(id)")
            return data
        } catch {
            print("Error downloading image from Firebase: \(error.localizedDescription)")
            
            // Try to get from local storage as fallback
            if let localData = await localBackup.getImage(with: id) {
                print("Successfully retrieved image from local backup: \(id)")
                return localData
            }
            
            print("Image not found in local backup either: \(id)")
            return nil
        }
    }
    
    func deleteImage(with id: String) async {
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