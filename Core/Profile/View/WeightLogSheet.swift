import SwiftUI

struct WeightLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WeightLogViewModel
    @State private var showSuccess = false
    @State private var showError = false
    
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
                
                Text("Өнөөдрийн жингээ бүртгэх")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Weight slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Жин")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", viewModel.newWeight)) кг")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.primaryApp)
                    }
                    
                    Slider(value: $viewModel.newWeight, in: 30...200, step: 0.1)
                        .tint(Color.primaryApp)
                        .padding(.vertical, 8)
                    
                    HStack {
                        Text("30 кг")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("200 кг")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Тэмдэглэл (заавал биш)")
                        .font(.headline)
                    
                    TextField("Өнөөдрийн жингийн талаар тэмдэглэл", text: $viewModel.weightNote)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
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
                        Text("Хадгалах")
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
                    Button("Хаах") {
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
                            
                            Text("Хадгалагдлаа!")
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
                            
                            Text("Алдаа гарлаа!")
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
                                Text("Дахин оролдох")
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