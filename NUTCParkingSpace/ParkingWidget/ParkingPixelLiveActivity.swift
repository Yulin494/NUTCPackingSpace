//
//  ParkingPixelLiveActivity.swift
//  ParkingWidget
//
//  停車即時動態的像素版視圖（鎖定畫面、動態島、手錶 Smart Stack small）。
//  樣式由 `AppearanceStyle.fromAppGroup()` 決定，標準版維持原樣。
//  色盤與框線沿用 App 的像素元件（PixelPalette／PixelFrameShape／PixelIcon／StatusChip）。
//

import ActivityKit
import SwiftUI
import WidgetKit
import NUTCParkingShared

// MARK: - 共用輔助

/// 多個停車場的彙總狀態（動態島 compact／minimal／expanded 共用）
struct ParkingPixelSummary {
    let totalAvailable: Int
    let totalCapacity: Int

    init(lots: [LiteLot]) {
        totalAvailable = lots.reduce(0) { $0 + $1.available }
        totalCapacity = lots.reduce(0) { $0 + $1.total }
    }

    var status: PixelStatus {
        PixelStatus.forLot(available: totalAvailable, total: totalCapacity)
    }

    /// 深色底（動態島、手錶）上的狀態色：滿位的墨色在黑底看不見，改用紅色；形狀另由圖示／文字負責
    var tint: Color { ParkingPixelTint.onDark(status) }
}

enum ParkingPixelTint {
    /// 黑底上的狀態色
    static func onDark(_ status: PixelStatus) -> Color {
        switch status {
        case .plenty: return PixelPalette.grass
        case .tight: return PixelPalette.orange
        case .almostFull: return PixelPalette.gold
        case .full: return PixelPalette.red
        case .done: return PixelPalette.water
        }
    }

    /// 紙色底上的進度條填色：滿位時無填色，用墨色即可
    static func onPaper(_ status: PixelStatus) -> Color {
        status.fill
    }
}

/// 2pt 單位的剩餘車位進度條：外框 2pt、填色寬度對齊 2pt 倍數
struct PixelUnitBar: View {
    let ratio: Double
    let fill: Color
    let track: Color
    let border: Color

    var body: some View {
        GeometryReader { geo in
            let inner = max(geo.size.width - PixelMetrics.border * 2, 0)
            let clamped = min(max(ratio, 0), 1)
            let width = PixelMetrics.snap(inner * CGFloat(clamped))
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                Rectangle().fill(fill).frame(width: width)
            }
            .padding(PixelMetrics.border)
            .background(Rectangle().fill(border))
        }
        .frame(height: 8)
    }
}

/// Always On（降低亮度）時使用的描邊狀態章：只留框線與文字，不填色
private struct PixelOutlineChip: View {
    let status: PixelStatus

    var body: some View {
        HStack(spacing: 4) {
            PixelIcon(kind: status.icon, scale: 1, color: PixelPalette.paper)
            Text(status.label).pixelFont(size: PixelMetrics.FontSize.small)
        }
        .foregroundStyle(PixelPalette.paper)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border))
    }
}

// MARK: - 鎖定畫面卡片

struct ParkingPixelLockScreenView: View {
    let title: String
    let lots: [LiteLot]
    let lastUpdated: Date
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        let shown = Array(lots.prefix(4))
        let textColor = isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink

