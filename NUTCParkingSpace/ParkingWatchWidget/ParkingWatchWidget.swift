import WidgetKit
import SwiftUI
import NUTCParkingShared

struct ParkingWatchWidget: Widget {
    let kind: String = "ParkingWatchWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchParkingProvider()) { entry in
            WatchWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("校園停車位")
        .description("即時查看校園各停車場剩餘車位")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

#Preview(as: .accessoryRectangular) {
    ParkingWatchWidget()
} timeline: {
    WatchParkingEntry(date: .now, parkingLots: [], error: nil)
    WatchParkingEntry(date: .now, parkingLots: [], error: "無法連線")
}
