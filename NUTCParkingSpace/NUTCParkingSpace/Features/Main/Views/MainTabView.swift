//
//  MainTabView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: 停車
            ParkingListView()
                .tabItem {
                    Label("停車", systemImage: "car.fill")
                }

            // Tab 2: 校園
            CampusHubView()
                .tabItem {
                    Label("校園", systemImage: "building.2.fill")
                }

            // Tab 3: 課業
            StudyHubView()
                .tabItem {
                    Label("課業", systemImage: "book.fill")
                }

            // Tab 4: 設定
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
