import Foundation
import CoreLocation
import NUTCParkingShared

// Re-export ParkingType so other files don't need to change
typealias ParkingType = NUTCParkingShared.ParkingType

// Make ParkingLot conform to Codable manually since CLLocationCoordinate2D is not Codable by default
struct ParkingLot: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let totalCapacity: Int
    let availableCount: Int
    // Store coordinate components for Codable conformance
    private let latitude: Double
    private let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    let lastUpdated: Date
    let type: ParkingType
    
    // Initializer to adapt Shared Model
    init(data: ParkingLotData) {
        self.id = data.id
        self.name = data.name
        self.totalCapacity = data.totalCapacity
        self.availableCount = data.availableCount
        self.latitude = data.latitude
        self.longitude = data.longitude
        self.lastUpdated = data.lastUpdated
        self.type = data.type
    }
    
    // Original Initializer for compatibility
    init(name: String, totalCapacity: Int, availableCount: Int, coordinate: CLLocationCoordinate2D, lastUpdated: Date, type: ParkingType) {
        self.id = UUID()
        self.name = name
        self.totalCapacity = totalCapacity
        self.availableCount = availableCount
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.lastUpdated = lastUpdated
        self.type = type
    }
    
    // Equatable implementation
    static func == (lhs: ParkingLot, rhs: ParkingLot) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.availableCount == rhs.availableCount &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.lastUpdated == rhs.lastUpdated &&
               lhs.type == rhs.type
    }
}
