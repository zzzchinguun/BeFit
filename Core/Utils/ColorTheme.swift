//
//  ColorTheme.swift
//  BeFit
//
//  Created by AI Assistant on 5/8/25.
//

import SwiftUI

// App color theme following the 60-30-10 color rule
extension Color {
    // Primary - 60% of UI
    static let primaryApp = Color(hex: "39FF14") // Neon green (was blue)
    
    // Secondary - 30% of UI
    static let secondaryApp = Color(hex: "2E3A59") // Dark blue/gray
    
    // Accent - 10% of UI (for call to action, important info)
    static let accentApp = Color(hex: "FF5C5C") // Accent red
    
    // Background and text colors
    static let neutralBackground = Color(hex: "F6F8FA") // Light background
    static let neutralBackgroundDark = Color(hex: "000000") // Pure black background (was dark gray)
    static let neutralText = Color(hex: "7E8CA0") // Text for captions, secondary info
    
    // Success, warning, info colors
    static let successApp = Color(hex: "2ECB7F") // Green for success
    static let warningApp = Color(hex: "FFA14A") // Orange for warnings
    static let infoApp = Color(hex: "55C4F5") // Light blue for info
    
    // Helper method to create colors from hex strings
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Extension to provide system-aware color variations
extension Color {
    // For backgrounds that should adapt to light/dark mode
    static func adaptiveBackground(_ isDarkMode: Bool) -> Color {
        return isDarkMode ? Color.neutralBackgroundDark : Color.neutralBackground
    }
    
    // For cards that should adapt to light/dark mode
    static func adaptiveCard(_ isDarkMode: Bool) -> Color {
        return isDarkMode ? Color.black.opacity(0.7) : Color.white
    }
    
    // For surfaces that should adapt to light/dark mode
    static func adaptiveSurface(_ isDarkMode: Bool) -> Color {
        return isDarkMode ? Color.black : Color.white.opacity(0.95)
    }
} 