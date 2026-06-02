import Foundation

// Open-Meteo 免費 API，台中科大座標
private let apiURLString = "https://api.open-meteo.com/v1/forecast?latitude=24.1493&longitude=120.6836&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,weather_code&timezone=Asia%2FTaipei&forecast_days=1"

public actor WeatherFetchService {
    public static let shared = WeatherFetchService()

    public func fetch() async throws -> SharedWeatherData {
        guard let url = URL(string: apiURLString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parse(data)
    }

    private func parse(_ data: Data) throws -> SharedWeatherData {
        let json = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)

        var temps: [Double] = []
        var codes: [Int]   = []
        var hours: [Int]   = []

        for (i, timeStr) in json.hourly.time.enumerated() {
            guard let hourPart = timeStr.split(separator: "T").last,
                  let hour = Int(hourPart.prefix(2)),
                  hour >= currentHour,
                  temps.count < 6
            else { continue }
            temps.append(json.hourly.temperature2m[i])
            codes.append(json.hourly.weatherCode[i])
            hours.append(hour)
        }

        let w = SharedWeatherData(
            temperature:          json.current.temperature2m,
            apparentTemperature:  json.current.apparentTemperature,
            humidity:             json.current.relativeHumidity2m,
            windSpeed:            json.current.windSpeed10m,
            weatherCode:          json.current.weatherCode,
            fetchedAt:            now,
            hourlyTemps:          temps,
            hourlyCodes:          codes,
            hourlyHours:          hours
        )
        SharedWeatherCache.save(w)
        return w
    }
}

// MARK: - Response models (private)

private struct OpenMeteoResponse: Decodable {
    let current: Current
    let hourly: Hourly

    struct Current: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let relativeHumidity2m: Int
        let windSpeed10m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m       = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case relativeHumidity2m  = "relative_humidity_2m"
            case windSpeed10m        = "wind_speed_10m"
            case weatherCode         = "weather_code"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode   = "weather_code"
        }
    }
}
