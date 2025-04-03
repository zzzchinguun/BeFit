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
    @EnvironmentObject var viewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Logo and Welcome Text
                VStack(spacing: 15) {
                    Image(systemName: "dumbbell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                        .symbolEffect(.bounce, value: email)
                    
                    Text("Тавтай морино уу!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("И-мейл")
                            .foregroundColor(.gray)
                            .font(.callout)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            TextField("И-мэйл хаягаа оруулах", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
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
                                    TextField("Нууц үгээ оруулах", text: $password)
                                } else {
                                    SecureField("Нууц үгээ оруулах", text: $password)
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
                    
                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Нууц үг мартсан уу?")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal)
                
                // Sign In Button
                Button {
                    Task {
                        do {
                            try await viewModel.signIn(withEmail: email, password: password)
                        } catch {
                            loginError = error
                            showStatusSheet = true
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
                    .padding(.horizontal)
                }
                .disabled(!formIsValid)
                .statusSheet(
                    isPresented: $showStatusSheet,
                    isSuccess: false,
                    title: "Login Failed",
                    message: loginError?.localizedDescription ?? "An unknown error occurred",
                    action: nil
                )
                
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
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
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
