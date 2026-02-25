import SwiftUI
import NUTCParkingShared

struct WatchParkingRow: View {
    let lot: ParkingLotData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lot.name)
                .font(.headline)
            
            HStack {
                Text(lot.type == .motorcycle ? "機車" : "汽車")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(lot.type == .motorcycle ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Text("剩餘: \(lot.availableCount)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        if lot.availableCount > 50 {
            return .green
        } else if lot.availableCount > 10 {
            return .yellow
        } else {
            return .red
        }
    }
}
