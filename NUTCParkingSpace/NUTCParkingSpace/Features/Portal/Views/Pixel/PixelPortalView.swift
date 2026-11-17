//
//  PixelPortalView.swift
//  NUTCParkingSpace
//
//  像素模式學校系統：兩欄像素入口格（點陣圖示 + 名稱 + 說明），
//  點擊沿用 NavigationLink → PortalWebView（App 內瀏覽器）。
//

import SwiftUI

struct PixelPortalView: View {
    let portals: [PortalItem]

    private func glyph(for item: PortalItem) -> PixelInfoGlyphKind {
        switch item.name {
        case "學生入口網站": return .person
        case "圖書館館藏查詢": return .book
        case "教務處": return .cap
        case "學校官網": return .globe
        case "學務處": return .people
        case "計算機中心": return .monitor
        default: return .building
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(portals) { item in
                    NavigationLink(destination: PortalWebView(item: item)) {
                        VStack(alignment: .leading, spacing: 8) {
                            PixelInfoGlyph(kind: glyph(for: item), scale: 3)
                                .padding(6)
                                .pixelFrame(fill: PixelPalette.gold)
                            Text(item.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(PixelPalette.ink)
                                .multilineTextAlignment(.leading)
                            Text(item.description)
                                .font(.system(size: 15))
                                .foregroundStyle(PixelPalette.muted)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.pixel)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .pixelInfoPage(title: "學校系統")
    }
}
