//
//  RouteView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI
import SwiftData
import MapboxMaps
import CoreLocation
import Supabase

struct RouteView: View {
    let route: Route
    @State private var cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 40.7135, longitude: -74.0066), zoom: 15)
    @State private var isPublishing = false
    @State private var publishMessage = ""
    @State private var showAlert = false
    
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://xrhrzvsehumzahcdtzzt.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyaHJ6dnNlaHVtemFoY2R0enp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQzMzA3ODAsImV4cCI6MjA1OTkwNjc4MH0.TLkmvnntYekunucf7-s6H0Pchy-M39VLl83zeX2hbZo"
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Información de la ruta en la parte superior
            VStack(alignment: .leading, spacing: 8) {
                Text(route.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !route.routeDescription.isEmpty {
                    Text(route.routeDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Creada: \(route.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Puntos: \(route.points.count) | Tracking: \(route.locationPoints.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Mapa de Mapbox
            MapReader { proxy in
                Map(initialViewport: .camera(center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), zoom: cameraOptions.zoom!)) {
                    
                    // Polyline para mostrar la ruta completa usando LocationPoints
                    if !route.locationPoints.isEmpty {
                        let sortedLocationPoints = route.locationPoints.sorted { $0.timestamp < $1.timestamp }
                        let coordinates = sortedLocationPoints.map { $0.coordinate }
                        
                        PolylineAnnotation(lineCoordinates: coordinates)
                            .lineColor(.blue)
                            .lineWidth(4.0)
                    }
                    
                    // Marcadores para RoutePoints (puntos manuales)
                    ForEvery(route.points, id: \.persistentModelID) { point in
                        PointAnnotation(coordinate: point.coordinate)
                            .image(.init(image: UIImage(named: "mpin")!, name: "mpin")).iconSize(0.3)
                    }
                    
                    // Punto de inicio (primer LocationPoint)
                    if let firstPoint = route.locationPoints.sorted(by: { $0.timestamp < $1.timestamp }).first {
                        PointAnnotation(id: "start", coordinate: firstPoint.coordinate)
                            .iconColor(.green)
                            .iconSize(1.0)
                    }
                    
                    // Punto de fin (último LocationPoint)
                    if let lastPoint = route.locationPoints.sorted(by: { $0.timestamp < $1.timestamp }).last,
                       route.locationPoints.count > 1 {
                        PointAnnotation(id: "end", coordinate: lastPoint.coordinate)
                            .iconColor(.red)
                            .iconSize(1.0)
                    }
                }
                .mapStyle(.standard)
                .onMapLoaded { _ in
                    // Priorizar el primer LocationPoint si existe
                    if let firstLocationPoint = route.locationPoints.sorted(by: { $0.timestamp < $1.timestamp }).first {
                        let newCamera = CameraOptions(
                            center: firstLocationPoint.coordinate,
                            zoom: 15
                        )
                        proxy.camera?.ease(to: newCamera, duration: 1.0)
                        return
                    }
                    
                    // Si no hay LocationPoints, usar el primer RoutePoint
                    if let firstRoutePoint = route.points.first {
                        let newCamera = CameraOptions(
                            center: firstRoutePoint.coordinate,
                            zoom: 15
                        )
                        proxy.camera?.ease(to: newCamera, duration: 1.0)
                        return
                    }
                    
                    // Fallback: calcular centro de todos los puntos
                    let allPoints = route.points.map { $0.coordinate } + route.locationPoints.map { $0.coordinate }
                    
                    guard allPoints.count > 1 else { return }
                    
                    let latitudes = allPoints.map { $0.latitude }
                    let longitudes = allPoints.map { $0.longitude }
                    
                    let minLat = latitudes.min() ?? 0
                    let maxLat = latitudes.max() ?? 0
                    let minLon = longitudes.min() ?? 0
                    let maxLon = longitudes.max() ?? 0
                    
                    let centerLat = (minLat + maxLat) / 2
                    let centerLon = (minLon + maxLon) / 2
                    
                    let newCamera = CameraOptions(
                        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                        zoom: 14
                    )
                    proxy.camera?.ease(to: newCamera, duration: 1.0)
                }
            }
            .padding(.bottom, 10)
            
            // Botón Publicar en la parte inferior
            Button(action: {
                publishRoute()
            }) {
                HStack {
                    if isPublishing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Publicando...")
                    } else {
                        Text("Publicar")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPublishing ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(isPublishing)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Ruta")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Resultado", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(publishMessage)
        }
    }
    
    struct RouteRow: Decodable {
        let id: UUID
        let name: String
        let route_description: String?
        let created_at: String
        let owner_id: UUID
    }

    // Lo que vas a enviar (insert)
    struct RouteInsert: Encodable {
        let name: String
        let route_description: String?
        let owner_id: UUID       // 👈 agregar owner_id
    }
    
    private func publishRoute() {
        Task {
            isPublishing = true
            
            do {
                //let user = try await supabase.auth.user()
                //let userId = user.id

                let routeInsert = RouteInsert(
                    name: "Popayán – Cali",
                    route_description: "Salida dominguera",
                    owner_id: UUID(uuidString: "c34048ff-b223-48bb-81d6-6589dea8c5bd")!
                )

                
                let createdRoute: RouteRow = try await supabase
                    .from("routes")         // 👈 en vez de supabase.database
                    .insert(routeInsert)
                    .select()
                    .single()
                    .execute()
                    .value
                
                let routeId = createdRoute.id
                
                // 2. Subir los puntos de interés (RoutePoints)
                /*if !route.points.isEmpty {
                    let routePointsInsert = route.points.map { point in
                        [
                            "route_id": routeId,
                            "name": point.name,
                            "description": point.pointDescription,
                            "latitude": point.latitude,
                            "longitude": point.longitude
                        ]
                    }
                    
                    try await supabase
                        .from("route_points")
                        .insert(routePointsInsert)
                        .execute()
                }*/
                
                // 3. Subir los puntos de ubicación (LocationPoints)
                /*if !route.locationPoints.isEmpty {
                    let locationPointsInsert = route.locationPoints.map { location in
                        [
                            "route_id": routeId,
                            "latitude": location.latitude,
                            "longitude": location.longitude,
                            "recorded_at": ISO8601DateFormatter().string(from: location.timestamp)
                        ]
                    }
                    
                    try await supabase
                        .from("location_points")
                        .insert(locationPointsInsert)
                        .execute()
                }*/
                
                publishMessage = "¡Ruta publicada exitosamente!"
                showAlert = true
                
            } catch {
                publishMessage = "Error al publicar: \(error.localizedDescription)"
                showAlert = true
            }
            
            isPublishing = false
        }
    }
    
    private func centerMapOnRoute() {
        // Priorizar el primer LocationPoint si existe
        if let firstLocationPoint = route.locationPoints.sorted(by: { $0.timestamp < $1.timestamp }).first {
            cameraOptions = CameraOptions(center: firstLocationPoint.coordinate, zoom: 15)
            return
        }
        
        // Si no hay LocationPoints, usar RoutePoints
        if let firstRoutePoint = route.points.first {
            cameraOptions = CameraOptions(center: firstRoutePoint.coordinate, zoom: 15)
            return
        }
        
        // Fallback: Si hay múltiples puntos, calcular el centro
        let allPoints = route.points.map { $0.coordinate } + route.locationPoints.map { $0.coordinate }
        
        guard allPoints.count > 1 else { return }
        
        let latitudes = allPoints.map { $0.latitude }
        let longitudes = allPoints.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon), zoom: 14)
    }
}

struct RouteRow: Codable {
    let id: String
    let name: String
    let route_description: String?
    let created_at: String
    let owner_id: String
}

#Preview {
    let sampleRoute = Route(name: "Ruta de Ejemplo", description: "Esta es una descripción de ejemplo para la ruta")
    return RouteView(route: sampleRoute)
}
