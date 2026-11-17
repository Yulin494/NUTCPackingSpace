//
//  PixelTabBar.swift
//  NUTCParkingSpace
//
//  自繪底部分頁列：5 個項目、PixelIcon、選中項為金底並下壓 2pt。
//

import SwiftUI

struct PixelTabItem: Identifiable {
    let tag: Int
    let title: String
    let icon: PixelIconKind
    var id: Int { tag }
}

struct PixelTabBar: View {
    @Binding var selection: Int

    /// 與 MainTabView 的 tag 對應：停車0、課業1、首頁2、校園3、設定4
    static let items: [PixelTabItem] = [
        PixelTabItem(tag: 0, title: "停車", icon: .parking),
        PixelTabItem(tag: 1, title: "課業", icon: .study),
        PixelTabItem(tag: 2, title: "首頁", icon: .home),
        PixelTabItem(tag: 3, title: "校園", icon: .campus),
        PixelTabItem(tag: 4, title: "設定", icon: .settings),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.items) { item in
                tab(item)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            // 底色延伸到安全區；頂部 4pt 墨色線
            VStack(spacing: 0) {
                Rectangle().fill(PixelPalette.ink).frame(height: 4)
                Rectangle().fill(PixelPalette.paper2)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tab(_ item: PixelTabItem) -> some View {
        let selected = selection == item.tag
        return Button {
            selection = item.tag
        } label: {
            VStack(spacing: 2) {
                PixelIcon(kind: item.icon, scale: 2)
                Text(item.title)
                    .pixelFont(size: PixelMetrics.FontSize.small)
            }
            .foregroundStyle(selected ? PixelPalette.ink : PixelPalette.muted)
            .frame(maxWidth: .infinity, minHeight: 52)
            .pixelFrame(fill: selected ? PixelPalette.gold : .clear,
                        border: selected ? PixelPalette.ink : .clear)
            .offset(y: selected ? PixelMetrics.unit : 0)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: selected) { _, now in now }
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

#Preview {
    struct Demo: View {
        @State var tab = 2
        var body: some View {
            VStack {
                Spacer()
                PixelTabBar(selection: $tab)
            }
            .background(PixelPalette.grass)
        }
    }
    return Demo()
}
