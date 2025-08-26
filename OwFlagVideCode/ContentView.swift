//
//  ContentView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingRegistration = false
    @State private var showingLogin = false
    @StateObject private var supabaseManager = SupabaseManager.shared

    var body: some View {
        
        NavigationView {
            VStack {
                Text("Vibe Coding")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 16) {
                    Button("Registro de Usuario") {
                        showingRegistration = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Button("Iniciar Sesión") {
                        showingLogin = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                if let currentUser = supabaseManager.getCurrentUser() {
                    VStack {
                        Text("Usuario Conectado")
                            .font(.headline)
                            .padding()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email: \(currentUser.email ?? "Sin email")")
                                .font(.body)
                            Text("ID: \(currentUser.id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Conectado desde: \(currentUser.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        Button("Cerrar Sesión") {
                            Task {
                                try? await supabaseManager.signOut()
                            }
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Inicio")
            .sheet(isPresented: $showingRegistration) {
                UserRegistrationView()
            }
            .sheet(isPresented: $showingLogin) {
                LoginView()
            }
        }
    }

}

#Preview {
    ContentView()
}
