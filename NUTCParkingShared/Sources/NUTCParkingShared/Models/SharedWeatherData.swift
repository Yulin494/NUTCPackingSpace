import Foundation

public struct SharedWeatherData: Codable {
    public let temperature: Double
    public let apparentTemperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let weatherCode: Int
    public let fetchedAt: Date
    public let hourlyTemps: [Double]   // 接下來 6 小時
    public let hourlyCodes: [Int]
    public let hourlyHours: [Int]      // 0-23

    public init(
        temperature: Double, apparentTemperature: Double,
        humidity: Int, windSpeed: Double, weatherCode: Int,
        fetchedAt: Date,
        hourlyTemps: [Double], hourlyCodes: [Int], hourlyHours: [Int]
    ) {
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.weatherCode = weatherCode
        self.fetchedAt = fetchedAt
        self.hourlyTemps = hourlyTemps
        self.hourlyCodes = hourlyCodes
        self.hourlyHours = hourlyHours
    }

    public var description: String { Self.weatherDescription(for: weatherCode) }
    public var symbolName: String  { Self.weatherSymbol(for: weatherCode) }

    public static func weatherDescription(for code: Int) -> String {
        switch code {
        case 0:       return "晴天"
        case 1:       return "大致晴朗"
        case 2:       return "局部多雲"
        case 3:       return "陰天"
        case 45, 48:  return "霧"
        case 51, 53:  return "毛毛雨"
        case 55:      return "濃毛毛雨"
        case 61, 63:  return "降雨"
        case 65:      return "大雨"
        case 71, 73:  return "降雪"
        case 75:      return "大雪"
        case 80, 81:  return "陣雨"
        case 82:      return "強陣雨"
        case 95:      return "雷暴"
        case 96, 99:  return "冰雹雷暴"
        default:      return "多雲"
        }
    }

    public static func weatherSymbol(for code: Int) -> String {
        switch code {
        case 0:        return "sun.max.fill"
        case 1:        return "sun.haze.fill"
        case 2:        return "cloud.sun.fill"
        case 3:        return "cloud.fill"
        case 45, 48:   return "cloud.fog.fill"
        case 51...55:  return "cloud.drizzle.fill"
        case 61...65:  return "cloud.rain.fill"
        case 71...77:  return "cloud.snow.fill"
        case 80...82:  return "cloud.heavyrain.fill"
        case 85, 86:   return "cloud.snow.fill"
        case 95...99:  return "cloud.bolt.rain.fill"
        default:       return "cloud.fill"
        }
    }
}

public struct SharedWeatherCache {
    private static let suiteName = "group.com.yulin494.NUTCParkingSpace"
    private static let key = "sharedWeather"

    public static func save(_ data: SharedWeatherData) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data)
        else { return }
        defaults.set(encoded, forKey: key)
    }

    public static func load() -> SharedWeatherData? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: key),
              let weather = try? JSONDecoder().decode(SharedWeatherData.self, from: data)
        else { return nil }
        return weather
    }
}
