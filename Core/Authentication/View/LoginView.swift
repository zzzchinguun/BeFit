//
//  LoginView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showStatusSheet = false
    @State private var loginError: Error?
    @State private var errorMessage: String = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @State private var isAnimationReady = false
    @State private var titleVisible = true
    @EnvironmentObject var viewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Helper function to get user-friendly error message
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("no user record") || errorMessage.contains("wrong password") {
            return "И-мэйл эсвэл нууц үг буруу байна."
        } else if errorMessage.contains("network error") {
            return "Интернэт холболтоо шалгана уу."
        } else if errorMessage.contains("too many attempts") {
            return "Хэт олон удаа оролдлоо. Түр хүлээнэ үү."
        } else if errorMessage.contains("invalid email") {
            return "И-мэйл хаяг буруу байна."
        } else if errorMessage.contains("operation") {
            return "И-мэйл эсвэл нууц үг буруу байна."
        }
        
        return error.localizedDescription
    }
    
    // Update title visibility when focus changes
    private func updateTitleVisibility() {
        // Use transaction with faster animation for better performance
        var transaction = Transaction()
        transaction.animation = .easeOut(duration: 0.15)
        transaction.disablesAnimations = !isAnimationReady
        
        withTransaction(transaction) {
            titleVisible = !isEmailFocused && !isPasswordFocused
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                (isDarkMode ? Color.black : Color(.systemBackground))
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and Welcome Text
                    VStack(spacing: 15) {
                        if !titleVisible{
                            Spacer().frame(height: 40)
                        }
                        Image(systemName: "dumbbell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: titleVisible ? 80 : 110, height: titleVisible ? 80 : 110)
                            .foregroundStyle(.blue)
                        
                        // Use conditional rendering with a fixed height placeholder to prevent layout shifts
                        if titleVisible {
                            VStack(spacing: 5) {
                                Text("Тавтай морино уу!")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Sign in to continue your fitness journey")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Form Fields - extract to subviews for better performance
                    loginForm
                }
            }
            .onChange(of: isEmailFocused) { updateTitleVisibility() }
            .onChange(of: isPasswordFocused) { updateTitleVisibility() }
            .onAppear {
                // Pre-load and cache layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimationReady = true
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    // Extract form to a separate view for better performance
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("И-мейл")
                    .foregroundColor(.gray)
                    .font(.callout)
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    TextField("И-мэйл", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($isEmailFocused)
                        // Disable auto-correction and prediction for better performance
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Нууц үг")
                    .foregroundColor(.gray)
                    .font(.callout)
                
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Group {
                        if showPassword {
                            TextField("Нууц үг", text: $password)
                                .focused($isPasswordFocused)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Нууц үг", text: $password)
                                .focused($isPasswordFocused)
                        }
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Error message
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, -10)
            }
            
            NavigationLink {
                ForgotPasswordView()
            } label: {
                Text("Нууц үг мартсан уу?")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
            }
            
            // Sign In Button
            Button {
                Task {
                    do {
                        errorMessage = "" // Clear previous errors
                        print("Attempting login with email: \(email)")
                        try await viewModel.signIn(withEmail: email, password: password)
                    } catch {
                        loginError = error
                        errorMessage = getUserFriendlyErrorMessage(from: error)
                        showStatusSheet = true
                        print("Login failed with error: \(errorMessage)")
                    }
                }
            } label: {
                HStack {
                    Text("Нэвтрэх")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(formIsValid ? Color.blue : Color.blue.opacity(0.3))
                )
            }
            .disabled(!formIsValid)
            
            Spacer()
            
            // Sign Up Link
            NavigationLink {
                RegisterationView()
                    .navigationBarBackButtonHidden()
            } label: {
                HStack(spacing: 3) {
                    Text("Бүртгэл үүсгээгүй юу?")
                        .foregroundColor(.gray)
                    Text("Бүртгүүлэх")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .font(.callout)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal)
    }
}

extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty &&
               email.contains("@") &&
               email.count > 5 &&
               !password.isEmpty &&
               password.count > 5
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
