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
    @StateObject private var authService = AuthService.shared

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Usuario autenticado - mostrar pantalla de rutas
                RoutesView()
            } else {
                // Usuario no autenticado - mostrar pantalla de inicio
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
    }
}

#Preview {
    ContentView()
}