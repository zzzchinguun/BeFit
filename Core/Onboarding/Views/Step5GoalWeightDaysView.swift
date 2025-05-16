import SwiftUI

struct Step5GoalWeightDaysView: View {
    @Binding var user: User
    @State var showSheet: Bool = false
    @State private var showingSaveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Таны тооцоолсон үр дүн")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Button {
                    showSheet.toggle()
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Булчингийн дээд потенциалыг шалгах")
                    }
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                let tdeeResult = calculateTDEE(user: user)
                ResultCard(result: tdeeResult.resultString) {
                    saveToPhotos(text: tdeeResult.resultString)
                }
                .onAppear {
                    user.tdee = tdeeResult.tdee
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text("Таны натурал булчингийн дээд потенциал")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                if let height = user.height {
                    ScrollView {
                        Text(calculateMaximumMuscularPotential(height: height))
                            .font(.body)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                } else {
                    Text("Өндрөө оруулна уу")
                        .font(.body)
                        .padding()
                }

                Button("Хаах") {
                    showSheet.toggle()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .presentationDetents([.fraction(0.7)])
        }
        .alert("Амжилттай", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Зураг амжилттай хадгалагдлаа")
        }
    }
    
    private func saveToPhotos(text: String) {
        let renderer = ImageRenderer(content:
            VStack(spacing: 20) {
                Text("BeFit - Таны Фитнесс Зорилго")
                    .font(.title2)
                    .bold()
                Text(text)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(Color(.systemBackground))
        )
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            showingSaveSuccess = true
        }
    }
}

struct ResultCard: View {
    let result: String
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(result)
                .font(.system(.body, design: .rounded))
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            
            Button(action: onSave) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Зурган файлаар хадгалах")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    Step5GoalWeightDaysView(user: $previewUser)
//        .previewDevice("iPhone 14")
}
