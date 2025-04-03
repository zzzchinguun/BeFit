//
//  ForgotPasswordView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/30/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack(spacing: 15) {
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, value: email)
                
                Text("Нууц үг сэргээх")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Та бүртгэлтэй и-мэйл хаягаа оруулна уу")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 50)
            
            // Email Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("И-мэйл")
                    .foregroundColor(.gray)
                    .font(.callout)
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    TextField("И-мэйл хаягаа оруулах", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    if !email.isEmpty {
                        Button(action: { email = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Reset Password Button
            Button {
                resetPassword()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Нууц үг сэргээх")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(email.isEmpty ? Color.blue.opacity(0.3) : Color.blue)
                )
                .padding(.horizontal)
            }
            .disabled(email.isEmpty || isLoading)
            
            // Back to Login Button
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                    Text("Буцах")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .padding(.top)
            }
            
            Spacer()
        }
        .alert(isSuccess ? "Амжилттай" : "Алдаа", isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func resetPassword() {
        isLoading = true
        Task {
            do {
                try await viewModel.resetPassword(withEmail: email)
                alertMessage = "Таны и-мэйл хаяг руу нууц үг сэргээх линк илгээгдлээ."
                isSuccess = true
            } catch {
                alertMessage = error.localizedDescription
                isSuccess = false
            }
            isLoading = false
            showAlert = true
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
