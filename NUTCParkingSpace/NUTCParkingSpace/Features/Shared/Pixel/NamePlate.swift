//
//  NamePlate.swift
//  NUTCParkingSpace
//
//  建築名牌：墨底（或指定色底）、像素字、2pt 缺角。不可按，無厚底陰影。
//

import SwiftUI

struct NamePlate: View {
    let text: String
    var fill: Color = PixelPalette.ink
    var textColor: Color = PixelPalette.paper
    var fontSize: CGFloat = PixelMetrics.FontSize.small

    var body: some View {
        Text(text)
            .pixelFont(size: fontSize)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .pixelFrame(fill: fill)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        NamePlate(text: "圖書館")
        NamePlate(text: "中正大樓", fill: PixelPalette.paper, textColor: PixelPalette.ink)
        NamePlate(text: "資訊大樓", fill: PixelPalette.gold, textColor: PixelPalette.ink)
        NamePlate(text: "體育館", fontSize: PixelMetrics.FontSize.medium)
    }
    .padding(24)
    .background(PixelPalette.grass)
}
