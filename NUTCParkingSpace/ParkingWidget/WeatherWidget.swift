import WidgetKit
import SwiftUI
import NUTCParkingShared

// MARK: - Entry

struct WeatherEntry: TimelineEntry {
    let date: Date
    let weather: SharedWeatherData?
}

// MARK: - Provider

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), weather: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        let cached = SharedWeatherCache.load()
        completion(WeatherEntry(date: Date(), weather: cached))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let weather = try? await WeatherFetchService.shared.fetch()
            let entry = WeatherEntry(date: Date(), weather: weather ?? SharedWeatherCache.load())
            // 每 30 分鐘更新一次
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - Views

struct WeatherWidgetView: View {
    var entry: WeatherEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let w = entry.weather {
            switch family {
            case .accessoryRectangular: lockView(w)
            case .systemSmall:          smallView(w)
            default:                    mediumView(w)
            }
        } else {
            Label("台中天氣", systemImage: "cloud.fill")
                .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        }
    }

    // 鎖定畫面
    private func lockView(_ w: SharedWeatherData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: w.symbolName)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(Int(w.temperature.rounded()))°C")
                    .font(.system(size: 16, weight: .bold))
                Text(w.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    // Small
    private func smallView(_ w: SharedWeatherData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("台中", systemImage: "location.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            Image(systemName: w.symbolName)
                .font(.system(size: 32))
                .symbolRenderingMode(.multicolor)

            Text("\(Int(w.temperature.rounded()))°C")
                .font(.system(size: 28, weight: .thin, design: .rounded))

            Text(w.description)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }

    // Medium
    private func mediumView(_ w: SharedWeatherData) -> some View {
        HStack(spacing: 0) {
            // 左：當前天氣
            VStack(alignment: .leading, spacing: 4) {
                Label("台中天氣", systemImage: "location.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: w.symbolName)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.multicolor)
                Text("\(Int(w.temperature.rounded()))°C")
                    .font(.system(size: 30, weight: .thin, design: .rounded))
                Text(w.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("體感 \(Int(w.apparentTemperature.rounded()))°C  濕度 \(w.humidity)%")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.vertical, 4)

            // 右：逐時
            VStack(spacing: 6) {
                ForEach(Array(zip(w.hourlyHours.prefix(3).indices, w.hourlyHours.prefix(3))), id: \.0) { i, hour in
                    HStack {
                        Text(String(format: "%02d:00", hour))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: SharedWeatherData.weatherSymbol(for: w.hourlyCodes[i]))
                            .font(.system(size: 11))
                            .symbolRenderingMode(.multicolor)
                        Text("\(Int(w.hourlyTemps[i].rounded()))°")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 10)
        }
        .padding(14)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }
}

// MARK: - Widget

struct WeatherWidget: Widget {
    let kind = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("台中天氣")
        .description("顯示台中科大附近的即時天氣與逐時預報。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
