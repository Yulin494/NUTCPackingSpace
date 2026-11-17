//
//  MainTabView.swift
//  NUTCParkingSpace
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = MainTabView.initialTab
    @Environment(\.appearanceStyle) private var appearanceStyle

    /// 預設停在首頁（2）。DEBUG 建置可用啟動參數 `-DebugInitialTab N` 指定起始分頁，方便模擬器截圖。
    private static var initialTab: Int {
        #if DEBUG
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "DebugInitialTab") != nil {
            let tab = defaults.integer(forKey: "DebugInitialTab")  // 啟動參數的值是字串，integer(forKey:) 會轉成整數
            if (0...4).contains(tab) { return tab }
        }
        #endif
        return 2
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ParkingListView()
                .tabItem { Label("停車", systemImage: "parkingsign") }
                .tag(0)

            StudyHubView()
                .tabItem { Label("課業", systemImage: "book.fill") }
                .tag(1)

            HomeView()
                .tabItem { Label("首頁", systemImage: "house.fill") }
                .tag(2)

            CampusHubView()
                .tabItem { Label("校園", systemImage: "building.2.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(4)
        }
        // 像素模式：隱藏系統 tab bar，改用自繪 PixelTabBar；標準模式維持原樣
        .toolbar(appearanceStyle == .pixel ? .hidden : .automatic, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if appearanceStyle == .pixel {
                PixelTabBar(selection: $selectedTab)
            }
        }
    }
}

#Preview {
    MainTabView()
}
