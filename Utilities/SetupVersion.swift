import Foundation
import FirebaseFirestore

enum VersionSetup {
    static func setupInitialVersion() async {
        print("Starting version setup...")
        do {
            let db = Firestore.firestore()
            print("Firestore instance created")
            
            // First check if version document exists
            let docRef = db.collection("appVersion").document("version")
            let document = try await docRef.getDocument()
            
            if document.exists {
                print("Version document already exists")
            } else {
                print("Creating new version document")
                try await AppVersion.update(
                    currentVersion: "1.0.0",
                    requiredVersion: "1.0.0"
                )
                print("Successfully set up initial version data")
            }
        } catch {
            print("Error setting up version data: \(error)")
        }
    }
} 