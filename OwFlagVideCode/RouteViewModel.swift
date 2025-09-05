//
//  RouteViewModel.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 05/09/25.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class RouteViewModel: ObservableObject {
    @Published var isPublishing = false
    @Published var publishMessage = ""
    @Published var showAlert = false
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://xrhrzvsehumzahcdtzzt.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyaHJ6dnNlaHVtemFoY2R0enp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQzMzA3ODAsImV4cCI6MjA1OTkwNjc4MH0.TLkmvnntYekunucf7-s6H0Pchy-M39VLl83zeX2hbZo"
    )
    
    func publishRoute(_ route: Route) {
        Task {
            isPublishing = true
            
            do {
                let routeInsert = RouteInsert(
                    name: route.name,
                    route_description: route.routeDescription,
                    owner_id: UUID(uuidString: "c34048ff-b223-48bb-81d6-6589dea8c5bd")!
                )
                
                let createdRoute: RouteRow = try await supabase
                    .from("routes")
                    .insert(routeInsert)
                    .select()
                    .single()
                    .execute()
                    .value
                
                let routeId = createdRoute.id
                
                // 2. Subir los puntos de interés (RoutePoints)
                if !route.points.isEmpty {
                    let routePointsInsert = route.points.map { point in
                        RoutePointInsert(
                            route_id: routeId,
                            name: point.name,
                            description: point.pointDescription,
                            latitude: point.latitude,
                            longitude: point.longitude
                        )
                    }
                    
                    try await supabase
                        .from("route_points")
                        .insert(routePointsInsert)
                        .execute()
                }
                
                // 3. Subir los puntos de ubicación (LocationPoints)
                if !route.locationPoints.isEmpty {
                    let locationPointsInsert = route.locationPoints.map { location in
                        LocationPointInsert(
                            route_id: routeId,
                            latitude: location.latitude,
                            longitude: location.longitude,
                            recorded_at: ISO8601DateFormatter().string(from: location.timestamp)
                        )
                    }
                    
                    try await supabase
                        .from("location_points")
                        .insert(locationPointsInsert)
                        .execute()
                }
                
                publishMessage = "¡Ruta publicada exitosamente!"
                showAlert = true
                
            } catch {
                publishMessage = "Error al publicar: \(error.localizedDescription)"
                showAlert = true
            }
            
            isPublishing = false
        }
    }
}

// MARK: - Models

struct RouteRow: Decodable {
    let id: UUID
    let name: String
    let route_description: String?
    let created_at: String
    let owner_id: UUID
}

struct RouteInsert: Encodable {
    let name: String
    let route_description: String?
    let owner_id: UUID
}

struct RoutePointInsert: Encodable {
    let route_id: UUID
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
}

struct LocationPointInsert: Encodable {
    let route_id: UUID
    let latitude: Double
    let longitude: Double
    let recorded_at: String
}