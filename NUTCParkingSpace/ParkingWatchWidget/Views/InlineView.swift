import SwiftUI
import WidgetKit
import NUTCParkingShared

struct InlineView: View {
    let entry: WatchParkingEntry
    
    var body: some View {
        let totalAvailable = entry.parkingLots
            .filter { $0.type == .motorcycle }
            .reduce(0) { $0 + $1.availableCount }
        
        Text("🏍️ 剩餘 \(totalAvailable) 個機車位")
    }
}
