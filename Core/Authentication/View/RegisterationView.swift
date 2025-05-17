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
    @State private var errorMessage: String = ""
    @State private var isShowingPassword = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var showEmailError = false
    @State private var showPasswordError = false
    @State private var showConfirmPasswordError = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    enum Field {
        case email, lastName, firstName, password, confirmPassword
    }
    
    // Helper function to get user-friendly error message
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("email already in use") {
            return "Энэ и-мэйл хаяг бүртгэлтэй байна."
        } else if errorMessage.contains("network error") {
            return "Интернэт холболтоо шалгана уу."
        } else if errorMessage.contains("weak password") {
            return "Нууц үг хангалттай хүчтэй биш байна. 6+ тэмдэгт, тоо, үсэг хольж оруулна уу."
        } else if errorMessage.contains("invalid email") {
            return "И-мэйл хаяг буруу байна."
        }
        
        return error.localizedDescription
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
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onChange(of: email) { oldValue, newValue in
                                    showEmailError = !newValue.isEmpty && !newValue.contains("@")
                                }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showEmailError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        
                        if showEmailError {
                            Text("Зөв и-мэйл хаяг оруулна уу")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Name Fields in HStack for better layout
                    HStack(spacing: 15) {
                        // Last Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Овог")
                                .foregroundColor(.gray)
                                .font(.callout)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                TextField("Таны овог", text: $lastName)
                                    .focused($focusedField, equals: .lastName)
                                    .submitLabel(.next)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        
                        // First Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Нэр")
                                .foregroundColor(.gray)
                                .font(.callout)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                TextField("Таны нэр", text: $firstName)
                                    .focused($focusedField, equals: .firstName)
                                    .submitLabel(.next)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
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
                                } else {
                                    SecureField("Нууц үг", text: $password)
                                }
                            }
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .onChange(of: password) { oldValue, newValue in
                                showPasswordError = !newValue.isEmpty && newValue.count < 6
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showPasswordError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        
                        if showPasswordError {
                            Text("Нууц үг 6-с дээш тэмдэгттэй байх ёстой")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        // Password strength indicator
                        if !password.isEmpty {
                            HStack(spacing: 5) {
                                ForEach(0..<3) { index in
                                    Rectangle()
                                        .fill(passwordStrength > index ? (passwordStrength > 1 ? Color.green : Color.orange) : Color.gray.opacity(0.3))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .padding(.top, 5)
                        }
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
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                
                // Sign Up Button
                Button {
                    Task {
                        do {
                            errorMessage = "" // Clear previous errors
                            try await viewModel.createUser(
                                withEmail: email,
                                password: password,
                                firstName: firstName,
                                lastName: lastName
                            )
                            showStatusSheet = true
                        } catch {
                            registrationError = error
                            errorMessage = getUserFriendlyErrorMessage(from: error)
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
            title: registrationError == nil ? "Амжилттай!" : "Бүртгэл үүсгэхэд алдаа гарлаа",
            message: registrationError == nil ?
                "Таны бүртгэл амжилттай үүслээ! Фитнесс аяллыг эхлүүлцгээе!" :
                getUserFriendlyErrorMessage(from: registrationError!),
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
    
    // Password strength calculation
    private var passwordStrength: Int {
        var strength = 0
        
        if password.count >= 6 {
            strength += 1
        }
        
        // Check for mixed characters (numbers, special chars, etc.)
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: .punctuationCharacters) != nil
        let hasLetters = password.rangeOfCharacter(from: .letters) != nil
        
        if (hasNumbers && hasLetters) || (hasSpecialChars && hasLetters) || (hasNumbers && hasSpecialChars) {
            strength += 1
        }
        
        // Longer passwords are stronger
        if password.count >= 10 {
            strength += 1
        }
        
        return strength
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