        VStack(alignment: .leading, spacing: 6) {
            // 標題列：名牌 + 更新時間
            HStack(spacing: 8) {
                Text("停車追蹤")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.paper)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background {
                        if isLuminanceReduced {
                            PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border)
                        } else {
                            PixelFrameBackground(fill: PixelPalette.ink, border: PixelPalette.ink)
                        }
                    }
                Spacer(minLength: 0)
                Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(isLuminanceReduced ? PixelPalette.tan : PixelPalette.muted)
                    .lineLimit(1)
            }

            if shown.isEmpty {
                Text("暫無資料")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(textColor)
            } else if shown.count == 1, let lot = shown.first {
                singleLot(lot)
            } else {
                grid(shown)
            }
        }
        .padding(8)
        .background {
            if isLuminanceReduced {
                PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border)
            } else {
                PixelFrameBackground(fill: PixelPalette.paper, border: PixelPalette.ink)
            }
        }
        .padding(6)
        // Always On 時退為黑底，避免大面積亮色
        .activityBackgroundTint(isLuminanceReduced ? Color.black : PixelPalette.paper2)
        .activitySystemActionForegroundColor(isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink)
    }

    /// 單一停車場：名稱 + 狀態章在左，大數字在右，下方整條進度條
    private func singleLot(_ lot: LiteLot) -> some View {
        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
        let ratio = lot.total > 0 ? Double(lot.available) / Double(lot.total) : 0
        return VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lot.name)
                        .pixelFont(size: PixelMetrics.FontSize.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    chip(status)
                }
                Spacer(minLength: 0)
                Text("\(lot.available)")
                    .pixelFont(size: PixelMetrics.FontSize.xlarge)
                    .lineLimit(1)
            }
            .foregroundStyle(isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink)
            bar(ratio: ratio, status: status)
        }
    }

    /// 多個停車場：兩欄格子，每格 = 名稱 + 狀態章 / 大數字 + 進度條
    private func grid(_ shown: [LiteLot]) -> some View {
        let first = shown.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
        let second = shown.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }
        return HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 6) {
                ForEach(first, id: \.self) { cell($0) }
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 6) {
                ForEach(second, id: \.self) { cell($0) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func cell(_ lot: LiteLot) -> some View {
        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
        let ratio = lot.total > 0 ? Double(lot.available) / Double(lot.total) : 0
        return VStack(alignment: .leading, spacing: 2) {
            Text(lot.name)
                .pixelFont(size: PixelMetrics.FontSize.small)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink)
            HStack(alignment: .center, spacing: 4) {
                Text("\(lot.available)")
                    .pixelFont(size: PixelMetrics.FontSize.medium)
                    .lineLimit(1)
                    .foregroundStyle(isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink)
                Spacer(minLength: 0)
                chip(status)
            }
            bar(ratio: ratio, status: status)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func chip(_ status: PixelStatus) -> some View {
        if isLuminanceReduced {
            PixelOutlineChip(status: status)
        } else {
            StatusChip(status: status)
        }
    }

    private func bar(ratio: Double, status: PixelStatus) -> some View {
        PixelUnitBar(
            ratio: ratio,
            fill: isLuminanceReduced ? PixelPalette.paper : ParkingPixelTint.onPaper(status),
            track: isLuminanceReduced ? Color.clear : PixelPalette.paper2,
            border: isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink
        )
    }
}

// MARK: - 動態島

/// expanded 左側：停車 P 圖示（依彙總狀態著色）
struct ParkingPixelIslandLeading: View {
    let lots: [LiteLot]
    var body: some View {
        PixelIcon(kind: .parking, scale: 3, color: ParkingPixelSummary(lots: lots).tint)
            .padding(.leading)
    }
}

/// expanded 右側：總空位數（像素大字）
struct ParkingPixelIslandTrailing: View {
    let lots: [LiteLot]
    var body: some View {
        let summary = ParkingPixelSummary(lots: lots)
        Text("\(summary.totalAvailable)")
            .pixelFont(size: PixelMetrics.FontSize.medium)
            .foregroundStyle(summary.tint)
            .lineLimit(1)
            .padding(.trailing)
    }
}

/// expanded 中間：標題名牌
struct ParkingPixelIslandCenter: View {
    let title: String
    var body: some View {
        Text(title)
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(PixelPalette.paper)
            .lineLimit(1)
    }
}

/// expanded 底部：最多 3 個停車場（名稱、剩餘數、狀態章）+ 更新時間
struct ParkingPixelIslandBottom: View {
    let lots: [LiteLot]
    let lastUpdated: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lots.prefix(3)), id: \.self) { lot in
                let status = PixelStatus.forLot(available: lot.available, total: lot.total)
                HStack(spacing: 6) {
                    Text(lot.name)
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Text("\(lot.available)")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(ParkingPixelTint.onDark(status))
                    StatusChip(status: status)
                }
            }
            HStack {
                if lots.count > 3 {
                    Text("還有 \(lots.count - 3) 個")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.tan)
                }
                Spacer(minLength: 0)
                Text(lastUpdated.formatted(date: .omitted, time: .shortened))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.tan)
            }
            .lineLimit(1)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

/// compact 左側：停車 P 圖示
struct ParkingPixelCompactLeading: View {
    let lots: [LiteLot]
    var body: some View {
        PixelIcon(kind: .parking, scale: 1, color: ParkingPixelSummary(lots: lots).tint)
    }
}

/// compact 右側：總空位數，顏色依狀態
struct ParkingPixelCompactTrailing: View {
    let lots: [LiteLot]
    var body: some View {
        let summary = ParkingPixelSummary(lots: lots)
        Text("\(summary.totalAvailable)")
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(summary.tint)
            .lineLimit(1)
    }
}

/// minimal：有位時顯示數字，滿位改顯示叉號形狀（不單靠顏色）
struct ParkingPixelMinimal: View {
    let lots: [LiteLot]
    var body: some View {
        let summary = ParkingPixelSummary(lots: lots)
        if summary.status == .full {
            PixelIcon(kind: .cross, scale: 1, color: summary.tint)
        } else {
            Text("\(summary.totalAvailable)")
                .pixelFont(size: PixelMetrics.FontSize.small)
                .foregroundStyle(summary.tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - 手錶 Smart Stack small

/// 像素版手錶小卡：像素框 + 像素圖示 + 系統字（小尺寸不用點陣字，避免跑版與糊字）
struct ParkingLiveActivityWatchPixelView: View {
    let context: ActivityViewContext<ParkingAttributes>

    var body: some View {
        let lots = context.state.lots
        let summary = ParkingPixelSummary(lots: lots)

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                PixelIcon(kind: .parking, scale: 1, color: summary.tint)
                Text("機車空位")
                    .lineLimit(1)
                Spacer()
                Text("\(summary.totalAvailable)")
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(summary.tint)
            }
            .font(.footnote)

            if lots.isEmpty {
                Text("暫無資料")
                    .font(.caption2)
                    .foregroundStyle(PixelPalette.tan)
            } else {
                // 最多顯示 2 個停車場；狀態以形狀 + 顏色表示
                ForEach(Array(lots.prefix(2)), id: \.self) { lot in
                    let status = PixelStatus.forLot(available: lot.available, total: lot.total)
                    HStack(spacing: 4) {
                        PixelIcon(kind: status.icon, scale: 1, color: ParkingPixelTint.onDark(status))
                        Text(lot.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Text("\(lot.available)")
                            .monospacedDigit()
                            .foregroundStyle(ParkingPixelTint.onDark(status))
                    }
                    .font(.caption2)
                }
            }
        }
        .foregroundStyle(PixelPalette.paper)
        .padding(6)
        .background(PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border))
    }
}
