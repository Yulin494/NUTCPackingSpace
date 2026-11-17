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
        worst = lots
            .map { PixelStatus.forLot(available: $0.available, total: $0.total) }
            .max { Self.severity($0) < Self.severity($1) } ?? .plenty
    }

    /// 嚴重度：滿位 > 快滿 > 緊張 > 充足
    static func severity(_ s: PixelStatus) -> Int {
        switch s {
        case .plenty, .done: return 0
        case .tight: return 1
        case .almostFull: return 2
        case .full: return 3
        }
    }

    /// 以加總計算的狀態（全部滿位才會是 .full）
    var status: PixelStatus {
        PixelStatus.forLot(available: totalAvailable, total: totalCapacity)
    }

    /// 最緊張的單一停車場狀態：總數會掩蓋某場已滿，所以顏色取最嚴重的那一個
    let worst: PixelStatus

    /// 深色底（動態島、手錶）上的狀態色：滿位的墨色在黑底看不見，改用紅色；形狀另由圖示／文字負責
    var tint: Color { ParkingPixelTint.onDark(worst) }
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
            // 框線用描邊（不是實心底），track 為透明時（Always On）才不會被框線色填滿
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                Rectangle().fill(fill).frame(width: width)
                    .padding(PixelMetrics.border)
            }
            .overlay(Rectangle().strokeBorder(border, lineWidth: PixelMetrics.border))
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

/// 鎖定畫面（高度上限約 160pt），依追蹤數量切換版面：
/// 1 個大字單一版面；2–3 個一列一個；4–8 個兩欄精簡格（>8 個顯示前 7 格 + 「還有 N 個」）
struct ParkingPixelLockScreenView: View {
    let lots: [LiteLot]
    let lastUpdated: Date
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    private var textColor: Color { isLuminanceReduced ? PixelPalette.paper : PixelPalette.ink }

