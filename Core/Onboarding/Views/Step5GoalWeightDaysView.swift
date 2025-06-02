import SwiftUI
import Photos
import Charts

struct Step5GoalWeightDaysView: View {
    @Binding var user: User
    @State var showSheet: Bool = false
    @State private var showingSaveSuccess = false
    @State private var saveErrorMessage: String? = nil
    @State private var showingSaveError = false
    @State private var photoDelegate: PhotoLibraryDelegate? // Store the delegate as state
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Beautiful Header with animated title
                VStack(spacing: 15) {
                    Text("🎉")
                        .font(.system(size: 50))
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                    
                    Text("Таны тооцоолсон үр дүн")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Progress Chart Section
                if let currentWeight = user.weight,
                   let goalWeight = user.goalWeight,
                   let days = user.daysToComplete {
                    
                    WeightProgressChart(
                        currentWeight: currentWeight,
                        goalWeight: goalWeight,
                        days: days
                    )
                    .padding()
                }
                
                // Muscle Potential Button
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
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                
                // Static Results Section (typing moved to Step6)
                if let tdeeResult = FitnessCalculations.calculateTDEE(user: user) {
                    VStack(alignment: .leading, spacing: 15) {
                        ScrollView {
                            Text(tdeeResult.resultString)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                        
                        Button(action: {
                            saveToPhotos(text: tdeeResult.resultString)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Зураг болгон хадгалах")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                    .onAppear {
                        user.tdee = tdeeResult.tdee
                        user.goalCalories = tdeeResult.goalCalories
                    }
                } else {
                    Text("Тооцоолол хийхэд алдаа гарлаа")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Macro Distribution Chart (if available)
                if let macros = user.macros {
                    MacroDistributionChart(macros: macros)
                        .padding()
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
        .alert("Алдаа гарлаа", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Зураг хадгалахад алдаа гарлаа")
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
            .frame(width: 350) // Fixed width instead of UIScreen
            .background(Color(.systemBackground))
        )
        
        if let uiImage = renderer.uiImage {
            // Create a new delegate instance and store it in state
            photoDelegate = PhotoLibraryDelegate(
                onSuccess: {
                    self.showingSaveSuccess = true
                },
                onFailure: { error in
                    self.saveErrorMessage = error.localizedDescription
                    self.showingSaveError = true
                }
            )
            
            UIImageWriteToSavedPhotosAlbum(uiImage, photoDelegate, #selector(PhotoLibraryDelegate.image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            saveErrorMessage = "Зураг үүсгэхэд алдаа гарлаа"
            showingSaveError = true
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

// Weight Progress Chart Component
struct WeightProgressChart: View {
    let currentWeight: Double
    let goalWeight: Double
    let days: Int
    
    @State private var animateProgress = false
    
    var weightDifference: Double {
        abs(goalWeight - currentWeight)
    }
    
    var isGaining: Bool {
        goalWeight > currentWeight
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Таны зорилго")
                .font(.headline)
                .foregroundColor(.gray)
            
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: animateProgress ? 0.75 : 0) // 75% as example progress
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [isGaining ? .green : .blue, isGaining ? .green.opacity(0.6) : .blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 2.0), value: animateProgress)
                
                // Center Content
                VStack(spacing: 8) {
                    Text("\(String(format: "%.1f", weightDifference))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(isGaining ? .green : .blue)
                    
                    Text("кг")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(isGaining ? "нэмэх" : "хасах")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Stats
            HStack(spacing: 30) {
                VStack {
                    Text("Одоо")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", currentWeight)) кг")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Image(systemName: isGaining ? "arrow.right" : "arrow.right")
                    .foregroundColor(isGaining ? .green : .blue)
                
                VStack {
                    Text("Зорилго")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", goalWeight)) кг")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isGaining ? .green : .blue)
                }
            }
            
            // Timeline
            VStack(spacing: 5) {
                Text("\(days) өдөр")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("(\(days/7) долоо хоног)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                animateProgress = true
            }
        }
    }
}

// Macro Distribution Chart Component
struct MacroDistributionChart: View {
    let macros: Macros
    
    @State private var animateSlices = false
    
    var totalGrams: Int {
        macros.protein + macros.carbs + macros.fat
    }
    
    var proteinPercentage: Double {
        Double(macros.protein) / Double(totalGrams)
    }
    
    var carbsPercentage: Double {
        Double(macros.carbs) / Double(totalGrams)
    }
    
    var fatPercentage: Double {
        Double(macros.fat) / Double(totalGrams)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Macro төлөвлөгөө")
                .font(.headline)
                .foregroundColor(.gray)
            
            ZStack {
                // Protein slice
                Circle()
                    .trim(from: 0, to: animateSlices ? proteinPercentage : 0)
                    .stroke(Color.blue, lineWidth: 20)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).delay(0.2), value: animateSlices)
                
                // Carbs slice
                Circle()
                    .trim(from: proteinPercentage, to: animateSlices ? (proteinPercentage + carbsPercentage) : proteinPercentage)
                    .stroke(Color.green, lineWidth: 20)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).delay(0.5), value: animateSlices)
                
                // Fat slice
                Circle()
                    .trim(from: (proteinPercentage + carbsPercentage), to: animateSlices ? 1.0 : (proteinPercentage + carbsPercentage))
                    .stroke(Color.yellow, lineWidth: 20)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).delay(0.8), value: animateSlices)
                
                // Center label
                Text("Macro")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            // Legend
            VStack(spacing: 12) {
                MacroLegendItem(color: .blue, label: "Уураг", amount: macros.protein, unit: "г")
                MacroLegendItem(color: .green, label: "Нүүрс ус", amount: macros.carbs, unit: "г") 
                MacroLegendItem(color: .yellow, label: "Өөх тос", amount: macros.fat, unit: "г")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .onAppear {
            withAnimation {
                animateSlices = true
            }
        }
    }
}

struct MacroLegendItem: View {
    let color: Color
    let label: String
    let amount: Int
    let unit: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(amount)\(unit)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview{
    @Previewable
    @State var previewUser = User.MOCK_USER
    Step5GoalWeightDaysView(user: $previewUser)
//        .previewDevice("iPhone 14")
}
