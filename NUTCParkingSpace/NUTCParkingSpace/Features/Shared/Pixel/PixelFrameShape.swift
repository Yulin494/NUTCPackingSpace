//
//  PixelFrameShape.swift
//  NUTCParkingSpace
//
//  2pt 缺角框：四角各缺一個 2pt 方格的 12 邊折線。
//

import SwiftUI

struct PixelFrameShape: InsettableShape {
    var notch: CGFloat = PixelMetrics.notch
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let n = notch
        var p = Path()
        p.move(to: CGPoint(x: r.minX + n, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.minY + n))
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> PixelFrameShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

/// 缺角框背景：外層墨色框 + 內層填色，不使用抗鋸齒模糊的描邊。
struct PixelFrameBackground: View {
    var fill: Color = PixelPalette.paper
    var border: Color = PixelPalette.ink
    var borderWidth: CGFloat = PixelMetrics.border

    var body: some View {
        ZStack {
            PixelFrameShape().fill(border)
            PixelFrameShape().inset(by: borderWidth).fill(fill)
        }
    }
}

extension View {
    /// 以缺角框作為背景（填色 + 2pt 墨色框）
    func pixelFrame(fill: Color = PixelPalette.paper,
                    border: Color = PixelPalette.ink,
                    borderWidth: CGFloat = PixelMetrics.border) -> some View {
        background(PixelFrameBackground(fill: fill, border: border, borderWidth: borderWidth))
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("缺角框")
            .padding(12)
            .pixelFrame()
        Text("金底")
            .padding(12)
            .pixelFrame(fill: PixelPalette.gold)
        PixelFrameShape()
            .fill(PixelPalette.grass)
            .frame(width: 80, height: 40)
    }
    .padding(24)
    .background(PixelPalette.paper2)
}
