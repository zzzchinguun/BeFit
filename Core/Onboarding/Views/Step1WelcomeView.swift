import SwiftUI

struct Step1WelcomeView: View {
    @Binding var user: User
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Welcome Animation
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(showAnimation ? 1.2 : 0.8)
                    .opacity(showAnimation ? 0.5 : 1)
                
                Image(systemName: "figure.run")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .foregroundColor(.blue)
                    .offset(x: showAnimation ? 20 : -20)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    showAnimation = true
                }
            }
            
            VStack(spacing: 15) {
                Text("Таны хувийн фитнесс аялал")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Бид таны зорилго болон одоогийн фитнесс түвшинд тохируулан хувийн төлөвлөгөө боловсруулахад тань тусална")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Feature List
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Ахиц дэвшлээ хянах", description: "Фитнесс аяллаа хянаарай")
                FeatureRow(icon: "fork.knife", title: "Хооллолтын зөвлөмж", description: "Хувийн хоолны төлөвлөгөө гаргах")
                FeatureRow(icon: "figure.strengthtraining.traditional", title: "Дасгалын төлөвлөгөө", description: "Танд тохирсон дасгалын хөтөлбөр")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
            }
        }
    }
}
