//
//  RoutesView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI
import SwiftData

struct RoutesView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Query(sort: \Route.createdAt, order: .reverse) private var routes: [Route]
    @State private var showingNewRoute = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Contenido principal
                    if routes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No hay rutas guardadas")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("Crea tu primera ruta presionando el botón +")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.bottom, 200) // Espacio para botones inferiores
                    } else {
                        List(routes) { route in
                            NavigationLink(destination: RouteView(route: route)) {
                                RouteRowView(route: route)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    // Botón de logout en la parte inferior
                    VStack {
                        if let currentUser = supabaseManager.getCurrentUser() {
                            Text("Bienvenido, \(currentUser.email ?? "Usuario")")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                        Button("Cerrar Sesión") {
                            Task {
                                try? await supabaseManager.signOut()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                
                // Botón flotante
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewRoute = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 150) // Espacio sobre el botón de logout
                    }
                }
            }
            .navigationTitle("Rutas")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingNewRoute) {
                NewRouteView()
            }
        }
    }
}

struct RouteRowView: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(route.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(route.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !route.routeDescription.isEmpty {
                Text(route.routeDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoutesView()
}