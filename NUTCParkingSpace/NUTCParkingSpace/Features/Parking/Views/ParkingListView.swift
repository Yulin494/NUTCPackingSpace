import SwiftUI

struct ParkingListView: View {
    @StateObject private var viewModel = ParkingListViewModel()
    
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
                    Button(action: {
                        LocationService.shared.testNotification()
                    }) {
                        Image(systemName: "bell.badge")
                    }
                }
            }
        }
    }
}
