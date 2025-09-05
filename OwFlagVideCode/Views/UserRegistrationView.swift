//
//  UserRegistrationView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI

struct UserRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var registrationSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Registro de Usuario")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Ingrese su email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contraseña")
                            .font(.headline)
                        SecureField("Ingrese su contraseña", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repetir Contraseña")
                            .font(.headline)
                        SecureField("Repita su contraseña", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    Task {
                        await registerUser()
                    }
                }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(authService.isLoading ? "Registrando..." : "Registrarse")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .disabled(!isFormValid || authService.isLoading)
                
                Spacer()
            }
            .navigationTitle("Registro")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Resultado", isPresented: $showAlert) {
                Button("OK") {
                    if registrationSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func registerUser() async {
        guard isFormValid else { return }
        
        do {
            let user = try await authService.signUp(email: email, password: password)
            
            // Registro exitoso
            alertMessage = "¡Cuenta creada exitosamente! Bienvenido \(user.email ?? "")."
            registrationSuccess = true
            showAlert = true
            
            // Reset form
            email = ""
            password = ""
            confirmPassword = ""
            
        } catch {
            // Error en el registro
            if error.localizedDescription.contains("User already registered") {
                alertMessage = "Ya existe un usuario registrado con este email"
            } else {
                alertMessage = error.localizedDescription
            }
            registrationSuccess = false
            showAlert = true
        }
    }
}

#Preview {
    UserRegistrationView()
}
