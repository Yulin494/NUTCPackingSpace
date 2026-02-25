import ActivityKit
import Foundation
import NUTCParkingShared

public struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 動態狀態屬性 (會隨時間更新)
        public var lots: [LiteLot]
        public var lastUpdated: Date
        
        public init(lots: [LiteLot], lastUpdated: Date) {
            self.lots = lots
            self.lastUpdated = lastUpdated
        }
    }

    // 固定屬性 (不會改變)
    public var title: String
    
    public init(title: String) {
        self.title = title
    }
}
