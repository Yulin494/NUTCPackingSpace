import SwiftUI
import NUTCParkingShared

struct WatchParkingListView: View {
    @State private var lots: [ParkingLotData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("載入中...")
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        
                        Button("重試") {
                            Task { await loadData() }
                        }
                        .padding(.top)
                    }
                } else {
                    List(lots) { lot in
                        WatchParkingRow(lot: lot)
                    }
                }
            }
            .navigationTitle("校園車位")
            .onAppear {
                Task { await loadData() }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // 先讀取快取
        if let cached = SharedParkingCache.load() {
            self.lots = cached
            self.isLoading = false
        }
        
        do {
            let freshLots = try await ParkingFetchService.shared.fetchParkingData()
            self.lots = freshLots
            SharedParkingCache.save(freshLots)
            self.isLoading = false
        } catch {
            if self.lots.isEmpty {
                self.errorMessage = "無法連線"
            }
            self.isLoading = false
        }
    }
}

#Preview {
    WatchParkingListView()
}
