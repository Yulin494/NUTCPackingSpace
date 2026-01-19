import ActivityKit
import Foundation

struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 動態狀態屬性 (會隨時間更新)
        var lots: [LiteLot]
        var lastUpdated: Date
    }

    public struct LiteLot: Codable, Hashable {
        var name: String
        var available: Int
        var total: Int
    }

    // 固定屬性 (不會改變)
    var title: String
}
