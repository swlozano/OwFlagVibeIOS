//
//  LoginView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var loginSuccess = false
    @State private var loggedInUser: AuthUser?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Iniciar Sesión")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                if loginSuccess, let user = loggedInUser {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("¡Bienvenido!")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text(user.email ?? "Sin email")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Sesión iniciada exitosamente")
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        Button("Cerrar") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
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
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: loginUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Iniciar Sesión")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .disabled(!isFormValid || isLoading)
                }
                
                Spacer()
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Mensaje", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func loginUser() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                let session = try await supabaseManager.signIn(email: email, password: password)
                
                DispatchQueue.main.async {
                    loggedInUser = session.user
                    loginSuccess = true
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    if error.localizedDescription.contains("Invalid login credentials") ||
                       error.localizedDescription.contains("Invalid email or password") {
                        alertMessage = "Email o contraseña incorrectos"
                    } else {
                        alertMessage = "Error al iniciar sesión: \(error.localizedDescription)"
                    }
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}