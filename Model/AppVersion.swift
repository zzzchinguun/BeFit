import Foundation
import FirebaseFirestore

struct AppVersion: Codable {
    let currentVersion: String
    let requiredVersion: String
    let appStoreURL: String
    
    static let collectionName = "appVersion"
    
    static func fetch() async throws -> AppVersion {
        let db = Firestore.firestore()
        let document = try await db.collection(collectionName).document("version").getDocument()
        return try document.data(as: AppVersion.self)
    }
    
    static func update(currentVersion: String, requiredVersion: String) async throws {
        let db = Firestore.firestore()
        let version = AppVersion(
            currentVersion: currentVersion,
            requiredVersion: requiredVersion,
            appStoreURL: "https://apps.apple.com/mn/app/befit-fitness-helper/id6746723531"
        )
        try await db.collection(collectionName).document("version").setData(from: version)
    }
} 