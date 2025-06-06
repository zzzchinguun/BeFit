import Foundation
import SwiftUI

class VersionCheckService: ObservableObject {
    @Published var shouldShowUpdatePrompt = false
    @Published var isRequiredUpdate = false
    @Published var appStoreURL: String = ""
    
    private let currentVersion: String
    
    init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.currentVersion = version
        } else {
            self.currentVersion = "1.0.0"
        }
    }
    
    func checkVersion() async {
        do {
            let version = try await AppVersion.fetch()
            await MainActor.run {
                self.appStoreURL = version.appStoreURL
                self.isRequiredUpdate = self.compareVersions(version.requiredVersion, self.currentVersion) > 0
                self.shouldShowUpdatePrompt = self.isRequiredUpdate || self.compareVersions(version.currentVersion, self.currentVersion) > 0
            }
        } catch {
            print("Error checking version: \(error)")
        }
    }
    
    private func compareVersions(_ version1: String, _ version2: String) -> Int {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(v1Components.count, v2Components.count) {
            let v1 = i < v1Components.count ? v1Components[i] : 0
            let v2 = i < v2Components.count ? v2Components[i] : 0
            
            if v1 > v2 { return 1 }
            if v1 < v2 { return -1 }
        }
        
        return 0
    }
} 