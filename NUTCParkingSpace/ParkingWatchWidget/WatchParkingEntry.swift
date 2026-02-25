import WidgetKit
import NUTCParkingShared
import Foundation

struct WatchParkingEntry: TimelineEntry {
    let date: Date
    let parkingLots: [ParkingLotData]
    let error: String?
}
