
import ActivityKit
import WidgetKit
import SwiftUI

import NUTCParkingShared

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
                    // Show total available
                    let total = context.state.lots.reduce(0) { $0 + $1.available }
                    Text("\(total)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.caption)
                        .lineLimit(1)
                }   
                DynamicIslandExpandedRegion(.bottom) {
                    // Show a mini list or summary
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(context.state.lots.prefix(3)), id: \.self) { lot in
                            HStack {
                                Text(lot.name)
                                    .font(.caption2)
                                Spacer()
                                Text("\(lot.available)位")
                                    .font(.caption2)
                                    .foregroundStyle(lot.available > 0 ? .green : .red)
                            }
                        }
                        if context.state.lots.count > 3 {
                            Text("還有 \(context.state.lots.count - 3) 個...")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("最後更新: \(context.state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            } compactLeading: {
                Image(systemName: "bicycle")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                let total = context.state.lots.reduce(0) { $0 + $1.available }
                Text("\(total)")
                    .fontWeight(.bold)
                    .foregroundStyle(total > 0 ? .green : .red)
            } minimal: {
                let total = context.state.lots.reduce(0) { $0 + $1.available }
                Text("\(total)")
                    .font(.caption2)
            }
        }
    }
}

struct ParkingLiveActivityLockScreenView: View {
    let context: ActivityViewContext<ParkingAttributes>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if context.state.lots.count == 1, let lot = context.state.lots.first {
                // Single Lot View (Original Large Style)
                HStack(alignment: .top, spacing: 15) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(lot.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("最後更新: \(context.state.lastUpdated.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(lot.available)")
                                .font(.system(size: 60, weight: .heavy))
                                .foregroundStyle(lot.available > 0 ? Color.green : Color.red)
                        }
                        
                        // 滿載率與時間底部資訊
                        OccupancyBarView(
                            available: lot.available,
                            total: lot.total,
                            lastUpdated: context.state.lastUpdated
                        )
                    }
                }
                .padding()
                .activityBackgroundTint(Color(UIColor.systemBackground))
                .activitySystemActionForegroundColor(Color.primary)
            } else {
                // Grid View (Compact Style for Multiple Lots)
                VStack(spacing: 0) {
                    // Grid Layout (Manual 2 columns)
                    let lots = Array(context.state.lots.prefix(4))
                    let firstColumn = lots.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
                    let secondColumn = lots.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
                    
                    HStack(alignment: .top, spacing: 8) {
                        VStack(spacing: 8) {
                            ForEach(firstColumn, id: \.self) { lot in
                                ParkingGridItem(lot: lot)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 8) {
                            ForEach(secondColumn, id: \.self) { lot in
                                ParkingGridItem(lot: lot)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                }
                .padding()
                .activityBackgroundTint(Color(UIColor.secondarySystemBackground))
                .activitySystemActionForegroundColor(Color.primary)
            }
        }
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
    
        }
    }
}

private struct ParkingGridItem: View {
    let lot: LiteLot
    
    var occupancyRate: Double {
        guard lot.total > 0 else { return 0 }
        return 1.0 - (Double(lot.available) / Double(lot.total))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(lot.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(lot.available)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(lot.available > 0 ? .green : .red)
                    .contentTransition(.numericText(value: Double(lot.available)))
                
                Spacer()
                
                // Progress Circle (Mini)
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 2.5)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(occupancyRate))
                        .stroke(
                            occupancyRate > 0.9 ? .red : (occupancyRate > 0.7 ? .orange : .green),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 14, height: 14)
            }
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
