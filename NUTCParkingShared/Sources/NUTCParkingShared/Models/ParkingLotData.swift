import Foundation

public enum ParkingType: String, Codable, CaseIterable, Sendable {
    case motorcycle = "機車停車場"
    case car = "汽車停車場"
}

public struct ParkingLotData: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let totalCapacity: Int
    public let availableCount: Int
    public let latitude: Double
    public let longitude: Double
    public let lastUpdated: Date
    public let type: ParkingType
    
    public init(id: UUID = UUID(), name: String, totalCapacity: Int, availableCount: Int,
                latitude: Double, longitude: Double,
                lastUpdated: Date, type: ParkingType) {
        self.id = id
        self.name = name
        self.totalCapacity = totalCapacity
        self.availableCount = availableCount
        self.latitude = latitude
        self.longitude = longitude
        self.lastUpdated = lastUpdated
        self.type = type
    }
}
