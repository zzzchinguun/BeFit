import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var isEnglishLanguage: Bool {
        didSet {
            UserDefaults.standard.set(isEnglishLanguage, forKey: "isEnglishLanguage")
        }
    }
    
    @Published var isExerciseEnglishLanguage: Bool {
        didSet {
            UserDefaults.standard.set(isExerciseEnglishLanguage, forKey: "isExerciseEnglishLanguage")
        }
    }
    
    private init() {
        // Initialize language setting if it hasn't been set yet
        if !UserDefaults.standard.bool(forKey: "languageInitialized") {
            // Default to false (Mongolian) if not set
            UserDefaults.standard.set(false, forKey: "isEnglishLanguage")
            UserDefaults.standard.set(false, forKey: "isExerciseEnglishLanguage")
            UserDefaults.standard.set(true, forKey: "languageInitialized")
        }
        
        // Load current values
        self.isEnglishLanguage = UserDefaults.standard.bool(forKey: "isEnglishLanguage")
        self.isExerciseEnglishLanguage = UserDefaults.standard.bool(forKey: "isExerciseEnglishLanguage")
    }
    
    func toggleLanguage() {
        isEnglishLanguage.toggle()
    }
    
    func toggleExerciseLanguage() {
        isExerciseEnglishLanguage.toggle()
    }
} 