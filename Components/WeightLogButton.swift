import SwiftUI

struct WeightLogButton: View {
    @State private var glowAmount = 0.5
    @State private var gradientRotation = 0.0
    @State private var bounce = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "scalemass.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .offset(y: bounce ? -2 : 0)
                    .scaleEffect(bounce ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bounce)
                
                Text("Өнөөдрийн жингээ бүртгэх")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Color.green.opacity(0.1)
                    
                    // Glowing effect
                    Circle()
                        .fill(Color.green)
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
                                .green.opacity(0.8),
                                .blue.opacity(0.6),
                                .green.opacity(0.4),
                                .green.opacity(0.8)
                            ]),
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 2
                    )
            )
            .foregroundColor(.green)
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