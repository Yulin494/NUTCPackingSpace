import SwiftUI

struct ParkingListView: View {
    @StateObject private var viewModel = ParkingListViewModel()
    // 控制設定頁面的顯示狀態
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading && viewModel.parkingLots.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("載入中...")
                        Spacer()
                    }
                } else if let errorMessage = viewModel.errorMessage, viewModel.parkingLots.isEmpty {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        Button("重試") {
                            viewModel.fetchParkingData()
                        }
                        .buttonStyle(.bordered)
                    }
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
                viewModel.fetchParkingData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 設定按鈕：點擊開啟設定頁面
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            // 彈出設定頁面
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
