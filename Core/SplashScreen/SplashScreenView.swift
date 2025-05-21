//
//  SplashScreenView.swift
//  BeFit
//
//  Created by Claude on 3/15/25.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var size = 0.7
    @State private var opacity = 0.0
    @State private var rotation = 0.0
    @State private var bounce = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Darker blue background
            Color(red: 0.17, green: 0.2, blue: 0.31)
                .ignoresSafeArea()
            
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.blue.opacity(0.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(pulse ? 1.2 : 0.9)
            .opacity(pulse ? 0.6 : 0.4)
            .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 25) {
                    // Animated dumbbell
                    ZStack {
                        // Background glow effect
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(bounce ? 1.4 : 1.0)
                            .opacity(bounce ? 0.6 : 0.2)
                            .blur(radius: 3)
                        
                        // Secondary glow
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulse ? 1.2 : 1.0)
                            .blur(radius: 2)
                        
                        // Main dumbbell icon
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.8), radius: 10, x: 0, y: 0)
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(size)
                            .opacity(opacity)
                    }
                    
                    // App name in Mongolian
                    Text("BeFit")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.8), radius: 10, x: 0, y: 0)
                        .opacity(opacity)
                    
                    // Tagline in Mongolian
                    Text("Таны фитнесс туслах")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeIn(duration: 1.0)) {
                self.size = 1.0
                self.opacity = 1.0
            }
            
            // Rotation animation with more movement
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                self.rotation = 25.0
            }
            
            // Bounce animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                self.bounce = true
            }
            
            // Pulse animation for the glow
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                self.pulse = true
            }
            
            // Extend animation time before dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.8)) {
                    self.isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
        .environmentObject(AuthViewModel())
} 
