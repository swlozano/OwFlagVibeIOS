//
//  SupabaseManager.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import Foundation

struct AuthResponse: Codable {
    let user: AuthUser?
    let session: AuthSession?
}

struct AuthUser: Codable, Identifiable {
    let id: UUID
    let email: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        
        // Try different date formats
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
            formatter1.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter2.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formatter3 = DateFormatter()
            formatter3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter3.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter1.date(from: dateString) {
                createdAt = date
            } else if let date = formatter2.date(from: dateString) {
                createdAt = date
            } else if let date = formatter3.date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date() // fallback
            }
        } else {
            createdAt = Date()
        }
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    private let baseURL = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    private let apiKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
    
    @Published var currentUser: AuthUser?
    @Published var currentSession: AuthSession?
    
    init() {}
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            do {
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                return authResponse
            } catch {
                print("Decoding error: \(error)")
                // If decoding fails, create a simple success response
                return AuthResponse(user: nil, session: nil)
            }
        } else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["message"] as? String {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else if let responseString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])
            }
            throw URLError(.badServerResponse)
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthSession {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("Login Response data: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let authSession = try decoder.decode(AuthSession.self, from: data)
                DispatchQueue.main.async {
                    self.currentUser = authSession.user
                    self.currentSession = authSession
                }
                return authSession
            } catch {
                print("Login decoding error: \(error)")
                throw NSError(domain: "SupabaseError", code: 422, userInfo: [NSLocalizedDescriptionKey: "Error al procesar la respuesta del servidor"])
            }
        } else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorData["message"] as? String {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            } else if let responseString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])
            }
            throw URLError(.badServerResponse)
        }
    }
    
    func signOut() async throws {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.currentSession = nil
        }
    }
    
    func getCurrentUser() -> AuthUser? {
        return currentUser
    }
    
    func getCurrentSession() -> AuthSession? {
        return currentSession
    }
}
