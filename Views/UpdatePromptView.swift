import SwiftUI

struct UpdatePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isEnglishLanguage") private var isEnglishLanguage = false
    let isRequiredUpdate: Bool
    let appStoreURL: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(isEnglishLanguage ? "Update Available" : "Шинэчлэл бэлэн")
                .font(.title)
                .bold()
            
            Text(isRequiredUpdate ? 
                (isEnglishLanguage ? "A new version is required to continue using the app." : "Аппликейшныг үргэлжлүүлэн ашиглахын тулд шинэчлэл хийх шаардлагатай.") :
                (isEnglishLanguage ? "A new version is available with exciting new features!" : "Шинэ функцүүдтэй шинэ хувилбар бэлэн боллоо!"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if let url = URL(string: appStoreURL) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(isEnglishLanguage ? "Update Now" : "Шинэчлэх")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            if !isRequiredUpdate {
                Button(action: {
                    dismiss()
                }) {
                    Text(isEnglishLanguage ? "Skip" : "Дараа нь")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
} 