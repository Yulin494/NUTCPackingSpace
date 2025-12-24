import Foundation
import Combine

class ParkingListViewModel: ObservableObject {
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let dataService = ParkingDataService.shared
    private var timer: Timer?
    
    init() {
        addSubscribers()
    }
    
    deinit {
        stopAutoRefresh()
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
    
    func fetchParkingData(completion: (() -> Void)? = nil) {
        dataService.fetchParkingData { _ in
            completion?()
        }
    }
    
    func startAutoRefresh() {
        // Fetch immediately
        fetchParkingData()
        
        // Invalidate existing timer if any
        stopAutoRefresh()
        
        // Schedule new timer for every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fetchParkingData()
        }
    }
    
    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}