    var body: some View {
        let shown = lots

        VStack(alignment: .leading, spacing: 6) {
            // 標題列（只在 1–2 個時顯示，3 個以上把高度讓給內容）：名牌 + 更新時間
            if shown.count <= 2 {
                header(count: shown.count)
            }

            if shown.isEmpty {
                Text("暫無資料")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(textColor)
            } else if shown.count == 1, let lot = shown.first {
                singleLot(lot)
            } else if shown.count <= 3 {
                // 高度：3 列 × 約 28 + 間距 12 + 內距 28 ≈ 124
                VStack(spacing: 6) {
                    ForEach(shown, id: \.self) { row($0) }
                }
            } else {
                // 高度：4 列 × 約 24 + 間距 3×6 + 內距 28 ≈ 142
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

    private func header(count: Int) -> some View {
        HStack(spacing: 8) {
            Text(count > 1 ? "追蹤 \(count) 個" : "停車追蹤")
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
            .foregroundStyle(textColor)
            bar(ratio: ratio, status: status)
        }
    }

    /// 2–3 個：單行 = 名稱 | 進度條 | 狀態章 | 剩餘數
    private func row(_ lot: LiteLot) -> some View {
        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
        let ratio = lot.total > 0 ? Double(lot.available) / Double(lot.total) : 0
        return HStack(alignment: .center, spacing: 6) {
            Text(lot.name)
                .pixelFont(size: PixelMetrics.FontSize.small)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(textColor)
                .frame(width: 84, alignment: .leading)
            bar(ratio: ratio, status: status)
            chip(status)
            Text("\(lot.available)")
                .pixelFont(size: PixelMetrics.FontSize.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(textColor)
                .frame(width: 44, alignment: .trailing)
        }
    }

    /// 4–8 個：兩欄精簡格，每格 = 短名稱 + 狀態圖示 + 剩餘數（無進度條）
    private func grid(_ lots: [LiteLot]) -> some View {
        let cells: [Cell] = lots.count <= 8
            ? lots.map { .lot($0) }
            : lots.prefix(7).map { Cell.lot($0) } + [.more(lots.count - 7)]
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                switch cell {
                case .lot(let lot): compactCell(lot)
                case .more(let n): moreCell(n)
                }
            }
        }
    }

    private enum Cell { case lot(LiteLot), more(Int) }

    private func compactCell(_ lot: LiteLot) -> some View {
        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
        return HStack(spacing: 4) {
            Text(lot.shortName)
                .pixelFont(size: PixelMetrics.FontSize.small)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            PixelIcon(kind: status.icon, scale: 1,
                      color: isLuminanceReduced ? PixelPalette.paper : status == .full ? PixelPalette.ink : status.fill)
            Text("\(lot.available)")
                .pixelFont(size: PixelMetrics.FontSize.small)
                .lineLimit(1)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, minHeight: 22)
        .background(cellFrame)
    }

    private func moreCell(_ n: Int) -> some View {
        Text("還有 \(n) 個")
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(isLuminanceReduced ? PixelPalette.tan : PixelPalette.muted)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, minHeight: 22)
            .background(cellFrame)
    }

    @ViewBuilder
    private var cellFrame: some View {
        if isLuminanceReduced {
            PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border)
        } else {
            PixelFrameBackground(fill: PixelPalette.paper2, border: PixelPalette.ink)
        }
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

/// expanded 右側：總空位數（像素大字），顏色取最緊張的停車場
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

/// expanded 底部：1 個單行；2–3 個一列一個；4 個以上兩欄（最多 4 個 + 「還有 N 個」）+ 更新時間
struct ParkingPixelIslandBottom: View {
    let lots: [LiteLot]
    let lastUpdated: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if lots.count <= 3 {
                ForEach(lots, id: \.self) { lot in
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
            } else {
                let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(lots.prefix(4)), id: \.self) { lot in
                        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
                        HStack(spacing: 4) {
                            Text(lot.shortName)
                                .pixelFont(size: PixelMetrics.FontSize.small)
                                .foregroundStyle(PixelPalette.paper)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 0)
                            PixelIcon(kind: status.icon, scale: 1, color: ParkingPixelTint.onDark(status))
                            Text("\(lot.available)")
                                .pixelFont(size: PixelMetrics.FontSize.small)
                                .foregroundStyle(ParkingPixelTint.onDark(status))
                        }
                    }
                }
            }
            HStack {
                if lots.count > 4 {
                    Text("還有 \(lots.count - 4) 個")
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

/// compact 左側：1 個為停車 P 圖示；多個加上追蹤數量
struct ParkingPixelCompactLeading: View {
    let lots: [LiteLot]
    var body: some View {
        HStack(spacing: 2) {
            PixelIcon(kind: .parking, scale: 1, color: ParkingPixelSummary(lots: lots).tint)
            if lots.count > 1 {
                Text("\(lots.count)")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.paper)
                    .lineLimit(1)
            }
        }
    }
}

/// compact 右側：1 個為該場剩餘、多個為總剩餘；顏色取最緊張的停車場
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
/// 1 個：大字；多個：最多 3 個精簡列（超過 3 個只列前 2 個 + 「＋N」）
struct ParkingLiveActivityWatchPixelView: View {
    let context: ActivityViewContext<ParkingAttributes>

    var body: some View {
        let lots = context.state.lots
        let summary = ParkingPixelSummary(lots: lots)

        Group {
            if lots.isEmpty {
                Text("暫無資料")
                    .font(.caption2)
                    .foregroundStyle(PixelPalette.tan)
            } else if lots.count == 1, let lot = lots.first {
                let status = PixelStatus.forLot(available: lot.available, total: lot.total)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lot.name)
                        .font(.footnote)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(lot.available)")
                            .font(.system(size: 44, weight: .heavy))
                            .monospacedDigit()
                            .foregroundStyle(ParkingPixelTint.onDark(status))
                            .minimumScaleFactor(0.6)
                        PixelIcon(kind: status.icon, scale: 1, color: ParkingPixelTint.onDark(status))
                    }
                    Text("剩餘車位・\(status.label)")
                        .font(.caption2)
                        .foregroundStyle(PixelPalette.tan)
                }
            } else {
                let rows = lots.count <= 3 ? lots.count : 2
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        PixelIcon(kind: .parking, scale: 1, color: summary.tint)
                        Text("追蹤 \(lots.count) 個")
                            .lineLimit(1)
                        Spacer()
                        Text("\(summary.totalAvailable)")
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .foregroundStyle(summary.tint)
                    }
                    .font(.footnote)

                    // 狀態以形狀 + 顏色表示
                    ForEach(Array(lots.prefix(rows)), id: \.self) { lot in
                        let status = PixelStatus.forLot(available: lot.available, total: lot.total)
                        HStack(spacing: 4) {
                            PixelIcon(kind: status.icon, scale: 1, color: ParkingPixelTint.onDark(status))
                            Text(lot.shortName)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer()
                            Text("\(lot.available)")
                                .monospacedDigit()
                                .foregroundStyle(ParkingPixelTint.onDark(status))
                        }
                        .font(.caption2)
                    }
                    if lots.count > rows {
                        Text("＋\(lots.count - rows)")
                            .font(.caption2)
                            .foregroundStyle(PixelPalette.tan)
                    }
                }
            }
        }
        .foregroundStyle(PixelPalette.paper)
        .padding(6)
        .background(PixelFrameShape().strokeBorder(PixelPalette.paper, lineWidth: PixelMetrics.border))
    }
}
