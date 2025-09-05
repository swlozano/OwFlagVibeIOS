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

struct RouteView: View {
    let route: Route
    @State private var cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 40.7135, longitude: -74.0066), zoom: 15)
    @StateObject private var viewModel = RouteViewModel()
    
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
                viewModel.publishRoute(route)
            }) {
                HStack {
                    if viewModel.isPublishing {
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
                .background(viewModel.isPublishing ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.isPublishing)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("Ruta")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Resultado", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.publishMessage)
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

#Preview {
    let sampleRoute = Route(name: "Ruta de Ejemplo", description: "Esta es una descripción de ejemplo para la ruta")
    return RouteView(route: sampleRoute)
}
