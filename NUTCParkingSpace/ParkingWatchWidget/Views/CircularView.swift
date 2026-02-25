import SwiftUI
import WidgetKit
import NUTCParkingShared

struct CircularView: View {
    let entry: WatchParkingEntry
    
    var body: some View {
        let totalAvailable = entry.parkingLots.reduce(0) { $0 + $1.availableCount }
        let totalCapacity = entry.parkingLots.reduce(0) { $0 + $1.totalCapacity }
        
        Gauge(value: Double(totalAvailable), in: 0...Double(max(totalCapacity, 1))) {
            Image(systemName: "motorcycle.fill")
        } currentValueLabel: {
            Text("\(totalAvailable)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}
