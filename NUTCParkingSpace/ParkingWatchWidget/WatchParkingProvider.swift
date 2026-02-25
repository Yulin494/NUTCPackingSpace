import WidgetKit
import NUTCParkingShared
import Foundation

struct WatchParkingProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> WatchParkingEntry {
        WatchParkingEntry(date: Date(), parkingLots: Self.placeholderLots(), error: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchParkingEntry) -> Void) {
        let cached = SharedParkingCache.load()
        let entry = WatchParkingEntry(date: Date(), parkingLots: cached ?? Self.placeholderLots(), error: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchParkingEntry>) -> Void) {
        Task {
            do {
                let lots = try await ParkingFetchService.shared.fetchParkingData()
                let entry = WatchParkingEntry(date: Date(), parkingLots: lots, error: nil)
                
                // Refresh every 15 minutes to save battery
                let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                
                SharedParkingCache.save(lots)
                
                completion(timeline)
            } catch {
                let entry = WatchParkingEntry(date: Date(), parkingLots: [], error: "無法取得資料")
                let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }
    
    static func placeholderLots() -> [ParkingLotData] {
        [
            ParkingLotData(name: "三民校區", totalCapacity: 500, availableCount: 120, latitude: 24.149691, longitude: 120.683974, lastUpdated: Date(), type: .motorcycle),
            ParkingLotData(name: "民生校區", totalCapacity: 300, availableCount: 50, latitude: 24.149691, longitude: 120.683974, lastUpdated: Date(), type: .motorcycle)
        ]
    }
}
