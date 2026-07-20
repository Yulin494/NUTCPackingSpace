import SwiftUI

struct ParkingListView: View {
    @StateObject private var viewModel = ParkingListViewModel()
    @ObservedObject private var commuteManager = CommuteManager.shared
    // 控制設定頁面的顯示狀態
    @State private var showSettings = false
    @State private var showMap = false

    var body: some View {
        NavigationStack {
            List {
                // 追蹤中橫幅（可停止）
                if commuteManager.isCommuting {
                    trackingBanner
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                }

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

                    if !viewModel.parkingLots.isEmpty {
                        Text("長按停車場可開始通勤即時追蹤")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
                        // 追蹤全部按鈕：可開始 / 停止（開始時顯示實心、監控中顯示斜線）
                        Button(action: {
                            HapticManager.shared.impact(style: .medium)
                            if commuteManager.isCommuting {
                                commuteManager.stopCommuting()
                            } else {
                                commuteManager.startTrackingAll()
                            }
                        }) {
                            Image(systemName: commuteManager.isCommuting ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(commuteManager.isCommuting ? .red : nil)
                        }

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

    // MARK: - 追蹤中橫幅

    private var trackingBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.title3)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("即時動態追蹤中")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(commuteManager.trackingDescription ?? "正在監控車位")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Button {
                HapticManager.shared.impact(style: .medium)
                commuteManager.stopCommuting()
            } label: {
                Text("停止")
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(.white)
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            LinearGradient(colors: [.blue, Color(red: 0.2, green: 0.4, blue: 0.85)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
