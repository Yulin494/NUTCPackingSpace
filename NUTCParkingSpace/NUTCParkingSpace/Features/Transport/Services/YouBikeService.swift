import Foundation
import CoreLocation

actor YouBikeService {
    static let shared = YouBikeService()

    // 台中市 YouBike 開放資料
    private let apiURL = URL(string: "https://newdatacenter.taichung.gov.tw/api/v1/no-auth/resource.download?rid=a378bb83-a019-4b7b-bc05-d4d55f97ff9e")!

    // NUTC 台中科技大學座標（三民路四段129號）
    static let nutcCoordinate = CLLocationCoordinate2D(latitude: 24.1493, longitude: 120.6836)

    func fetchNearby(radiusMeters: Double = 1500) async throws -> [YouBikeStation] {
        let (data, _) = try await URLSession.shared.data(from: apiURL)

        var rawStations: [RawStation] = []

        // 嘗試兩種格式
        if let wrapped = try? JSONDecoder().decode(TaichungYouBikeResponse.self, from: data) {
            rawStations = wrapped.result?.records ?? wrapped.data ?? []
        }
        if rawStations.isEmpty {
            rawStations = (try? JSONDecoder().decode([RawStation].self, from: data)) ?? []
        }

        let nutc = CLLocation(latitude: Self.nutcCoordinate.latitude,
                              longitude: Self.nutcCoordinate.longitude)

        var result: [YouBikeStation] = []
        for raw in rawStations {
            guard var station = raw.toStation(), station.isActive else { continue }
            let loc = CLLocation(latitude: station.coordinate.latitude,
                                 longitude: station.coordinate.longitude)
            let dist = loc.distance(from: nutc)
            guard dist <= radiusMeters else { continue }
            station.distance = dist
            result.append(station)
        }
        return result.sorted { $0.distance < $1.distance }
    }
}
