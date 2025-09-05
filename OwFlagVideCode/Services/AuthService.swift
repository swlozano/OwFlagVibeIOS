//
//  AuthService.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 05/09/25.
//

import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AuthUserClient?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "")!,
        supabaseKey: Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    )
    
    private init() {
        checkAuthStatus()
    }
    
    // MARK: - Auth Status
    
    private func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                currentUser = AuthUserClient(
                    id: session.user.id,
                    email: session.user.email
                )
                isAuthenticated = true
            } catch {
                currentUser = nil
                isAuthenticated = false
            }
        }
    }
    
    // MARK: - Registration
    
    func signUp(email: String, password: String) async throws -> AuthUserClient {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            let user = authResponse.user
        
            
            
            let authUser = AuthUserClient(
                id: user.id,
                email: user.email
            )
            
            currentUser = authUser
            isAuthenticated = true
            
            return authUser
            
        } catch {
            throw AuthError.registrationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Login
    
    func signIn(email: String, password: String) async throws -> AuthUserClient {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let authUser = AuthUserClient(
                id: session.user.id,
                email: session.user.email
            )
            
            currentUser = authUser
            isAuthenticated = true
            
            return authUser
            
        } catch {
            throw AuthError.loginFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Logout
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            throw AuthError.logoutFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            //try await supabase.auth.resetPassword(email: email)
        } catch {
            throw AuthError.resetPasswordFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Get Current Session
    
    func getCurrentSession() async -> Session? {
        do {
            return try await supabase.auth.session
        } catch {
            return nil
        }
    }
}

// MARK: - Models

struct AuthUserClient {
    let id: UUID
    let email: String?
}

enum AuthError: LocalizedError {
    case registrationFailed(String)
    case loginFailed(String)
    case logoutFailed(String)
    case resetPasswordFailed(String)
    case userNotFound
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return "Error de registro: \(message)"
        case .loginFailed(let message):
            return "Error de inicio de sesión: \(message)"
        case .logoutFailed(let message):
            return "Error al cerrar sesión: \(message)"
        case .resetPasswordFailed(let message):
            return "Error al restablecer contraseña: \(message)"
        case .userNotFound:
            return "Usuario no encontrado"
        case .invalidCredentials:
            return "Credenciales inválidas"
        }
    }
}
