import Foundation
import Combine

class ParkingListViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = ParkingDataService.shared
    
    init() {
        addSubscribers()
    }
    
    func addSubscribers() {
        dataService.$parkingLots
            .receive(on: DispatchQueue.main)
            .assign(to: \.parkingLots, on: self)
            .store(in: &cancellables)
            
        dataService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
            
        dataService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    func fetchParkingData() {
        dataService.fetchParkingData()
    }
}
