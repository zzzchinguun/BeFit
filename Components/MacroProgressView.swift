//
//  MacroProgressView.swift
//  BeFit
//
//  Created by AI Assistant on 3/31/25.
//

import SwiftUI

struct MacroProgressView: View {
    var title: String
    var current: Int
    var target: Int
    var color: Color
    
    private var percentage: CGFloat {
        if target == 0 { return 0 }
        return min(CGFloat(current) / CGFloat(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(current)/\(target)g")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack {
        MacroProgressView(title: "Protein", current: 80, target: 140, color: .blue)
        MacroProgressView(title: "Carbs", current: 120, target: 240, color: .green)
        MacroProgressView(title: "Fat", current: 40, target: 60, color: .red)
    }
    .padding()
} 