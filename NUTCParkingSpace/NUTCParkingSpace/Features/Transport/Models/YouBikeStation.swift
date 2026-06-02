import Foundation
import CoreLocation

struct YouBikeStation: Identifiable {
    let id: String
    let name: String
    let address: String
    let district: String
    let availableBikes: Int
    let emptyDocks: Int
    let totalDocks: Int
    let isActive: Bool
    let coordinate: CLLocationCoordinate2D
    var distance: Double = 0   // 公尺，顯示前填入

    var occupancyRatio: Double {
        totalDocks > 0 ? Double(availableBikes) / Double(totalDocks) : 0
    }
}

// MARK: - Taichung YouBike API response

struct TaichungYouBikeResponse: Decodable {
    let result: ResultWrapper?
    let data: [RawStation]?

    // Taichung data center wraps in result.records
    struct ResultWrapper: Decodable {
        let records: [RawStation]?
    }
}

struct RawStation: Decodable {
    let sno: String?
    let sna: StringOrDouble?
    let ar:  StringOrDouble?
    let sarea: StringOrDouble?
    let lat: StringOrDouble?
    let lng: StringOrDouble?
    let sbi: StringOrDouble?
    let bemp: StringOrDouble?
    let tot: StringOrDouble?
    let act: StringOrDouble?

    func toStation() -> YouBikeStation? {
        guard let id   = sno,
              let name = sna?.stringValue, !name.isEmpty,
              let latV = lat?.doubleValue,
              let lngV = lng?.doubleValue
        else { return nil }
        return YouBikeStation(
            id: id,
            name: name,
            address: ar?.stringValue ?? "",
            district: sarea?.stringValue ?? "",
            availableBikes: Int(sbi?.doubleValue ?? 0),
            emptyDocks: Int(bemp?.doubleValue ?? 0),
            totalDocks: Int(tot?.doubleValue ?? 0),
            isActive: act?.stringValue != "0",
            coordinate: CLLocationCoordinate2D(latitude: latV, longitude: lngV)
        )
    }
}

// Handles fields that can be either JSON string or JSON number
enum StringOrDouble: Decodable {
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let d = try? container.decode(Double.self) { self = .double(d); return }
        if let s = try? container.decode(String.self)  { self = .string(s); return }
        self = .string("")
    }

    var stringValue: String {
        switch self {
        case .string(let s): return s
        case .double(let d): return d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(d)
        }
    }

    var doubleValue: Double {
        switch self {
        case .string(let s): return Double(s) ?? 0
        case .double(let d): return d
        }
    }
}
