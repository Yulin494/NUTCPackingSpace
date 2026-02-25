import Foundation

public struct SharedParkingCache {
    // App Group ID needs to be configured in Xcode Capabilities
    private static let suiteName = "group.com.yulin494.NUTCParkingSpace"
    private static let cacheKey = "cachedParkingLots"
    private static let lastUpdateKey = "lastCacheUpdate"
    
    public static func save(_ lots: [ParkingLotData]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let data = try? JSONEncoder().encode(lots) {
            defaults.set(data, forKey: cacheKey)
            defaults.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    public static func load() -> [ParkingLotData]? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: cacheKey),
              let lots = try? JSONDecoder().decode([ParkingLotData].self, from: data)
        else { return nil }
        return lots
    }
    
    public static var lastUpdateDate: Date? {
        UserDefaults(suiteName: suiteName)?.object(forKey: lastUpdateKey) as? Date
    }
}
