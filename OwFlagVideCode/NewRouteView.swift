//
//  NewRouteView.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI
import MapboxMaps
import CoreLocation
import SwiftData

// MARK: - Point Data Model
@Model
final class RoutePoint: Identifiable {
    var id: UUID
    var name: String
    var pointDescription: String
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var route: Route?
    
    init(name: String, description: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.pointDescription = description
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
}

// MARK: - Location Point Data Model for Tracking
@Model
final class LocationPoint: Identifiable {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var route: Route?
    
    init(latitude: Double, longitude: Double) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
    }
}

// MARK: - Route Data Model
@Model
final class Route {
    var name: String
    var routeDescription: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RoutePoint.route) var points: [RoutePoint] = []
    @Relationship(deleteRule: .cascade, inverse: \LocationPoint.route) var locationPoints: [LocationPoint] = []
    
    init(name: String, description: String) {
        self.name = name
        self.routeDescription = description
        self.createdAt = Date()
        self.points = []
        self.locationPoints = []
    }
}

extension RoutePoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension LocationPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct NewRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = LocationManager()
    @State private var cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), zoom: 15)
    @State private var userLocationCoordinate: CLLocationCoordinate2D?
    
    // Estados para el diálogo de punto
    @State private var showingPointDialog = false
    @State private var pointName = ""
    @State private var pointDescription = ""
    
    // Estados para el diálogo de ruta
    @State private var showingRouteDialog = true
    @State private var routeName = ""
    @State private var routeDescription = ""
    @State private var currentRoute: Route?
    @State private var savedPoints: [RoutePoint] = []
    @State private var savedLocationPoints: [LocationPoint] = []
    
    // Estados para tracking de posición
    @State private var isTracking = false
    @State private var trackingTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Título en la parte superior
                    VStack {
                        Text("Nueva Ruta")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                        
                        // Mostrar estado de ubicación
                        if let error = locationManager.locationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        } else if let location = locationManager.currentLocation {
                            Text("Ubicación: \(location.coordinate.latitude, specifier: "%.4f"), \(location.coordinate.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    
                    
                    // Mapa de Mapbox con seguimiento de ubicación y marcador
                    MapReader { proxy in
                        Map(initialViewport: .camera(center: cameraOptions.center!, zoom: cameraOptions.zoom!)) {
                            // Marcador rojo para la posición del usuario
                            if let coordinate = userLocationCoordinate {
                                PointAnnotation(coordinate: coordinate)
                                    .image(.init(image: UIImage(named: "map_mark")!, name: "map_mark")).iconSize(0.2)
                            }
                            
                            // Marcadores para puntos guardados (RoutePoints - azules)
                            ForEvery(savedPoints, id: \.persistentModelID) { point in
                                PointAnnotation(coordinate: point.coordinate)
                                    .image(.init(image: UIImage(named: "mpin")!, name: "mpin")).iconSize(0.2)
                            }
                            
                            // Marcadores para tracking de ubicación (LocationPoints - verdes)
                            ForEvery(savedLocationPoints, id: \.persistentModelID) { locationPoint in
                                PointAnnotation(coordinate: locationPoint.coordinate)
                                    .iconColor(.green)
                                    .iconSize(0.8)
                            }
                            
                            
                        }
                        .mapStyle(.standard)
                        .onReceive(locationManager.$currentLocation) { location in
                            if let location = location {
                                // Actualizar la vista del mapa cuando cambie la ubicación
                                let newCamera = CameraOptions(
                                    center: location.coordinate,
                                    zoom: 15
                                )
                                proxy.camera?.ease(to: newCamera, duration: 1.0)
                                
                                // Actualizar el marcador de ubicación del usuario
                                userLocationCoordinate = location.coordinate
                            }
                        }
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                
                // Botón flotante en la esquina inferior derecha
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingPointDialog = true
                        }) {
                            Image(systemName: "mappin")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Nueva Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        locationManager.stopLocationTracking()
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.requestLocationPermission()
            }
            .onDisappear {
                stopLocationTracking()
                locationManager.stopLocationTracking()
            }
            .sheet(isPresented: $showingPointDialog) {
                NavigationView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del Punto")
                                .font(.headline)
                            TextField("Ingresa el nombre del punto", text: $pointName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción del punto")
                                .font(.headline)
                            TextField("Ingresa la descripción", text: $pointDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 15) {
                            Button("Cancelar") {
                                pointName = ""
                                pointDescription = ""
                                showingPointDialog = false
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            
                            Button("Guardar") {
                                if !pointName.isEmpty, let route = currentRoute, let userLocation = userLocationCoordinate {
                                    let newPoint = RoutePoint(
                                        name: pointName,
                                        description: pointDescription,
                                        latitude: userLocation.latitude,
                                        longitude: userLocation.longitude
                                    )
                                    newPoint.route = route
                                    modelContext.insert(newPoint)
                                    
                                    // Agregar punto al estado para mostrarlo en el mapa
                                    savedPoints.append(newPoint)
                                    
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Error saving point: \(error)")
                                    }
                                }
                                
                                pointName = ""
                                pointDescription = ""
                                showingPointDialog = false
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .navigationTitle("Nuevo Punto")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingRouteDialog) {
                NavigationView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre de la ruta")
                                .font(.headline)
                            TextField("Ingresa el nombre de la ruta", text: $routeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción de la ruta")
                                .font(.headline)
                            TextField("Ingresa la descripción", text: $routeDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 15) {
                            Button("Cancelar") {
                                routeName = ""
                                routeDescription = ""
                                dismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            
                            Button("Guardar") {
                                if !routeName.isEmpty {
                                    let newRoute = Route(name: routeName, description: routeDescription)
                                    modelContext.insert(newRoute)
                                    currentRoute = newRoute
                                    
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Error saving route: \(error)")
                                    }
                                    
                                    routeName = ""
                                    routeDescription = ""
                                    showingRouteDialog = false
                                    
                                    // Iniciar tracking automático después de crear la ruta
                                    startLocationTracking()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .navigationTitle("Nueva Ruta")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
            }
        }
    }
    
    // MARK: - Location Tracking Functions
    private func startLocationTracking() {
        guard currentRoute != nil else { return }
        
        isTracking = true
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            saveCurrentPosition()
        }
    }
    
    private func stopLocationTracking() {
        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    private func saveCurrentPosition() {
        guard let route = currentRoute, 
              let location = userLocationCoordinate else { return }
        
        let locationPoint = LocationPoint(
            latitude: location.latitude,
            longitude: location.longitude
        )
        locationPoint.route = route
        modelContext.insert(locationPoint)
        
        // Agregar al array para mostrar en mapa
        savedLocationPoints.append(locationPoint)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving location point: \(error)")
        }
    }
}

#Preview {
    NewRouteView()
}
