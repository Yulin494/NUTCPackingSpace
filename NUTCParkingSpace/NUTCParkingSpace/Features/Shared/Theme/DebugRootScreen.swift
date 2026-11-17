//
//  DebugRootScreen.swift
//  NUTCParkingSpace
//
//  DEBUG 專用：啟動參數 `-DebugRootScreen <name>` 讓 App 直接顯示指定子頁（截圖用）。
//  name：schedule、homework、weather、calendar、announcements、library、dining、
//        youbike、emergency、portal、campusmap、license
//

#if DEBUG
import SwiftUI

struct DebugRootScreen: ViewModifier {
    func body(content: Content) -> some View {
        if let name = UserDefaults.standard.string(forKey: "DebugRootScreen"), !name.isEmpty {
            DebugRootScreenHost(name: name)
        } else {
            content
        }
    }
}

private struct DebugRootScreenHost: View {
    let name: String

    var body: some View {
        // 只負責包 NavigationStack；外觀由入口的 environment 注入
        NavigationStack { screen }
    }

    @ViewBuilder private var screen: some View {
        switch name {
        case "schedule": ScheduleView()
        case "homework": HomeworkView()
        case "weather": WeatherView()
        case "calendar": AcademicCalendarView()
        case "announcements": AnnouncementListView()
        case "library": LibraryView()
        case "dining": DiningView()
        case "youbike": YouBikeView()
        case "emergency": EmergencyView()
        case "portal": SchoolPortalView()
        case "campusmap": CampusMapView()
        case "license": FontLicenseView()
        default: Text("unknown DebugRootScreen: \(name)")
        }
    }
}
#endif
