//
//  MainTabView.swift
//  NUTCParkingSpace
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: 停車
            ParkingListView()
                .tabItem {
                    Label("停車", systemImage: "parkingsign")
                }

            // Tab 2: 課業
            StudyHubView()
                .tabItem {
                    Label("課業", systemImage: "book.fill")
                }

            // Tab 3: 首頁（中間）
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }

            // Tab 4: 校園
            CampusHubView()
                .tabItem {
                    Label("校園", systemImage: "building.2.fill")
                }

            // Tab 5: 設定
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
