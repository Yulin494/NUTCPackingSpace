import Foundation
import CoreLocation
import Combine
import NUTCParkingShared

class ParkingDataService: ObservableObject {
    static let shared = ParkingDataService()
    
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let campusCenter = CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974)
    
    // Convert async call to completion handler for compatibility with existing code
    func fetchParkingData(completion: (([ParkingLot]) -> Void)? = nil) {
        // Set loading state on main thread
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
        }
        
        Task {
            do {
                let sharedLots = try await ParkingFetchService.shared.fetchParkingData()
                
                // Cache the data for Widget/Watch
                SharedParkingCache.save(sharedLots)
                
                let iosLots = sharedLots.map { ParkingLot(data: $0) }
                
                await MainActor.run {
                    self.parkingLots = iosLots
                    self.isLoading = false
                    completion?(iosLots)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "連線失敗: \(error.localizedDescription)"
                    completion?(self.parkingLots)
                }
            }
        }
    }
}
