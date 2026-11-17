
import ActivityKit
import WidgetKit
import SwiftUI

import NUTCParkingShared

// MARK: - 共用輔助（標準與像素版共用）

extension Array where Element == LiteLot {
    /// 即時動態標題：依追蹤數量決定（1 個顯示名稱、多個顯示數量）
    var liveTitle: String {
        switch count {
        case 0: return "停車追蹤"
        case 1: return self[0].name
        default: return "追蹤 \(count) 個停車場"
        }
    }

    var totalAvailable: Int { reduce(0) { $0 + $1.available } }
}

extension LiteLot {
    /// 格狀精簡版用的短名稱：去掉「停車場」，最多 5 字
    var shortName: String {
        let trimmed = name.replacingOccurrences(of: "停車場", with: "")
        let base = trimmed.isEmpty ? name : trimmed
        return String(base.prefix(5))
    }
}

/// 標準樣式的三段狀態（圖示形狀 + 文字 + 顏色，不單靠顏色）
enum LiveLotStatus: Int, Comparable {
    case ok, low, full

    init(_ lot: LiteLot) {
        if lot.available <= 0 {
            self = .full
        } else if lot.total > 0, Double(lot.available) / Double(lot.total) <= 0.3 {
            self = .low
        } else {
            self = .ok
        }
    }

    static func < (a: LiveLotStatus, b: LiveLotStatus) -> Bool { a.rawValue < b.rawValue }

    /// 最緊張（最嚴重）的狀態；空陣列視為 ok
    static func worst(of lots: [LiteLot]) -> LiveLotStatus {
        lots.map(LiveLotStatus.init).max() ?? .ok
    }

    var color: Color {
        switch self {
        case .ok: return .green
        case .low: return .orange
        case .full: return .red
        }
    }

    var icon: String {
        switch self {
        case .ok: return "checkmark.circle.fill"
        case .low: return "exclamationmark.triangle.fill"
        case .full: return "xmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .ok: return "充足"
        case .low: return "緊張"
        case .full: return "已滿"
        }
    }
}

