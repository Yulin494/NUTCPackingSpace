//
//  PixelInfoPageChrome.swift
//  NUTCParkingSpace
//
//  像素模式「資訊子頁」共用外殼（圖書館、美食、YouBike、緊急聯絡、學校系統、
//  校區配置圖、開放原始碼授權共用）：紙色背景、principal 像素標題、紙色導覽列、
//  缺角框卡片、缺角小名牌、點陣小圖示。
//

import SwiftUI

// MARK: - 頁面外殼

extension View {
    /// 像素子頁骨架：深紙色滿版背景 + inline 導覽列 + principal 像素標題 + 深紙色 toolbarBackground。
    /// 保留 navigationTitle（VoiceOver 與返回鍵文字）。
    func pixelInfoPage(title: String) -> some View {
        self
            .background(PixelPalette.paper2.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .pixelFont(size: PixelMetrics.FontSize.medium)
                        .foregroundStyle(PixelPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - 區塊標題 + 卡片

/// 區塊標題（NamePlate）靠左，下方內容由呼叫端放入。
struct PixelInfoSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NamePlate(text: title)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 不可點資訊卡：2pt 墨框缺角、無陰影。
struct PixelInfoCard<Content: View>: View {
    var fill: Color = PixelPalette.paper
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: fill)
    }
}

/// 2pt 缺角小名牌（取代膠囊標籤）：像素字或系統字皆可；形狀 + 文字，不只靠顏色。
struct PixelTagLabel: View {
    let text: String
    var fill: Color = PixelPalette.paper
    var textColor: Color = PixelPalette.ink
    var icon: PixelIconKind? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon { PixelIcon(kind: icon, scale: 1) }
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .pixelFrame(fill: fill)
    }
}

// MARK: - 點陣小圖示

enum PixelInfoGlyphKind {
    case book, globe, person, people, monitor, building, cap, shield, medcross, flame, star
    case search, swap, printer, door, bike, fork, pin, clock, phone

    var bitmap: [String] {
        switch self {
        case .book: return [
            ".XXXXXXXXXX.", ".X...XX...X.", ".X.X.XX.X.X.", ".X...XX...X.",
            ".X.X.XX.X.X.", ".X...XX...X.", ".XXXXXXXXXX."]
        case .globe: return [
            "...XXXXXX...", "..X..XX..X..", ".X...XX...X.", "XXXXXXXXXXXX", "X....XX....X",
            "X....XX....X", "XXXXXXXXXXXX", ".X...XX...X.", "..X..XX..X..", "...XXXXXX..."]
        case .person: return [
            "....XXXX....", "....XXXX....", "....XXXX....", ".....XX.....", "..XXXXXXXX..",
            ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX."]
        case .people: return [
            "..XX....XX..", ".XXXX..XXXX.", ".XXXX..XXXX.", "..XX....XX..", ".XXXXXXXXXX.",
            "XXXXXXXXXXXX", "XXXXXXXXXXXX"]
        case .monitor: return [
            ".XXXXXXXXXX.", ".X........X.", ".X........X.", ".X........X.", ".X........X.",
            ".XXXXXXXXXX.", ".....XX.....", "...XXXXXX..."]
        case .building: return [
            ".....XX.....", "...XXXXXX...", "..XXXXXXXX..", "XXXXXXXXXXXX", ".X.X.XX.X.X.",
            ".X.X.XX.X.X.", ".X.X.XX.X.X.", ".X.X.XX.X.X.", "XXXXXXXXXXXX"]
        case .cap: return [
            ".....XX.....", "...XXXXXX...", ".XXXXXXXXXX.", "XXXXXXXXXXXX", ".XXXXXXXXXX.",
            "...XX..XX...", "...XX..XX...", "...XXXXXX..."]
        case .shield: return [
            ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", "..XXXXXXXX..",
            "..XXXXXXXX..", "...XXXXXX...", "....XXXX....", ".....XX....."]
        case .medcross: return [
            "....XXXX....", "....XXXX....", "....XXXX....", "XXXXXXXXXXXX", "XXXXXXXXXXXX",
            "XXXXXXXXXXXX", "XXXXXXXXXXXX", "....XXXX....", "....XXXX....", "....XXXX...."]
        case .flame: return [
            ".....X......", "....XX......", "....XXX..X..", "...XXXX.XX..", "..XXXXXXXX..",
            "..XXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", ".XXXXXXXXXX.", "..XXXXXXXX..",
            "...XXXXXX..."]
        case .star: return [
            ".....XX.....", ".....XX.....", "....XXXX....", "XXXXXXXXXXXX", ".XXXXXXXXXX.",
            "..XXXXXXXX..", "..XXXXXXXX..", ".XXXX..XXXX.", ".XX......XX."]
        case .search: return [
            "..XXXXXX....", ".XX....XX...", ".X......X...", ".X......X...", ".XX....XX...",
            "..XXXXXXX...", ".......XXX..", "........XXX.", ".........XXX"]
        case .swap: return [
            "...X........", "..XX........", ".XXXXXXXXXX.", "..XX........", "...X........",
            "............", "........X...", "........XX..", ".XXXXXXXXXX.", "........XX..",
            "........X..."]
        case .printer: return [
            "...XXXXXX...", "...X....X...", "XXXXXXXXXXXX", "X..........X", "X.......XX.X",
            "XXXXXXXXXXXX", "...X....X...", "...XXXXXX..."]
        case .door: return [
            ".XXXXXXXX...", ".X......X...", ".X......X...", ".X....X.X...", ".X......X...",
            ".X......X...", ".X......X...", "XXXXXXXXXXXX"]
        case .bike: return [
            "......XXX...", "....XXX.....", "..XX.X.X....", ".X..X.X..X..", "X....X....X.",
            "X....X....X.", ".X..X.X..X..", "..XX...XX..."]
        case .fork: return [
            "X.X.X..XX...", "X.X.X.XXXX..", "X.X.X.XXXX..", "XXXXX.XXXX..", ".XXX..XXXX..",
            "..X....XX...", "..X....XX...", "..X....XX...", "..X....XX...", "..X....XX..."]
        case .pin: return [
            "....XXXX....", "...XXXXXX...", "..XXX..XXX..", "..XX....XX..", "..XXX..XXX..",
            "...XXXXXX...", "....XXXX....", ".....XX.....", ".....XX....."]
        case .clock: return [
            "...XXXXXX...", "..X......X..", ".X...X....X.", ".X...X....X.", "X....X.....X",
            "X....XXXX..X", ".X........X.", ".X........X.", "..X......X..", "...XXXXXX..."]
        case .phone: return [
            "...XXXXXX...", "...X....X...", "...X....X...", "...X....X...", "...X....X...",
            "...X....X...", "...X....X...", "...X.XX.X...", "...XXXXXX..."]
        }
    }
}

/// 12x12 點陣小圖示（Canvas 逐格填整數方塊）。顏色用 foregroundStyle 或 color。
struct PixelInfoGlyph: View {
    let kind: PixelInfoGlyphKind
    var scale: CGFloat = 2
    var color: Color = PixelPalette.ink

    var body: some View {
        let cell = max(scale.rounded(), 1)
        let side = 12 * cell
        Canvas { ctx, _ in
            for (y, row) in kind.bitmap.prefix(12).enumerated() {
                for (x, ch) in row.prefix(12).enumerated() where ch == "X" {
                    ctx.fill(Path(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                                         width: cell, height: cell)),
                             with: .color(color))
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}
