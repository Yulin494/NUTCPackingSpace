//
//  PixelIcon.swift
//  NUTCParkingSpace
//
//  12x12 位元圖圖示：以 Canvas 逐格填整數座標方塊，無抗鋸齒模糊。
//

import SwiftUI

enum PixelIconKind: CaseIterable {
    case parking, study, home, campus, settings
    case cloud, check, triangle, cross, dot, alert

    /// 12 列、每列 12 字元；"X" 為實心格，"." 為空格
    var bitmap: [String] {
        switch self {
        case .parking:
            return [
                "XXXXXXXXXXXX",
                "X..........X",
                "X..XXXXX...X",
                "X..XX..XX..X",
                "X..XX..XX..X",
                "X..XXXXX...X",
                "X..XX......X",
                "X..XX......X",
                "X..XX......X",
                "X..........X",
                "XXXXXXXXXXXX",
                "............",
            ]
        case .study:
            return [
                "............",
                ".XXXXX.XXXX.",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                ".XXXXX.XXXX.",
                "............",
                "............",
            ]
        case .home:
            return [
                ".....XX.....",
                "....XXXX....",
                "...XXXXXX...",
                "..XXXXXXXX..",
                ".XXXXXXXXXX.",
                "XXXXXXXXXXXX",
                ".XXXXXXXXXX.",
                ".XXXX..XXXX.",
                ".XXXX..XXXX.",
                ".XXXX..XXXX.",
                ".XXXXXXXXXX.",
                "............",
            ]
        case .campus:
            return [
                "....XXXX....",
                "..XXXXXXXX..",
                ".XXXXXXXXXX.",
                ".XXXX..XXXX.",
                ".XXX....XXX.",
                ".XXX....XXX.",
                ".XXXX..XXXX.",
                ".XXXXXXXXXX.",
                "..XXXXXXXX..",
                "...XXXXXX...",
                "....XXXX....",
                ".....XX.....",
            ]
        case .settings:
            return [
                ".....XX.....",
                ".XX..XX..XX.",
                ".XXXXXXXXXX.",
                "..XXXXXXXX..",
                "XXXXX..XXXXX",
                "XXXX....XXXX",
                "XXXX....XXXX",
                "XXXXX..XXXXX",
                "..XXXXXXXX..",
                ".XXXXXXXXXX.",
                ".XX..XX..XX.",
                ".....XX.....",
            ]
        case .cloud:
            return [
                "............",
                "............",
                "....XXX.....",
                "...XXXXX.XX.",
                "..XXXXXXXXXX",
                ".XXXXXXXXXXX",
                "XXXXXXXXXXXX",
                "XXXXXXXXXXXX",
                ".XXXXXXXXXX.",
                "............",
                "............",
                "............",
            ]
        case .check:
            return [
                "............",
                "..........XX",
                ".........XXX",
                "........XXX.",
                "XX.....XXX..",
                "XXX...XXX...",
                ".XXX.XXX....",
                "..XXXXX.....",
                "...XXX......",
                "....X.......",
                "............",
                "............",
            ]
        case .triangle:
            return [
                ".....XX.....",
                "....XXXX....",
                "....XXXX....",
                "...XXXXXX...",
                "...XXXXXX...",
                "..XXXXXXXX..",
                "..XXXXXXXX..",
                ".XXXXXXXXXX.",
                ".XXXXXXXXXX.",
                "XXXXXXXXXXXX",
                "XXXXXXXXXXXX",
                "............",
            ]
        case .cross:
            return [
                "XX........XX",
                "XXX......XXX",
                ".XXX....XXX.",
                "..XXX..XXX..",
                "...XXXXXX...",
                "....XXXX....",
                "....XXXX....",
                "...XXXXXX...",
                "..XXX..XXX..",
                ".XXX....XXX.",
                "XXX......XXX",
                "XX........XX",
            ]
        case .dot:
            return [
                "............",
                "............",
                "....XXXX....",
                "...XXXXXX...",
                "..XXXXXXXX..",
                "..XXXXXXXX..",
                "..XXXXXXXX..",
                "..XXXXXXXX..",
                "...XXXXXX...",
                "....XXXX....",
                "............",
                "............",
            ]
        case .alert:
            // 驚嘆號：快滿
            return [
                ".....XX.....",
                "....XXXX....",
                "....XXXX....",
                "....XXXX....",
                "....XXXX....",
                "....XXXX....",
                ".....XX.....",
                ".....XX.....",
                "............",
                ".....XX.....",
                "....XXXX....",
                ".....XX.....",
            ]
        }
    }
}

struct PixelIcon: View {
    static let gridSize = 12

    let kind: PixelIconKind
    /// 每格的邊長（pt）。2 = 24pt 圖示。
    var scale: CGFloat = 2
    /// 指定顏色；nil 時使用 foregroundStyle
    var color: Color? = nil

    var body: some View {
        // 每格取整數 pt，確保邊緣對齊像素格
        let cell = max(scale.rounded(), 1)
        let side = CGFloat(Self.gridSize) * cell
        Canvas { context, _ in
            for (y, row) in kind.bitmap.enumerated() {
                for (x, ch) in row.enumerated() where ch == "X" {
                    let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                                      width: cell, height: cell)
                    if let color {
                        context.fill(Path(rect), with: .color(color))
                    } else {
                        context.fill(Path(rect), with: .foreground)
                    }
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ForEach(PixelIconKind.allCases, id: \.self) { kind in
                PixelIcon(kind: kind)
            }
        }
        .foregroundStyle(PixelPalette.ink)
        HStack(spacing: 12) {
            PixelIcon(kind: .parking, scale: 4, color: PixelPalette.blue)
            PixelIcon(kind: .home, scale: 4, color: PixelPalette.red)
        }
    }
    .padding(24)
    .background(PixelPalette.paper)
}
