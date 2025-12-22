//
//  NUTCParkingSpaceApp.swift
//  NUTCParkingSpace
//
//  Created by imac on 2025/12/21.
//

import SwiftUI

@main
struct NUTCParkingSpaceApp: App {
    // Initialize LocationService on app launch to handle permissions/delegates if needed
    init() {
        _ = LocationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ParkingListView()
        }
    }
}
