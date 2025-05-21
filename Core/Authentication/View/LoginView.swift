//
//  LoginView.swift
//  BeFit
//
//  Created by Chinguun Khongor on 3/9/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showStatusSheet = false
    @State private var loginError: Error?
    @State private var errorMessage: String = ""
    @State private var showEmergencyReset = false
    @State private var loginAttempts = 0
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @State private var isAnimationReady = false
    @State private var titleVisible = true
    @EnvironmentObject var viewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Helper function to get user-friendly error message
    private func getUserFriendlyErrorMessage(from error: Error) -> String {
        // If it's a Firebase error, extract its message
        if let firebaseError = error as? FirebaseError {
            let errorMessage = firebaseError.localizedDescription.lowercased()
            
            // Use Mongolian error messages
            if errorMessage.contains("no user found") {
                return "Ийм и-мэйл хаягтай хэрэглэгч олдсонгүй."
            } else if errorMessage.contains("wrong password") {
                return "Нууц үг буруу байна."
            } else if errorMessage.contains("network") {
                return "Интернэт холболтоо шалгана уу."
            } else if errorMessage.contains("deleted") || errorMessage.contains("not found") {
                return "Энэ бүртгэл устгагдсан байна."
            } else if errorMessage.contains("invalid email") {
                return "И-мэйл хаяг буруу байна."
            } else if errorMessage.contains("disabled") {
                return "Энэ бүртгэл түр хаагдсан байна."
            } else if errorMessage.contains("too many attempts") {
                return "Хэт олон удаа оролдлоо. Түр хүлээнэ үү."
            }  else if errorMessage.contains("malformed or has expired") {
                return "Энэ бүртгэл хаагдсан байна."
            }
            
            // Return the firebase error message if no specific translation
            return firebaseError.localizedDescription
        }
        
        // Process regular errors
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
        } else if errorMessage.contains("account not found") || errorMessage.contains("has been deleted") {
            return "Энэ бүртгэл устгагдсан байна."
        }
        
        // If we don't have a specific translation, return the original
        return error.localizedDescription
    }
    
    // Function to trigger emergency app reset
    private func triggerEmergencyReset() {
        // Reset view state
        email = ""
        password = ""
        errorMessage = ""
        showEmergencyReset = false
        loginAttempts = 0
        
        // Clean local auth state
        viewModel.userSession = nil
        
        // Post notification to trigger app-wide reset
        NotificationCenter.default.post(name: Notification.Name("forceAuthReset"), object: nil)
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
                
                // Only reset login state if we're coming from a fresh start
                if viewModel.currentUser == nil && viewModel.userSession == nil {
                    // We're in a clean login state, can clear any stale errors
                    errorMessage = ""
                    
                    // Reset login attempts if we're in a fresh session
                    if !showEmergencyReset {
                        loginAttempts = 0
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("authenticationFailed"))) { notification in
                // Force update on main thread to ensure UI updates
                DispatchQueue.main.async {
                    if let error = notification.object as? Error {
                        errorMessage = getUserFriendlyErrorMessage(from: error)
                        print("Received authentication failure: \(errorMessage)")
                        
                        // Increment login attempts to show reset button if needed
                        loginAttempts += 1
                        if loginAttempts >= 2 {
                            showEmergencyReset = true
                        }
                    }
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
            
            // Error message displayed just below the password field for better visibility
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 5)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 5)
            }
            
            NavigationLink {
                ForgotPasswordView()
                    .navigationBarBackButtonHidden()
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
                        // Increment login attempts
                        loginAttempts += 1
                        
                        // Clear previous errors when making a new attempt
                        DispatchQueue.main.async {
                            errorMessage = ""
                        }
                        
                        isEmailFocused = false
                        isPasswordFocused = false
                        
                        // Disable keyboard and blur fields before login attempt
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        print("Attempting login with email: \(email)")
                        try await viewModel.signIn(withEmail: email, password: password)
                    } catch {
                        loginError = error
                        // Get user-friendly error message
                        let friendlyError = getUserFriendlyErrorMessage(from: error)
                        
                        // Force update on main thread
                        DispatchQueue.main.async {
                            errorMessage = friendlyError
                            print("Login failed with error: \(friendlyError)")
                            
                            // Show emergency reset button after 2 failed attempts
                            if loginAttempts >= 2 {
                                showEmergencyReset = true
                            }
                        }
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
            
            // Emergency Reset Button (only appears after failed login attempts)
            if showEmergencyReset {
                Button {
                    triggerEmergencyReset()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Апп-ыг дахин эхлүүлэх")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .font(.callout)
                    .padding(.top, 12)
                }
            }
            
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
