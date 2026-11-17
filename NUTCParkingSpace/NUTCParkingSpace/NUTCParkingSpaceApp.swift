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
    @AppStorage("appearanceStyle") var appearanceStyle: AppearanceStyle = .standard

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
            // 儲存區可能因先前的資料模型變更而無法遷移或已毀損。
            // 與其直接 fatalError 讓使用者一開 App 就閃退且無法復原，
            // 改為退回「僅記憶體」容器，讓 App 仍可啟動使用；資料待下次正常啟動再持久化。
            print("持久化 ModelContainer 初始化失敗，改用記憶體容器：\(error)")
            do {
                modelContainer = try ModelContainer(
                    for: Course.self, HomeworkItem.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("連記憶體 ModelContainer 都無法建立：\(error)")
            }
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
            .environment(\.appearanceStyle, appearanceStyle)
            // 只在使用者看完 onboarding、進入主畫面後才申請通知權限，
            // 避免在教學第一頁就跳出無情境的系統權限彈窗。
            .onChange(of: hasShownOnboarding) { _, shown in
                if shown { requestNotificationPermission() }
            }
            .onAppear {
                if hasShownOnboarding { requestNotificationPermission() }
            }
            #if DEBUG
            .modifier(PixelMapGalleryRoot())
            #endif
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // 通知權限已申請
        }
    }
}

#if DEBUG
/// DEBUG 專用：啟動參數含 `-PixelMapGallery YES` 時，根畫面改顯示像素地圖檢視
private struct PixelMapGalleryRoot: ViewModifier {
    func body(content: Content) -> some View {
        if UserDefaults.standard.bool(forKey: "PixelMapGallery") {
            PixelMapGalleryView()
        } else {
            content
        }
    }
}
#endif
