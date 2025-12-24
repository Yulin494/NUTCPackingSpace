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
                    .foregroundColor(statusColor)
                
                Text("剩餘車位")
                    .font(.caption2)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                HapticManager.shared.impact(style: .medium)
                CommuteManager.shared.startCommuting(for: parkingLot)
            } label: {
                Label("開始通勤監控", systemImage: "motorcycle.fill")
            }
        }
    }
    
    // 計算剩餘百分比
    private var availabilityPercentage: Double {
        guard parkingLot.totalCapacity > 0 else { return 0 }
        return Double(parkingLot.availableCount) / Double(parkingLot.totalCapacity)
    }
    
    // 判斷狀態顏色
    private var statusColor: Color {
        // 如果沒有總量數據，就用絕對數值判斷 (假設少於10個算少)
        if parkingLot.totalCapacity == 0 {
            return parkingLot.availableCount > 10 ? .green : .red
        }
        
        let percentage = availabilityPercentage
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.2 {
            return .orange
        } else {
            return .red
        }
    }
}
