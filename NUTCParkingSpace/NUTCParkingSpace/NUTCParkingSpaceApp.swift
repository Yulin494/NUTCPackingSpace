//
//  NUTCParkingSpaceApp.swift
//  NUTCParkingSpace
//
//  Created by imac on 2025/12/21.
//

import SwiftUI

@main
struct NUTCParkingSpaceApp: App {
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    
    // Initialize LocationService on app launch to handle permissions/delegates if needed
    init() {
        _ = LocationService.shared
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some Scene {
        WindowGroup {
            Group {
                if hasShownOnboarding {
                    ParkingListView()
                        .transition(.opacity)
                } else {
                    OnboardingView(hasShownOnboarding: $hasShownOnboarding)
                }
            }
            .onAppear {
                // App 啟動初始化邏輯可放在這裡
            }
        }
    }
}
