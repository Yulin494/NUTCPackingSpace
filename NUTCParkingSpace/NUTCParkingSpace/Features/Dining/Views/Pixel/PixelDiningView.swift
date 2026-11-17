//
//  PixelDiningView.swift
//  NUTCParkingSpace
//
//  像素模式育才街美食：像素分段分類篩選 + 兩欄像素餐廳卡（點擊以 Apple 地圖搜尋店名與地址）。
//

import SwiftUI

struct PixelDiningView: View {
    let restaurants: [Restaurant]
    @State private var selectedCategory: String = "全部"

    private var categories: [String] {
        ["全部"] + Array(Set(restaurants.map(\.category))).sorted()
    }

    private var filtered: [Restaurant] {
        selectedCategory == "全部" ? restaurants : restaurants.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 分類篩選：選中者金底 + 勾選圖示（不只靠顏色），離散切換無動畫
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            categoryButton(cat)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }

                HStack(spacing: 8) {
                    NamePlate(text: selectedCategory)
                    Text("\(filtered.count) 間")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.ink)
                }
                .padding(.horizontal, 16)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(filtered) { r in
                        PixelRestaurantCard(restaurant: r)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .pixelInfoPage(title: "育才街美食")
    }

    private func categoryButton(_ cat: String) -> some View {
        let selected = selectedCategory == cat
        return Button {
            selectedCategory = cat
        } label: {
            HStack(spacing: 4) {
                if selected { PixelIcon(kind: .check, scale: 1) }
                Text(cat)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(PixelPalette.ink)
            .frame(minHeight: 28)
        }
        .buttonStyle(PixelButtonStyle(
            fill: selected ? PixelPalette.gold : PixelPalette.paper,
            contentPadding: EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)))
        .frame(minHeight: 44)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct PixelRestaurantCard: View {
    let restaurant: Restaurant

    private var glyph: PixelInfoGlyphKind {
        let c = restaurant.category
        if c.contains("冰品") { return .star }
        if c.contains("燒肉") || c.contains("韓式") { return .flame }
        return .fork
    }

    // 與 RestaurantCard 相同：Apple 地圖搜尋店名＋地址
    private var mapsURL: URL {
        let query = "\(restaurant.name) \(restaurant.address)"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(encoded)") ?? URL(string: "http://maps.apple.com")!
    }

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(mapsURL)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    PixelInfoGlyph(kind: glyph, scale: 2)
                    Spacer(minLength: 0)
                    PixelTagLabel(text: restaurant.category, fill: PixelPalette.gold)
                }
                Text(restaurant.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PixelPalette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                infoLine(.clock, restaurant.hours)
                infoLine(.pin, restaurant.address)
                if let note = restaurant.note {
                    Text(note)
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                if !restaurant.tags.isEmpty {
                    // 標籤：缺角小名牌，最多三個
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(restaurant.tags.prefix(3)), id: \.self) { tag in
                            PixelTagLabel(text: tag)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.pixel)
        .accessibilityHint("在地圖中開啟")
    }

    private func infoLine(_ kind: PixelInfoGlyphKind, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            PixelInfoGlyph(kind: kind, scale: 1, color: PixelPalette.muted)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    NavigationStack { PixelDiningView(restaurants: RestaurantData.restaurants) }
}
