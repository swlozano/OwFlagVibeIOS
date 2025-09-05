//
//  OwFlagVideCodeApp.swift
//  OwFlagVideCode
//
//  Created by The Main Fun on 25/08/25.
//

import SwiftUI
import SwiftData

@main
struct OwFlagVideCodeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Route.self, RoutePoint.self, LocationPoint.self])
    }
}
