//
//  PixelLibraryView.swift
//  NUTCParkingSpace
//
//  像素模式圖書館頁：開館狀態章、開放時間數值格、樓層與服務列、館藏查詢像素按鈕。
//  資料與開館判斷沿用 LibraryView（由其傳入 isOpenNow）。
//

import SwiftUI

struct PixelLibraryView: View {
    let isOpenNow: Bool
    let catalogURL: URL

    private let hours: [(days: String, hours: String, closed: Bool)] = [
        ("週一至週五", "08:00 – 22:00", false),
        ("週六", "09:00 – 17:00", false),
        ("週日 / 國定假日", "閉館", true),
    ]

    private let floors: [(floor: String, name: String)] = [
        ("1F", "期刊 / 報紙"),
        ("2F", "參考書 / 視聽室"),
        ("3F", "中文圖書區"),
        ("4F", "外文圖書 / 研究小間"),
        ("B1", "自修室 / 電子資源"),
    ]

    private let services: [(glyph: PixelInfoGlyphKind, name: String, desc: String)] = [
        (.search, "館藏查詢", "書目搜尋、館位查詢"),
        (.swap, "館際互借", "他館借閱、文獻傳遞"),
        (.printer, "複印 / 列印", "黑白、彩色、A3"),
        (.door, "討論室預約", "需提前在線上預約"),
        (.cap, "讀書指導", "文獻資料庫使用教學"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                statusCard
                PixelInfoSection(title: "開放時間") { hoursCard }
                PixelInfoSection(title: "樓層指引") { floorsCard }
                PixelInfoSection(title: "主要服務") { servicesCard }
                catalogButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .pixelInfoPage(title: "圖書館")
    }

    // 開放狀態：形狀（圓點 / 叉）+ 文字 + 底色
    private var statusCard: some View {
        PixelInfoCard {
            HStack(spacing: 12) {
                PixelInfoGlyph(kind: .book, scale: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("台灣大道校區圖書館")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PixelPalette.ink)
                    HStack(spacing: 6) {
                        PixelTagLabel(
                            text: isOpenNow ? "現在開放中" : "目前閉館",
                            fill: isOpenNow ? PixelPalette.grass : PixelPalette.ink,
                            textColor: isOpenNow ? PixelPalette.ink : PixelPalette.paper,
                            icon: isOpenNow ? .dot : .cross
                        )
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // 數值格：每列「星期」+ 像素字時間
    private var hoursCard: some View {
        PixelInfoCard {
            VStack(spacing: 10) {
                ForEach(Array(hours.enumerated()), id: \.offset) { _, h in
                    HStack(alignment: .center, spacing: 8) {
                        Text(h.days)
                            .font(.system(size: 15))
                            .foregroundStyle(PixelPalette.ink)
                        Spacer(minLength: 8)
                        if h.closed {
                            PixelTagLabel(text: h.hours, fill: PixelPalette.ink,
                                          textColor: PixelPalette.paper, icon: .cross)
                        } else {
                            Text(h.hours)
                                .pixelFont(size: PixelMetrics.FontSize.small)
                                .foregroundStyle(PixelPalette.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .pixelFrame(fill: PixelPalette.paper)
                        }
                    }
                    .frame(minHeight: 32)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var floorsCard: some View {
        PixelInfoCard {
            VStack(spacing: 10) {
                ForEach(Array(floors.enumerated()), id: \.offset) { _, f in
                    HStack(spacing: 12) {
                        NamePlate(text: f.floor)
                            .frame(minWidth: 52)
                        Text(f.name)
                            .font(.system(size: 17))
                            .foregroundStyle(PixelPalette.ink)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 36)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var servicesCard: some View {
        PixelInfoCard {
            VStack(spacing: 12) {
                ForEach(Array(services.enumerated()), id: \.offset) { _, s in
                    HStack(spacing: 12) {
                        PixelInfoGlyph(kind: s.glyph, scale: 2)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(PixelPalette.ink)
                            Text(s.desc)
                                .font(.system(size: 15))
                                .foregroundStyle(PixelPalette.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // 進入館藏查詢系統：沿用 NavigationLink → LibraryCatalogView
    private var catalogButton: some View {
        NavigationLink(destination: LibraryCatalogView(url: catalogURL)) {
            HStack(spacing: 10) {
                PixelInfoGlyph(kind: .search, scale: 2)
                Text("進入館藏查詢系統")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PixelPalette.ink)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
    }
}

#Preview {
    NavigationStack { PixelLibraryView(isOpenNow: true, catalogURL: URL(string: "https://elib.nutc.edu.tw/")!) }
}
