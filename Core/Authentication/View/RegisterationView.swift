//
//  RegisterationView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI

struct RegisterationView: View {
    @State private var email: String = ""
    @State private var lastName: String = ""
    @State private var firstName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showStatusSheet = false
    @State private var registrationError: Error?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum Field {
        case email, lastName, firstName, password, confirmPassword
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                // Logo and Title
                VStack(spacing: 15) {
                    Image(systemName: "dumbbell.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.blue)
                        .symbolEffect(.bounce, value: email)
                    
                    Text("Бүртгүүлэх")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Эрүүл амьдралыг эхлүүлэх")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Email Field
                    FormField(title: "И-мейл",
                             placeholder: "И-мэйл хаягаа оруулах",
                             text: $email,
                             icon: "envelope.fill")
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                    
                    // Last Name Field
                    FormField(title: "Овог",
                             placeholder: "Таны овог",
                             text: $lastName,
                             icon: "person.fill")
                        .focused($focusedField, equals: .lastName)
                        .submitLabel(.next)
                    
                    // First Name Field
                    FormField(title: "Нэр",
                             placeholder: "Таны нэр",
                             text: $firstName,
                             icon: "person.fill")
                        .focused($focusedField, equals: .firstName)
                        .submitLabel(.next)
                    
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
                                } else {
                                    SecureField("Нууц үг", text: $password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Нууц үг давтах")
                            .foregroundColor(.gray)
                            .font(.callout)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                            Group {
                                if showConfirmPassword {
                                    TextField("Дахин оруулна уу", text: $confirmPassword)
                                } else {
                                    SecureField("Дахин оруулна уу", text: $confirmPassword)
                                }
                            }
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            
                            if !confirmPassword.isEmpty {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password == confirmPassword ? .green : .red)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Sign Up Button
                Button {
                    Task {
                        do {
                            try await viewModel.createUser(
                                withEmail: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName
                            )
                            showStatusSheet = true
                        } catch {
                            registrationError = error
                            showStatusSheet = true
                        }
                    }
                } label: {
                    HStack {
                        Text("Бүртгүүлэх")
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
                
                // Sign In Link
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Text("Бүртгэлтэй юу?")
                            .foregroundColor(.gray)
                        Text("Нэвтрэх")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .font(.callout)
                }
                .padding(.bottom)
            }
            .padding(.bottom, keyboardHeight) // Add padding when keyboard is shown
        }
        .statusSheet(
            isPresented: $showStatusSheet,
            isSuccess: registrationError == nil,
            title: registrationError == nil ? "Welcome!" : "Registration Failed",
            message: registrationError == nil ?
                "Your account has been successfully created. Start your fitness journey now!" :
                registrationError?.localizedDescription ?? "An unknown error occurred",
            action: {
                if registrationError == nil {
                    dismiss()
                }
            }
        )
        .onChange(of: focusedField) { oldValue, newValue in
            withAnimation {
                if newValue == nil {
                    keyboardHeight = 0
                } else {
                    keyboardHeight = 280 // Approximate keyboard height
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .lastName
            case .lastName:
                focusedField = .firstName
            case .firstName:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                focusedField = nil
            case .none:
                break
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// Form Field Component
struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
                .font(.callout)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                TextField(placeholder, text: $text)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

extension RegisterationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty &&
               email.contains("@") &&
               !password.isEmpty &&
               password.count > 5 &&
               !confirmPassword.isEmpty &&
               confirmPassword == password &&
               !firstName.isEmpty &&
               !lastName.isEmpty
    }
}

#Preview {
    RegisterationView()
        .environmentObject(AuthViewModel())
}
