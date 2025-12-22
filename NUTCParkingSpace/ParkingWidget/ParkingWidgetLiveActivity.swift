
import ActivityKit
import WidgetKit
import SwiftUI

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            // 鎖定畫面 / 橫幅 UI
            ParkingLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 動態島展開區域 UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "motorcycle.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .padding(.leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.availableCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.parkingName)
                        .font(.caption)
                        .lineLimit(1)
                }   
                DynamicIslandExpandedRegion(.bottom) {
                    Text("最後更新: \(context.state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)
                }
            } compactLeading: {
                Image(systemName: "bicycle")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text("\(context.state.availableCount)")
                    .fontWeight(.bold)
                    .foregroundStyle(context.state.availableCount > 0 ? .green : .red)
            } minimal: {
                Text("\(context.state.availableCount)")
                    .font(.caption2)
            }
        }
    }
}

struct ParkingLiveActivityLockScreenView: View {
    let context: ActivityViewContext<ParkingAttributes>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.parkingName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("最後更新: \(context.state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(context.state.availableCount)")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundStyle(context.state.availableCount > 0 ? Color.green : Color.red)
            }
            
            
            // 滿載率與時間底部資訊
            OccupancyBarView(
                available: context.state.availableCount,
                total: context.state.totalCapacity,
                lastUpdated: context.state.lastUpdated
            )
        }
        .padding()
        .activityBackgroundTint(Color(UIColor.systemBackground))
        .activitySystemActionForegroundColor(Color.primary)
    }
}

private struct OccupancyBarView: View {
    let available: Int
    let total: Int
    let lastUpdated: Date
    
    var occupancyRate: Double {
        guard total > 0 else { return 0 }
        return 1.0 - (Double(available) / Double(total))
    }
    
    var barColor: Color {
        if occupancyRate > 0.9 { return .red }
        if occupancyRate > 0.7 { return .orange }
        return .green
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    
                    Capsule()
                        .fill(barColor)
                        .frame(width: geometry.size.width * CGFloat(occupancyRate))
                        .animation(.spring, value: occupancyRate)
                }
            }
            .frame(height: 12)
            
            // 標籤
            HStack {
                Spacer()
                
                Text("滿載率: \(Int(occupancyRate * 100))% ・ \(lastUpdated, style: .relative)前更新")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
