//
//  PixelParkingRow.swift
//  NUTCParkingSpace
//
//  像素版停車場列：狀態章 + 名稱 + 剩餘數（像素字）+ 2pt 單位進度條。
//  整列是 Button（PixelButtonStyle）；長按選單保留「開始通勤監控」。
//

import SwiftUI

/// 2pt 單位像素進度條。滿位（剩 0）整條改為棋盤格，不單靠顏色表示。
struct PixelOccupancyBar: View {
    let ratio: Double
    let status: PixelStatus

    var body: some View {
        Canvas { ctx, size in
            let u = PixelMetrics.unit
            let outer = CGRect(origin: .zero, size: size)
            ctx.fill(Path(outer), with: .color(PixelPalette.ink))
            let inner = outer.insetBy(dx: u, dy: u)
            ctx.fill(Path(inner), with: .color(PixelPalette.paper))

            if status == .full {
                // 棋盤格：2pt 方格交錯
                var y = inner.minY
                var row = 0
                while y < inner.maxY {
                    var x = inner.minX
                    var col = row % 2
                    while x < inner.maxX {
                        if col % 2 == 0 {
                            let cell = CGRect(x: x, y: y,
                                              width: min(u, inner.maxX - x),
                                              height: min(u, inner.maxY - y))
                            ctx.fill(Path(cell), with: .color(PixelPalette.muted))
                        }
                        x += u
                        col += 1
                    }
                    y += u
                    row += 1
                }
            } else {
                // 剩餘比例：寬度對齊 2pt，至少 1 格
                let w = max(u, PixelMetrics.snap(inner.width * CGFloat(min(max(ratio, 0), 1))))
                let bar = CGRect(x: inner.minX, y: inner.minY, width: w, height: inner.height)
                ctx.fill(Path(bar), with: .color(status.fill))
                // 右緣 2pt 墨色分隔線，讓填色邊界不單靠顏色辨識
                if w < inner.width {
                    ctx.fill(Path(CGRect(x: bar.maxX, y: inner.minY, width: u, height: inner.height)),
                             with: .color(PixelPalette.ink))
                }
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}

struct PixelParkingRow: View {
    let lot: ParkingLot
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    var onStartCommute: () -> Void = {}

    /// 與地圖標記一致：沿用 PixelStatus 的絕對數量門檻（>=30 充足、1-29 緊張、0 滿位）
    private var status: PixelStatus { .forLot(lot) }

    private var ratio: Double {
        guard lot.totalCapacity > 0 else { return 0 }
        return Double(lot.availableCount) / Double(lot.totalCapacity)
    }

    private var updatedText: String {
        lot.lastUpdated.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_Hant_TW")))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lot.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(PixelPalette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        StatusChip(status: status)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(lot.availableCount)")
                                .pixelFont(size: PixelMetrics.FontSize.medium)
                                .foregroundStyle(PixelPalette.ink)
                            if lot.totalCapacity > 0 {
                                Text("/ \(lot.totalCapacity)")
                                    .font(.system(size: 15))
                                    .foregroundStyle(PixelPalette.muted)
                            }
                        }
                        Text("剩餘車位")
                            .font(.system(size: 15))
                            .foregroundStyle(PixelPalette.muted)
                    }
                }
                // 有總量資料才顯示進度條（沿用原本規則）
                if lot.totalCapacity > 0 {
                    PixelOccupancyBar(ratio: ratio, status: status)
                }
                if isSelected {
                    Text("更新時間 \(updatedText)　長按可開始通勤監控")
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(PixelButtonStyle(fill: isSelected ? PixelPalette.gold : PixelPalette.paper))
        // 長按：開始通勤即時追蹤（對應 ParkingRowView 的 contextMenu）
        .contextMenu {
            Button {
                HapticManager.shared.impact(style: .medium)
                onStartCommute()
            } label: {
                Label("開始通勤監控", systemImage: "motorcycle.fill")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lot.name)，剩餘 \(lot.availableCount) 個車位，\(status.label)")
        .accessibilityHint("長按可開始通勤監控")
        .accessibilityAddTraits(.isButton)
    }
}
