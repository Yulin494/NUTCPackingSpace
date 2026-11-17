//
//  PixelFont.swift
//  NUTCParkingSpace
//
//  像素字型：俐方體 11 號（Cubic 11，SIL OFL 1.1），PostScript 名稱 `Cubic_11`。
//  點陣字不能連續縮放，故在「粗體文字」或「輔助使用大字級」時退回系統字。
//

import SwiftUI

enum PixelFont {
    /// 俐方體 11 號的 PostScript 名稱（由字型 name table 查得）
    static let postScriptName = "Cubic_11"

    /// 是否應退回系統字（純函式，方便檢查）
    static func shouldFallback(legibilityWeight: LegibilityWeight?, dynamicTypeSize: DynamicTypeSize) -> Bool {
        legibilityWeight == .bold || dynamicTypeSize >= .accessibility1
    }

    /// 固定字級的像素字（不隨 Dynamic Type 縮放）
    static func font(size: CGFloat) -> Font {
        .custom(postScriptName, fixedSize: size)
    }
}

private struct PixelFontModifier: ViewModifier {
    @Environment(\.legibilityWeight) private var legibilityWeight
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var scaledSize: CGFloat
    private let size: CGFloat

    init(size: CGFloat) {
        self.size = size
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        if PixelFont.shouldFallback(legibilityWeight: legibilityWeight, dynamicTypeSize: dynamicTypeSize) {
            // 退回系統字：跟隨 Dynamic Type 與粗體設定
            content.font(.system(size: scaledSize))
        } else {
            content.font(PixelFont.font(size: size))
        }
    }
}

extension View {
    /// 套用像素字（Cubic 11）。字級請用 12 的整數倍（12/24/36/48）。
    func pixelFont(size: CGFloat = PixelMetrics.FontSize.small) -> some View {
        modifier(PixelFontModifier(size: size))
    }
}
