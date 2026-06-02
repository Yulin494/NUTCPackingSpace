//
//  NUTCParkingSpaceApp.swift
//  NUTCParkingSpace
//
//  Created by imac on 2025/12/21.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct NUTCParkingSpaceApp: App {
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    let modelContainer: ModelContainer

    init() {
        // Initialize LocationService
        _ = LocationService.shared

        // Setup SwiftData
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(
                for: Course.self, HomeworkItem.self,
                configurations: modelConfiguration
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasShownOnboarding {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    OnboardingView(hasShownOnboarding: $hasShownOnboarding)
                }
            }
            .onAppear {
                requestNotificationPermission()
            }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // 通知權限已申請
        }
    }
}
