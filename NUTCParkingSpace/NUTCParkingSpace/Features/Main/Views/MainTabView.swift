//
//  MainTabView.swift
//  NUTCParkingSpace
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2

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
    }
}

#Preview {
    MainTabView()
}
