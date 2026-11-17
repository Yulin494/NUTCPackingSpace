//
//  PixelWeatherView.swift
//  NUTCParkingSpace
//
//  像素模式天氣頁。資料來源與載入流程沿用 WeatherView。
//

import SwiftUI
import NUTCParkingShared

// MARK: - 天氣像素圖示（12x12，僅供本檔使用）

private enum WeatherGlyph {
    case sun, cloud, rain, snow, storm, fog

    init(code: Int) {
        switch code {
        case 0, 1:      self = .sun
        case 2, 3:      self = .cloud
        case 45, 48:    self = .fog
        case 51...67, 80...82: self = .rain
        case 71...77, 85, 86:  self = .snow
        case 95...99:   self = .storm
        default:        self = .cloud
        }
    }

    var label: String {
        switch self {
        case .sun: return "晴"
        case .cloud: return "多雲"
        case .rain: return "雨"
        case .snow: return "雪"
        case .storm: return "雷雨"
        case .fog: return "霧"
        }
    }

    var color: Color {
        switch self {
        case .sun: return PixelPalette.gold
        case .cloud, .fog: return PixelPalette.muted
        case .rain: return PixelPalette.blue
        case .snow: return PixelPalette.teal
        case .storm: return PixelPalette.orange
        }
    }

    var bitmap: [String] {
        switch self {
        case .sun:
            return [
                ".....XX.....",
                "..X..XX..X..",
                "...X....X...",
                "....XXXX....",
                "X..XXXXXX..X",
                "XX.XXXXXX.XX",
                "...XXXXXX...",
                "X..XXXXXX..X",
                "....XXXX....",
                "...X....X...",
                "..X..XX..X..",
                ".....XX.....",
            ]
        case .cloud:
            return [
                "............",
                "............",
                "....XXX.....",
                "...XXXXX.XX.",
                "..XXXXXXXXXX",
                ".XXXXXXXXXXX",
                "XXXXXXXXXXXX",
                "XXXXXXXXXXXX",
                ".XXXXXXXXXX.",
                "............",
                "............",
                "............",
            ]
        case .rain:
            return [
                "....XXX.....",
                "...XXXXX.XX.",
                "..XXXXXXXXXX",
                ".XXXXXXXXXXX",
                "XXXXXXXXXXXX",
                ".XXXXXXXXXX.",
                "............",
                "..X...X...X.",
                ".X...X...X..",
                "..X...X...X.",
                ".X...X...X..",
                "............",
            ]
        case .snow:
            return [
                "....XXX.....",
                "...XXXXX.XX.",
                "..XXXXXXXXXX",
                ".XXXXXXXXXXX",
                "XXXXXXXXXXXX",
                ".XXXXXXXXXX.",
                "............",
                "..X...X...X.",
                ".XXX.XXX.XXX",
                "..X...X...X.",
                "............",
                "............",
            ]
        case .storm:
            return [
                "....XXX.....",
                "...XXXXX.XX.",
                "..XXXXXXXXXX",
                ".XXXXXXXXXXX",
                ".XXXXXXXXXX.",
                "......XX....",
                ".....XX.....",
                "....XXXX....",
                ".....XX.....",
                "....XX......",
                "............",
                "............",
            ]
        case .fog:
            return [
                "............",
                "..XXXXXXX...",
                ".XXXXXXXXXX.",
                "............",
                "XXXXXXXXX...",
                "...XXXXXXXXX",
                "............",
                ".XXXXXXXXXX.",
                "..XXXXXXX...",
                "............",
                "............",
                "............",
            ]
        }
    }
}

private struct WeatherGlyphView: View {
    let glyph: WeatherGlyph
    var scale: CGFloat = 2

    var body: some View {
        let cell = max(scale.rounded(), 1)
        Canvas { context, _ in
            for (y, row) in glyph.bitmap.enumerated() {
                for (x, ch) in row.enumerated() where ch == "X" {
                    let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)
                    context.fill(Path(rect), with: .color(glyph.color))
                }
            }
        }
        .frame(width: 12 * cell, height: 12 * cell)
        .accessibilityHidden(true)
    }
}

// MARK: - 頁面

