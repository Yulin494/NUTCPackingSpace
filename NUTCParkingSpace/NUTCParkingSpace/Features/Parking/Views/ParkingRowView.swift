import SwiftUI

struct ParkingRowView: View {
    let parkingLot: ParkingLot
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(parkingLot.name)
                        .font(.headline)
                    Text("更新時間：\(parkingLot.lastUpdated.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_Hant_TW"))))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(parkingLot.availableCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                        if parkingLot.totalCapacity > 0 {
                            Text("/ \(parkingLot.totalCapacity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text("剩餘車位")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // 剩餘比例條（有總量資料時才顯示）
            if parkingLot.totalCapacity > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(statusColor)
                            .frame(width: max(4, geo.size.width * availabilityPercentage))
                    }
                }
                .frame(height: 5)
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
