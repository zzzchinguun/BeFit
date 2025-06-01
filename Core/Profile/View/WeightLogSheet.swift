import SwiftUI

struct WeightLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WeightLogViewModel
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showSuccess = false
    @State private var showError = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header image
                ZStack {
                    Circle()
                        .fill(Color.primaryApp.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.primaryApp)
                }
                .padding(.top)
                
                Text(languageManager.isEnglishLanguage ? "Log Today's Weight" : "Өнөөдрийн жингээ бүртгэх")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Weight slider
                VStack(spacing: 10) {
                    Text(languageManager.isEnglishLanguage ? "Weight" : "Жин")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(viewModel.newWeight, specifier: "%.1f") кг")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryApp)
                    
                    Slider(value: $viewModel.newWeight, in: 30...200, step: 0.1)
                        .accentColor(Color.primaryApp)
                        .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color(.systemGray6) : Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                
                // Optional note
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.isEnglishLanguage ? "Note (Optional)" : "Тэмдэглэл (Заавал биш)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField(languageManager.isEnglishLanguage ? "Note about today's weight" : "Өнөөдрийн жингийн талаар тэмдэглэл", text: $viewModel.weightNote)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Error message if present
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Save button
                Button {
                    viewModel.logWeight(weight: viewModel.newWeight, note: viewModel.weightNote.isEmpty ? nil : viewModel.weightNote) { success in
                        if success {
                            showSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        } else if viewModel.errorMessage != nil {
                            showError = true
                        }
                    }
                } label: {
                    HStack {
                        Text(languageManager.isEnglishLanguage ? "Save" : "Хадгалах")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryApp)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoggingWeight)
                .overlay {
                    if viewModel.isLoggingWeight {
                        ProgressView()
                            .tint(.black)
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.isEnglishLanguage ? "Close" : "Хаах") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccess {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .symbolEffect(.bounce, options: .repeat(1))
                            
                            Text(languageManager.isEnglishLanguage ? "Saved!" : "Хадгалагдлаа!")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                }
                
                if showError {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                                .symbolEffect(.pulse, options: .repeat(1))
                            
                            Text(languageManager.isEnglishLanguage ? "Error occurred!" : "Алдаа гарлаа!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button {
                                showError = false
                            } label: {
                                Text(languageManager.isEnglishLanguage ? "Try Again" : "Дахин оролдох")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(30)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                }
            }
            .onAppear {
                viewModel.resetForm()
            }
        }
    }
}

#Preview {
    WeightLogSheet(viewModel: WeightLogViewModel())
}