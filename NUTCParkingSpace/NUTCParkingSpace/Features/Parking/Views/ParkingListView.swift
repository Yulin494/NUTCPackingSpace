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
                    ForEach(viewModel.parkingLots) { lot in
                        ParkingRowView(parkingLot: lot)
                    }
                }
            }
            .navigationTitle("機車車位查詢")
            .onAppear {
                viewModel.fetchParkingData()
                LocationService.shared.requestPermissions()
            }
            .refreshable {
                viewModel.fetchParkingData()
            }
        }
    }
}
