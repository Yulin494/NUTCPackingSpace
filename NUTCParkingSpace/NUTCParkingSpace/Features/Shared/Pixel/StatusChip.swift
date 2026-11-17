//
//  StatusChip.swift
//  NUTCParkingSpace
//
//  車位／作業狀態章：形狀 + 文字 + 底色三重編碼，不單靠顏色表示狀態。
//

import SwiftUI

enum PixelStatus: CaseIterable {
    case plenty      // 充足：圓
    case tight       // 緊張：三角
    case almostFull  // 快滿：驚嘆號
    case full     // 滿位：叉
    case done     // 完成：勾

    var label: String {
        switch self {
        case .plenty: return "充足"
        case .tight: return "緊張"
        case .almostFull: return "快滿"
        case .full: return "滿位"
        case .done: return "完成"
        }
    }

    var icon: PixelIconKind {
        switch self {
        case .plenty: return .dot
        case .tight: return .triangle
        case .almostFull: return .alert
        case .full: return .cross
        case .done: return .check
        }
    }

    var fill: Color {
        switch self {
        case .plenty: return PixelPalette.grass
        case .tight: return PixelPalette.orange
        // 快滿沿用金色，不新增色盤；墨色文字對金色對比 8.2:1（>= 4.5:1），
        // 形狀（驚嘆號）與文字與緊張的三角明顯不同
        case .almostFull: return PixelPalette.gold
        case .full: return PixelPalette.ink
        case .done: return PixelPalette.water
        }
    }

    /// 前景色：滿位為墨底，反白；其餘用墨色（對比皆 >= 6.8:1）
    var foreground: Color {
        self == .full ? PixelPalette.paper : PixelPalette.ink
    }

    /// 與標準模式 ParkingRowView.statusColor 同為比例制，另把「紅」拆成快滿與滿位：
    /// 有總量：剩餘比例 > 50% 充足；> 20% 且 <= 50% 緊張；0 < 比例 <= 20% 快滿；剩餘 0 滿位。
    /// 沒有總量（total <= 0）：剩餘 0 滿位；> 10 充足；其餘緊張。
    static func forLot(available: Int, total: Int) -> PixelStatus {
        if available <= 0 { return .full }
        if total <= 0 { return available > 10 ? .plenty : .tight }
        let ratio = Double(available) / Double(total)
        if ratio > 0.5 { return .plenty }
        if ratio > 0.2 { return .tight }
        return .almostFull
    }

    static func forLot(_ lot: ParkingLot) -> PixelStatus {
        forLot(available: lot.availableCount, total: lot.totalCapacity)
    }
}

struct StatusChip: View {
    let status: PixelStatus

    var body: some View {
        HStack(spacing: 4) {
            PixelIcon(kind: status.icon, scale: 1)
            Text(status.label)
                .pixelFont(size: PixelMetrics.FontSize.small)
        }
        .foregroundStyle(status.foreground)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .pixelFrame(fill: status.fill)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.label)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(PixelStatus.allCases, id: \.self) { StatusChip(status: $0) }
    }
    .padding(24)
    .background(PixelPalette.paper)
}