struct PixelWeatherView: View {
    @State private var weather: SharedWeatherData?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            if isLoading && weather == nil {
                statusCard(title: "載入天氣中", message: "請稍候", showRetry: false)
            } else if let err = error, weather == nil {
                statusCard(title: "無法載入天氣", message: err, showRetry: true)
            } else if let w = weather {
                VStack(spacing: 20) {
                    currentCard(w)
                    detailRow(w)
                    hourlyCard(w)
                }
                .padding(16)
            }
        }
        .foregroundStyle(PixelPalette.ink)
        .background(PixelPalette.paper2.ignoresSafeArea())
        .navigationTitle("台中天氣")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("台中天氣").pixelFont(size: PixelMetrics.FontSize.medium)
                    .foregroundStyle(PixelPalette.ink)
                    .accessibilityHidden(true)
            }
            if let w = weather {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(w.fetchedAt, style: .time)
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.muted)
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: 狀態

    private func statusCard(title: String, message: String, showRetry: Bool) -> some View {
        VStack(spacing: 16) {
            NamePlate(text: title, fill: showRetry ? PixelPalette.red : PixelPalette.ink)
            PixelIcon(kind: showRetry ? .alert : .cloud, scale: 4, color: showRetry ? PixelPalette.red : PixelPalette.muted)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
                .multilineTextAlignment(.center)
            if showRetry {
                Button { Task { await load() } } label: {
                    Text("重試").pixelFont(size: PixelMetrics.FontSize.medium)
                        .frame(minWidth: 96, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .pixelFrame()
        .padding(16)
        .accessibilityElement(children: .combine)
    }

    // MARK: 目前天氣

    private func currentCard(_ w: SharedWeatherData) -> some View {
        let glyph = WeatherGlyph(code: w.weatherCode)
        return VStack(spacing: 12) {
            NamePlate(text: "目前天氣")
            WeatherGlyphView(glyph: glyph, scale: 8)
            Text("\(Int(w.temperature.rounded()))°C")
                .pixelFont(size: PixelMetrics.FontSize.xlarge)
            Text(w.description)
                .font(.system(size: 17))
            Text("體感 \(Int(w.apparentTemperature.rounded()))°C")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .pixelFrame(fill: PixelPalette.water)
        .accessibilityElement(children: .combine)
    }

    // MARK: 數值格

    private func detailRow(_ w: SharedWeatherData) -> some View {
        HStack(spacing: 8) {
            cell(label: "濕度", value: "\(w.humidity)%")
            cell(label: "風速", value: String(format: "%.1f", w.windSpeed), unit: "km/h")
            cell(label: "位置", value: "台中市")
        }
    }

    private func cell(label: String, value: String, unit: String? = nil) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 15)).foregroundStyle(PixelPalette.muted)
            Text(value).pixelFont(size: PixelMetrics.FontSize.medium).minimumScaleFactor(0.6).lineLimit(1)
            Text(unit ?? " ").font(.system(size: 15)).foregroundStyle(PixelPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .pixelFrame()
        .accessibilityElement(children: .combine)
    }

    // MARK: 逐時預報

    private func hourlyCard(_ w: SharedWeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NamePlate(text: "今日逐時預報")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(zip(w.hourlyHours.indices, w.hourlyHours)), id: \.0) { i, hour in
                        let g = WeatherGlyph(code: w.hourlyCodes[i])
                        VStack(spacing: 6) {
                            Text(String(format: "%02d:00", hour))
                                .font(.system(size: 15))
                                .foregroundStyle(PixelPalette.muted)
                            WeatherGlyphView(glyph: g, scale: 2)
                            Text("\(Int(w.hourlyTemps[i].rounded()))°")
                                .pixelFont(size: PixelMetrics.FontSize.medium)
                        }
                        .frame(width: 64)
                        .padding(.vertical, 8)
                        .pixelFrame(fill: PixelPalette.paper)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(hour) 點，\(g.label)，\(Int(w.hourlyTemps[i].rounded())) 度")
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(12)
        .pixelFrame(fill: PixelPalette.paper)
    }

    // MARK: 載入

    private func load() async {
        isLoading = true
        error = nil
        do {
            weather = try await WeatherFetchService.shared.fetch()
        } catch {
            self.error = error.localizedDescription
            weather = SharedWeatherCache.load()
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack { PixelWeatherView() }
}
