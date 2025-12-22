import Foundation
import CoreLocation

struct ParkingLot: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let availableCount: Int
    let coordinate: CLLocationCoordinate2D
    let lastUpdated: Date
    
    // Equatable implementation for coordinate comparison
    static func == (lhs: ParkingLot, rhs: ParkingLot) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.availableCount == rhs.availableCount &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.lastUpdated == rhs.lastUpdated
    }
}