struct ParkingLiveActivity: Widget {
    /// 指定樣式（Preview 用）；nil 時讀取 App 同步到 App Group 的外觀設定
    var appearanceOverride: AppearanceStyle?

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            // 鎖定畫面 / 橫幅 UI（依 activityFamily 切換手錶版）
            ParkingLiveActivityContentView(context: context, appearanceOverride: appearanceOverride)
        } dynamicIsland: { context in
            let style = appearanceOverride ?? AppearanceStyle.fromAppGroup()
            let lots = context.state.lots
            return DynamicIsland {
                // 動態島展開區域 UI
                DynamicIslandExpandedRegion(.leading) {
                    if style == .pixel {
                        ParkingPixelIslandLeading(lots: lots)
                    } else {
                        Image(systemName: "motorcycle.fill")
                            .font(.title2)
                            .foregroundColor(.cyan)
                            .padding(.leading)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if style == .pixel {
                        ParkingPixelIslandTrailing(lots: lots)
                    } else {
                        // 總剩餘，顏色依最緊張的停車場
                        Text("\(lots.totalAvailable)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(LiveLotStatus.worst(of: lots).color)
                            .padding(.trailing)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if style == .pixel {
                        ParkingPixelIslandCenter(title: lots.liveTitle)
                    } else {
                        Text(lots.liveTitle)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if style == .pixel {
                        ParkingPixelIslandBottom(lots: lots, lastUpdated: context.state.lastUpdated)
                    } else {
                        ParkingIslandBottomView(lots: lots, lastUpdated: context.state.lastUpdated)
                    }
                }
            } compactLeading: {
                if style == .pixel {
                    ParkingPixelCompactLeading(lots: lots)
                } else if lots.count > 1 {
                    // 多個：顯示追蹤數量
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                        Text("\(lots.count)").fontWeight(.bold)
                    }
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                } else {
                    Image(systemName: "motorcycle.fill")
                        .foregroundStyle(.cyan)
                }
            } compactTrailing: {
                if style == .pixel {
                    ParkingPixelCompactTrailing(lots: lots)
                } else {
                    // 1 個：該場剩餘；多個：總剩餘。顏色取最緊張的狀態（總數會掩蓋某場已滿）
                    Text("\(lots.totalAvailable)")
                        .fontWeight(.bold)
                        .foregroundStyle(LiveLotStatus.worst(of: lots).color)
                }
            } minimal: {
                if style == .pixel {
                    ParkingPixelMinimal(lots: lots)
                } else {
                    Text("\(lots.totalAvailable)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(LiveLotStatus.worst(of: lots).color)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        // 讓 watchOS Smart Stack 使用專屬小卡，而非拼湊動態島
        .supplementalActivityFamilies([.small])
    }
}

/// 動態島 expanded 底部：1 個單行、2–3 個一列一個、4 個以上兩欄（最多 4 個 + 還有 N 個）
struct ParkingIslandBottomView: View {
    let lots: [LiteLot]
    let lastUpdated: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if lots.count <= 3 {
                ForEach(lots, id: \.self) { lot in
                    let status = LiveLotStatus(lot)
                    HStack(spacing: 6) {
                        Text(lot.name)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Image(systemName: status.icon)
                            .font(.caption2)
                        Text("\(lot.available)位")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(status.color)
                }
            } else {
                let shown = Array(lots.prefix(4))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 4) {
                    ForEach(shown, id: \.self) { lot in
                        let status = LiveLotStatus(lot)
                        HStack(spacing: 3) {
                            Text(lot.shortName)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                            Image(systemName: status.icon)
                                .font(.caption2)
                            Text("\(lot.available)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(status.color)
                    }
                }
            }
            HStack {
                if lots.count > 4 {
                    Text("還有 \(lots.count - 4) 個")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("最後更新: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

/// 依 activityFamily 決定顯示鎖定畫面版或手錶版
struct ParkingLiveActivityContentView: View {
    let context: ActivityViewContext<ParkingAttributes>
    /// 指定樣式（Preview 用）；nil 時讀取 App Group 的外觀設定
    var appearanceOverride: AppearanceStyle?
    @Environment(\.activityFamily) private var activityFamily

    var body: some View {
        let style = appearanceOverride ?? AppearanceStyle.fromAppGroup()
        switch activityFamily {
        case .small:
            if style == .pixel {
                ParkingLiveActivityWatchPixelView(context: context)
            } else {
                ParkingLiveActivityWatchView(context: context)
            }
        default:
            if style == .pixel {
                ParkingPixelLockScreenView(
                    lots: context.state.lots,
                    lastUpdated: context.state.lastUpdated
                )
            } else {
                ParkingLiveActivityLockScreenView(context: context)
            }
        }
    }
}

/// Apple Watch Smart Stack 小卡（只用系統文字樣式，隨字級縮放）
/// 1 個：大字；多個：最多 3 個精簡列（超過 3 個只列前 2 個 + 「＋N」）
struct ParkingLiveActivityWatchView: View {
    let context: ActivityViewContext<ParkingAttributes>

    var body: some View {
        let lots = context.state.lots

        if lots.isEmpty {
            Text("暫無資料")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if lots.count == 1, let lot = lots.first {
            let status = LiveLotStatus(lot)
            VStack(alignment: .leading, spacing: 2) {
                Text(lot.name)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(lot.available)")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(status.color)
                        .minimumScaleFactor(0.6)
                    Image(systemName: status.icon)
                        .font(.footnote)
                        .foregroundStyle(status.color)
                }
                Text("剩餘車位・\(status.label)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            let rows = lots.count <= 3 ? lots.count : 2
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.cyan)
                    Text("追蹤 \(lots.count) 個")
                        .lineLimit(1)
                    Spacer()
                    Text("\(lots.totalAvailable)")
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(LiveLotStatus.worst(of: lots).color)
                }
                .font(.footnote)

                ForEach(Array(lots.prefix(rows)), id: \.self) { lot in
                    let status = LiveLotStatus(lot)
                    HStack(spacing: 4) {
                        Image(systemName: status.icon)
                            .foregroundStyle(status.color)
                        Text(lot.shortName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text("\(lot.available)")
                            .monospacedDigit()
                            .foregroundStyle(status.color)
                    }
                    .font(.caption2)
                }
                if lots.count > rows {
                    Text("＋\(lots.count - rows)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// 鎖定畫面（高度上限約 160pt）：
/// 1 個大字；2–3 個一列一個（含細進度條）；4–8 個兩欄精簡格（>8 個顯示前 7 格 + 「還有 N 個」）
struct ParkingLiveActivityLockScreenView: View {
    let context: ActivityViewContext<ParkingAttributes>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let lots = context.state.lots
        Group {
            if lots.count == 1, let lot = lots.first {
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
            } else if lots.count <= 3 {
                // 2–3 個：一列一個（名稱、狀態、剩餘數、細進度條）。高度：3 列約 3×33 + 間距 16 + 內距 24 ≈ 140
                VStack(spacing: 8) {
                    ForEach(lots, id: \.self) { ParkingListRow(lot: $0) }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .activityBackgroundTint(Color(UIColor.systemBackground))
                .activitySystemActionForegroundColor(Color.primary)
            } else {
                // 4–8 個：兩欄精簡格。高度：4 列 × 28 + 間距 3×6 + 內距 24 ≈ 154
                let cells = Self.gridCells(lots)
                let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                        switch cell {
                        case .lot(let lot): ParkingCompactCell(lot: lot)
                        case .more(let n): ParkingMoreCell(count: n)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .activityBackgroundTint(Color(UIColor.secondarySystemBackground))
                .activitySystemActionForegroundColor(Color.primary)
            }
        }
    }

    enum GridCell { case lot(LiteLot), more(Int) }

    /// 最多 8 格；超過 8 個時前 7 格 + 「還有 N 個」
    static func gridCells(_ lots: [LiteLot]) -> [GridCell] {
        if lots.count <= 8 { return lots.map { .lot($0) } }
        return lots.prefix(7).map { .lot($0) } + [.more(lots.count - 7)]
    }
}

private struct OccupancyBarView: View {
    let available: Int
    let total: Int
    let lastUpdated: Date
    var height: CGFloat = 12
    
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
            .frame(height: height)
    
        }
    }
}

/// 2–3 個時的單列：名稱、狀態（圖示 + 文字）、剩餘數、細進度條
private struct ParkingListRow: View {
    let lot: LiteLot

    var body: some View {
        let status = LiveLotStatus(lot)
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text(lot.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                HStack(spacing: 2) {
                    Image(systemName: status.icon)
                    Text(status.label)
                }
                .font(.caption2)
                .foregroundStyle(status.color)
                Text("\(lot.available)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(status.color)
                    .frame(minWidth: 36, alignment: .trailing)
            }
            OccupancyBarView(available: lot.available, total: lot.total, lastUpdated: .now, height: 5)
        }
    }
}

/// 4–8 個時的精簡格：短名稱 + 狀態圖示 + 剩餘數（單行，無進度條）
private struct ParkingCompactCell: View {
    let lot: LiteLot

    var body: some View {
        let status = LiveLotStatus(lot)
        HStack(spacing: 4) {
            Text(lot.shortName)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Image(systemName: status.icon)
                .font(.caption2)
                .foregroundStyle(status.color)
            Text("\(lot.available)")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ParkingMoreCell: View {
    let count: Int

    var body: some View {
        Text("還有 \(count) 個")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
