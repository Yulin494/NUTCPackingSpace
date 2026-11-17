//
//  PixelButtonStyle.swift
//  NUTCParkingSpace
//
//  可按元件專用：底下一層實色墨色陰影位移 (4,4)，不模糊；
//  按下時本體位移 (4,4) 蓋住陰影，並觸發輕觸覺回饋。
//

import SwiftUI

struct PixelButtonStyle: ButtonStyle {
    var fill: Color = PixelPalette.paper
    var border: Color = PixelPalette.ink
    var shadow: Color = PixelPalette.ink
    var contentPadding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

    func makeBody(configuration: Configuration) -> some View {
        let d = PixelMetrics.shadowOffset
        let pressed = configuration.isPressed

        configuration.label
            .padding(contentPadding)
            .pixelFrame(fill: fill, border: border)
            .offset(x: pressed ? d : 0, y: pressed ? d : 0)
            // 陰影層：實色、同形狀、位移 (4,4)，放在本體後方
            .background(
                PixelFrameShape()
                    .fill(shadow)
                    .offset(x: d, y: d)
            )
            // 預留陰影佔用的空間，避免被相鄰版面裁切
            .padding(.trailing, d)
            .padding(.bottom, d)
            .sensoryFeedback(trigger: pressed) { _, isDown in
                isDown ? .impact(weight: .light) : nil
            }
    }
}

extension ButtonStyle where Self == PixelButtonStyle {
    static var pixel: PixelButtonStyle { PixelButtonStyle() }
}

#Preview {
    VStack(spacing: 24) {
        Button("可按按鈕") {}
            .buttonStyle(.pixel)
        Button("金色按鈕") {}
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
    }
    .pixelFont(size: PixelMetrics.FontSize.small)
    .foregroundStyle(PixelPalette.ink)
    .padding(32)
    .background(PixelPalette.paper2)
}
