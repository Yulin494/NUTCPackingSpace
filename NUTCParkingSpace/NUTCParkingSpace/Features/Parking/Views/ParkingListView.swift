import SwiftUI

struct ParkingListView: View {
    @StateObject private var viewModel = ParkingListViewModel()
    // 控制設定頁面的顯示狀態
    @State private var showSettings = false
    @State private var showMap = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading && viewModel.parkingLots.isEmpty {
                    // 骨架屏載入效果
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonRowView()
                            .listRowSeparator(.hidden) // 隱藏分隔線讓骨架更像一個整體或自然排列
                    }
                } else if let errorMessage = viewModel.errorMessage, viewModel.parkingLots.isEmpty {
                    // 友善的錯誤頁面
                    FriendlyErrorView(message: errorMessage) {
                        viewModel.fetchParkingData()
                    }
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(ParkingType.allCases, id: \.self) { type in
                        let lots = viewModel.parkingLots.filter { $0.type == type }
                        if !lots.isEmpty {
                            Section(header: Text(type.rawValue)) {
                                ForEach(lots) { lot in
                                    ParkingRowView(parkingLot: lot)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("臺中科大剩餘車位")
            .onAppear {
                viewModel.startAutoRefresh()
                LocationService.shared.requestPermissions()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .refreshable {
                // 使用 continuation 將 callback 轉為 async
                await withCheckedContinuation { continuation in
                    viewModel.fetchParkingData {
                        continuation.resume()
                    }
                }
                
                // 根據結果觸發觸覺回饋
                if viewModel.errorMessage == nil {
                    HapticManager.shared.notification(type: .success)
                } else {
                    HapticManager.shared.notification(type: .error)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // 地圖按鈕
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            showMap = true
                        }) {
                            Image(systemName: "map")
                        }
                        
                        // 設定按鈕：點擊開啟設定頁面
                        Button(action: {
                            HapticManager.shared.impact(style: .light)
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            // 彈出設定頁面
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            // 彈出地圖頁面
            .sheet(isPresented: $showMap) {
                CampusMapView()
            }
        }
    }
}
