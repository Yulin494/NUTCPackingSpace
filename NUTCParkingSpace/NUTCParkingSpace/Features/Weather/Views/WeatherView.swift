import SwiftUI
import NUTCParkingShared

struct WeatherView: View {
    @State private var weather: SharedWeatherData?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("載入天氣…")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let err = error, weather == nil {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash").font(.largeTitle).foregroundColor(.secondary)
                    Text(err).multilineTextAlignment(.center).foregroundColor(.secondary)
                    Button("重試") { Task { await load() } }.buttonStyle(.bordered)
                }
                .padding()
            } else if let w = weather {
                VStack(spacing: 20) {
                    currentCard(w)
                    detailRow(w)
                    hourlyCard(w)
                }
                .padding()
            }
        }
        .navigationTitle("台中天氣")
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
        .refreshable { await load() }
        .toolbar {
            if let w = weather {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(w.fetchedAt, style: .time)
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - 當前天氣大卡

    private func currentCard(_ w: SharedWeatherData) -> some View {
        VStack(spacing: 8) {
            Image(systemName: w.symbolName)
                .font(.system(size: 64))
                .foregroundStyle(symbolColor(w.weatherCode))
                .symbolRenderingMode(.multicolor)

            Text("\(Int(w.temperature.rounded()))°C")
                .font(.system(size: 56, weight: .thin, design: .rounded))

            Text(w.description)
                .font(.title3)
                .foregroundColor(.secondary)

            Text("體感 \(Int(w.apparentTemperature.rounded()))°C")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - 細節列

    private func detailRow(_ w: SharedWeatherData) -> some View {
        HStack {
            detailItem(icon: "humidity.fill",    label: "濕度",   value: "\(w.humidity)%")
            Divider().frame(height: 40)
            detailItem(icon: "wind",             label: "風速",   value: String(format: "%.1f km/h", w.windSpeed))
            Divider().frame(height: 40)
            detailItem(icon: "location.fill",    label: "位置",   value: "台中市")
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func detailItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundColor(.blue)
            Text(value).font(.subheadline).bold()
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 逐時預報

    private func hourlyCard(_ w: SharedWeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日逐時預報")
                .font(.headline)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(zip(w.hourlyHours.indices, w.hourlyHours)), id: \.0) { i, hour in
                        VStack(spacing: 6) {
                            Text(String(format: "%02d:00", hour))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Image(systemName: SharedWeatherData.weatherSymbol(for: w.hourlyCodes[i]))
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .symbolRenderingMode(.multicolor)
                            Text("\(Int(w.hourlyTemps[i].rounded()))°")
                                .font(.subheadline).bold()
                        }
                        .frame(width: 52)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        error = nil
        do {
            weather = try await WeatherFetchService.shared.fetch()
        } catch {
            self.error = error.localizedDescription
            weather = SharedWeatherCache.load()   // 讀快取
        }
        isLoading = false
    }

    private func symbolColor(_ code: Int) -> Color {
        switch code {
        case 0, 1:      return .yellow
        case 2, 3:      return .gray
        case 45, 48:    return .gray
        case 51...65:   return .blue
        case 71...77:   return .cyan
        case 80...82:   return .blue
        case 95...99:   return .purple
        default:        return .gray
        }
    }
}

#Preview {
    NavigationStack { WeatherView() }
}
