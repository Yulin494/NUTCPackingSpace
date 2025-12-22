import SwiftUI

struct ParkingRowView: View {
    let parkingLot: ParkingLot
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(parkingLot.name)
                    .font(.headline)
                Text("更新時間: \(parkingLot.lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(parkingLot.availableCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(parkingLot.availableCount > 0 ? .green : .red)
                Text("剩餘車位")
                    .font(.caption2)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                CommuteManager.shared.startCommuting(for: parkingLot)
            } label: {
                Label("開始通勤監控", systemImage: "bicycle")
            }
        }
    }
}
