//
//  PixelMetrics.swift
//  NUTCParkingSpace
//
//  像素模式尺寸常數。所有數值皆為 2pt 的整數倍，確保邊緣對齊不糊。
//

import CoreGraphics

enum PixelMetrics {
    /// 像素單位
    static let unit: CGFloat = 2
    /// 框線粗細
    static let border: CGFloat = 2
    /// 缺角大小（四角各缺一個方格）
    static let notch: CGFloat = 2
    /// 可按元件的實色陰影位移（x、y 同值）
    static let shadowOffset: CGFloat = 4

    /// 像素字級：12 的整數倍
    enum FontSize {
        static let small: CGFloat = 12
        static let medium: CGFloat = 24
        static let large: CGFloat = 36
        static let xlarge: CGFloat = 48
    }

    /// 將數值對齊到像素單位的整數倍
    static func snap(_ value: CGFloat) -> CGFloat {
        (value / unit).rounded() * unit
    }
}
