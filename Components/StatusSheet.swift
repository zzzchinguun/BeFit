import SwiftUI

struct StatusSheet: View {
    let isSuccess: Bool
    let title: String
    let message: String
    var action: (() -> Void)?
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Icon with Animation
            Circle()
                .fill(isSuccess ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(isSuccess ? .green : .red)
                        .symbolEffect(.bounce.byLayer, options: .repeating, value: isPresented)
                }
                .transition(.scale.combined(with: .opacity))
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .transition(.move(edge: .top).combined(with: .opacity))
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            
            // Action Button
            Button {
                withAnimation(.spring()) {
                    isPresented = false
                    action?()
                }
            } label: {
                Text(isSuccess ? "Continue" : "Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSuccess ? Color.green : Color.blue)
                    )
                    .padding(.horizontal)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(25)
        .shadow(radius: 10)
        .padding()
    }
}

// Preview Provider
#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        
        StatusSheet(
            isSuccess: true,
            title: "Welcome!",
            message: "Your account has been successfully created. Start your fitness journey now!",
            action: {},
            isPresented: .constant(true)
        )
    }
}