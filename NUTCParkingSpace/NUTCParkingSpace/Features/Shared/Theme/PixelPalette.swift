//
//  PixelPalette.swift
//  NUTCParkingSpace
//
//  像素模式色盤與尺寸常數（來源：design-demos/pixel/C-map/SPEC.md §5）。
//

import SwiftUI

extension Color {
    /// 以 0xRRGGBB 建立顏色（像素色盤專用，避免與其他 Color 擴充衝突）
    fileprivate init(pixelHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// 像素色盤（14 色）。
///
/// TODO（第 3 階段後）：深色模式目前沿用淺色色盤，之後需另訂深色版本。
enum PixelPalette {
    /// 描邊黑：外框、主文字、滿位底
    static let ink = Color(pixelHex: 0x2B2438)
    /// 次要文字、未啟用分頁
    static let muted = Color(pixelHex: 0x5B5470)
    /// 卡片、名牌、標記底
    static let paper = Color(pixelHex: 0xFBF4DD)
    /// 面板底、分頁列底
    static let paper2 = Color(pixelHex: 0xE8DCB5)
    /// 道路、路徑虛線
    static let tan = Color(pixelHex: 0xCDB98A)
    /// 草地、充足標籤、空車位
    static let grass = Color(pixelHex: 0x8CC46A)
    /// 草叢、樹冠
    static let grassD = Color(pixelHex: 0x5FA356)
    /// 停車場地坪。
    /// SPEC 原值 #5E6378 對草地 #8CC46A 的對比只有 2.89:1（低於圖形 3:1），
    /// 正式版改為 #4F5368，WCAG 2.x 實算對比 3.69:1（>= 3:1，通過）。
    static let asphalt = Color(pixelHex: 0x4F5368)
    /// 池塘、窗戶
    static let water = Color(pixelHex: 0x78BFDD)
    static let red = Color(pixelHex: 0xC4503A)
    static let blue = Color(pixelHex: 0x4A74B5)
    static let teal = Color(pixelHex: 0x2F8F86)
    /// 強調色：下一堂、當日、啟用分頁
    static let gold = Color(pixelHex: 0xF0B83A)
    /// 體育館屋頂、緊張標籤
    static let orange = Color(pixelHex: 0xF59A5A)
}
