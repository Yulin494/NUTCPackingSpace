import SwiftUI
import WidgetKit
import NUTCParkingShared

struct RectangularView: View {
    let entry: WatchParkingEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "motorcycle.fill")
                    .font(.system(size: 9))
                Text("校園車位")
                    .font(.system(size: 9, weight: .bold))
            }
            ForEach(entry.parkingLots.prefix(4)) { lot in
                HStack {
                    Text(lot.name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Spacer()
                    Text("\(lot.availableCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(lot.availableCount > 10 ? .green : .red)
                }
            }
        }
    }
}
