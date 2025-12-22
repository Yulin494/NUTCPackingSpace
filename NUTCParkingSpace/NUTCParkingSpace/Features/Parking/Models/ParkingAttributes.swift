import ActivityKit
import Foundation

struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 動態狀態屬性 (會隨時間更新)
        var availableCount: Int
        var totalCapacity: Int
        var lastUpdated: Date
    }

    // 固定屬性 (不會改變)
    var parkingName: String
}
