import SwiftUI

struct WeightLogButton: View {
    @State private var glowAmount = 0.5
    @State private var gradientRotation = 0.0
    @State private var bounce = false
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .offset(y: bounce ? -2 : 0)
                    .scaleEffect(bounce ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bounce)
                
                Text(isEnglishLanguage ? "Log Today's Weight" : "Өнөөдрийн жингээ бүртгэх")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Color.primaryApp.opacity(0.1)
                    
                    // Glowing effect
                    Circle()
                        .fill(Color.primaryApp)
                        .blur(radius: 20)
                        .opacity(glowAmount)
                        .scaleEffect(1.2)
                }
            )
            .overlay(
                Capsule()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.primaryApp.opacity(0.8),
                                Color.blue.opacity(0.6),
                                Color.primaryApp.opacity(0.4),
                                Color.primaryApp.opacity(0.8)
                            ]),
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 2
                    )
            )
            .foregroundColor(Color.primaryApp)
            .clipShape(Capsule())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAmount = 0.2
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bounce = true
            }
        }
    }
}

#Preview {
    WeightLogButton(action: {})
        .padding()
}
