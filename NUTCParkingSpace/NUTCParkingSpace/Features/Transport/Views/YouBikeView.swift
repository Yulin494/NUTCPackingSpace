import SwiftUI
import CoreLocation

struct YouBikeView: View {
    @State private var stations: [YouBikeStation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var radiusKM: Double = 1.5   // 搜尋半徑（公里）

    var body: some View {
        Group {
            if isLoading {
                ProgressView("載入中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(err)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("重試") { Task { await load() } }
                        .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if stations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bicycle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("附近 \(Int(radiusKM * 1000)) 公尺內無 YouBike 站點")
                        .foregroundColor(.secondary)
                    Button("擴大至 2 公里") {
                        radiusKM = 2.0
                        Task { await load() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(stations) { station in
                    YouBikeRow(station: station)
                }
                .refreshable { await load() }
            }
        }
        .navigationTitle("YouBike 站點")
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isLoading {
                    Text("\(stations.count) 站")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            stations = try await YouBikeService.shared.fetchNearby(radiusMeters: radiusKM * 1000)
        } catch {
            errorMessage = "無法取得資料：\(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct YouBikeRow: View {
    let station: YouBikeStation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(station.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                distanceBadge
            }

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(station.address.isEmpty ? station.district : station.address)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                bikeCount
                dockCount
                occupancyBar
            }
        }
        .padding(.vertical, 4)
    }

    private var bikeCount: some View {
        HStack(spacing: 4) {
            Image(systemName: "bicycle")
                .font(.caption)
                .foregroundColor(station.availableBikes > 0 ? .green : .red)
            Text("\(station.availableBikes) 台可借")
                .font(.caption)
                .foregroundColor(station.availableBikes > 0 ? .primary : .red)
        }
    }

    private var dockCount: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down.to.line")
                .font(.caption)
                .foregroundColor(station.emptyDocks > 0 ? .blue : .secondary)
            Text("\(station.emptyDocks) 格可還")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var occupancyBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: geo.size.width * station.occupancyRatio)
            }
        }
        .frame(height: 4)
    }

    private var barColor: Color {
        station.occupancyRatio > 0.5 ? .green :
        station.occupancyRatio > 0.2 ? .orange : .red
    }

    private var distanceBadge: some View {
        Text(distanceString)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }

    private var distanceString: String {
        station.distance < 1000
            ? "\(Int(station.distance)) m"
            : String(format: "%.1f km", station.distance / 1000)
    }
}

#Preview {
    NavigationStack {
        YouBikeView()
    }
}
