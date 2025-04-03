import SwiftUI

struct StatusSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let isSuccess: Bool
    let title: String
    let message: String
    var action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isPresented = false
                                }
                            }
                        
                        StatusSheet(
                            isSuccess: isSuccess,
                            title: title,
                            message: message,
                            action: action,
                            isPresented: $isPresented
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
    }
}

// View extension for easier usage
extension View {
    func statusSheet(
        isPresented: Binding<Bool>,
        isSuccess: Bool,
        title: String,
        message: String,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(StatusSheetModifier(
            isPresented: isPresented,
            isSuccess: isSuccess,
            title: title,
            message: message,
            action: action
        ))
    }
}