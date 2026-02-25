import SwiftUI
import WidgetKit

struct WatchWidgetEntryView: View {
    var entry: WatchParkingEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            Text("不支援")
        }
    }
}
