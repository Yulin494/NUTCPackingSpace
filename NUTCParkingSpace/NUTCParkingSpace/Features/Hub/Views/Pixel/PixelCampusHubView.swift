//
//  PixelCampusHubView.swift
//  NUTCParkingSpace
//
//  像素模式校園頁：服務入口做成像素格（12×12 點陣圖示 + 名牌文字）。
//  不放縮小地圖：首頁已有校園地圖，本頁以服務入口為主，避免重複並保留捲動空間。
//  入口與導覽目的地與 CampusHubView 完全一致。
//

import SwiftUI
import NUTCParkingShared

// MARK: - 校園服務專用 12×12 點陣圖示（不動共用 PixelIcon）

enum CampusServiceGlyph {
    case megaphone, calendar, sun, book, fork, bike, card, phone

    /// 12 列、每列 12 字元；"X" 為實心格
    var bitmap: [String] {
        switch self {
        case .megaphone:
            return [
                "............",
                "......X.....",
                ".....XX..X..",
                "..XXXXX..XX.",
                ".XXXXXXXXXXX",
                ".XXXXXXXXXXX",
                ".XXXXXX.XXX.",
                "..XXXXX..X..",
                "...XX.......",
                "...XX.......",
                "............",
                "............",
            ]
        case .calendar:
            return [
                "..X......X..",
                "XXXXXXXXXXXX",
                "XXXXXXXXXXXX",
                "X..........X",
                "X.X.X.X.X..X",
                "X..........X",
                "X.X.X.X.X..X",
                "X..........X",
                "X.X.X......X",
                "X..........X",
                "XXXXXXXXXXXX",
                "............",
            ]
        case .sun:
            return [
                ".....X......",
                "X....X....X.",
                ".X.......X..",
                "...XXXX.....",
                "..XXXXXX....",
                "XXXXXXXXX...",
                "..XXXXXX....",
                "...XXXX.....",
                ".X.......X..",
                "X....X....X.",
                ".....X......",
                "............",
            ]
        case .book:
            return [
                "............",
                ".XXXXX.XXXX.",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                "X.XX.XX.XX.X",
                "X....XX....X",
                ".XXXXX.XXXX.",
                "............",
                "............",
            ]
        case .fork:
            return [
                "..X.X.X..XX.",
                "..X.X.X.XXXX",
                "..X.X.X.XXXX",
                "..XXXXX.XXXX",
                "...XXX..XXXX",
                "....X....XX.",
                "....X....XX.",
                "....X....XX.",
                "....X....XX.",
                "....X....XX.",
                "....X....XX.",
                "............",
            ]
        case .bike:
            return [
                "............",
                "......XXX...",
                ".....XX.....",
                "..XX.XXXXX..",
                ".X..XX..X.X.",
                "X....X.X...X",
                "X....XX....X",
                "X....XX....X",
                ".X..X..X..X.",
                "..XX....XX..",
                "............",
                "............",
            ]
        case .card:
            return [
                "............",
                "XXXXXXXXXXXX",
                "X..........X",
                "X.XXX......X",
                "X.XXX.XXXX.X",
                "X.XXX......X",
                "X.....XXXX.X",
                "X..........X",
                "XXXXXXXXXXXX",
                "............",
                "............",
                "............",
            ]
        case .phone:
            return [
                "XXXX........",
                "XXXXX.......",
                "XXXX........",
                ".XXX........",
                "..XXX.......",
                "...XXX......",
                "....XXXX..XX",
                ".....XXXXXXX",
                "......XXXXXX",
                ".......XXXXX",
                "........XXXX",
                "............",
            ]
        }
    }
}

/// 以 Canvas 逐格填整數座標方塊的點陣圖示
private struct CampusGlyphView: View {
    let glyph: CampusServiceGlyph
    var scale: CGFloat = 3

    var body: some View {
        let cell = max(scale.rounded(), 1)
        Canvas { context, _ in
            for (y, row) in glyph.bitmap.enumerated() {
                for (x, ch) in row.enumerated() where ch == "X" {
                    let rect = CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                                      width: cell, height: cell)
                    context.fill(Path(rect), with: .foreground)
                }
            }
        }
        .frame(width: 12 * cell, height: 12 * cell)
        .accessibilityHidden(true)
    }
}

// MARK: - 校園頁（像素版）

struct PixelCampusHubView: View {
    /// 單一服務入口
    private struct Entry: Identifiable {
        let id: String
        let glyph: CampusServiceGlyph
        let title: String
        let sub: String
        let tint: Color
        let dest: AnyView
    }

    // 與 CampusHubView 相同的入口與目的地
    private var infoItems: [Entry] { [
        Entry(id: "ann", glyph: .megaphone, title: "校園公告", sub: "最新消息與通知", tint: PixelPalette.blue, dest: AnyView(AnnouncementListView())),
        Entry(id: "cal", glyph: .calendar, title: "學術行事曆", sub: "考試、放假、截止", tint: PixelPalette.red, dest: AnyView(AcademicCalendarView())),
        Entry(id: "wx", glyph: .sun, title: "台中天氣", sub: "即時天氣預報", tint: PixelPalette.orange, dest: AnyView(WeatherView())),
        Entry(id: "lib", glyph: .book, title: "圖書館", sub: "開放時間 · 館藏", tint: PixelPalette.grassD, dest: AnyView(LibraryView())),
    ] }

    private var lifeItems: [Entry] { [
        Entry(id: "din", glyph: .fork, title: "育才街美食", sub: "周邊餐廳推薦", tint: PixelPalette.orange, dest: AnyView(DiningView())),
        Entry(id: "bike", glyph: .bike, title: "YouBike", sub: "附近可借站點", tint: PixelPalette.teal, dest: AnyView(YouBikeView())),
    ] }

    private var systemItems: [Entry] { [
        Entry(id: "portal", glyph: .card, title: "學校系統", sub: "選課 · 成績 · ePortal", tint: PixelPalette.blue, dest: AnyView(SchoolPortalView())),
        Entry(id: "sos", glyph: .phone, title: "緊急聯絡", sub: "校安 · 健康 · 警衛", tint: PixelPalette.red, dest: AnyView(EmergencyView())),
    ] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    calendarBanner
                    section(title: "資訊查詢", items: infoItems)
                    section(title: "生活服務", items: lifeItems)
                    section(title: "學校系統", items: systemItems)
                }
                .foregroundStyle(PixelPalette.ink)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(PixelPalette.paper2.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: 標題名牌

    private var header: some View {
        HStack(spacing: 12) {
            NamePlate(text: "校園", fontSize: PixelMetrics.FontSize.medium)
            Text("校園服務")
                .font(.system(size: 15))
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.grass)
        .accessibilityElement(children: .combine)
    }

    // MARK: 行事曆倒數橫幅（對應原 calendarBanner）

    private var calendarBanner: some View {
        NavigationLink(destination: AcademicCalendarView()) {
            HStack(spacing: 12) {
                CampusGlyphView(glyph: .calendar, scale: 4)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    if let next = SharedAcademicCalendar.nextEvent() {
                        let days = SharedAcademicCalendar.daysUntil(next)
                        Text(next.title)
                            .font(.system(size: 17, weight: .semibold))
                            .multilineTextAlignment(.leading)
                        Text(days == 0 ? "就是今天" : "\(days) 天後")
                            .pixelFont(size: PixelMetrics.FontSize.small)
                    } else {
                        Text("學術行事曆").pixelFont(size: PixelMetrics.FontSize.small)
                        Text("查看全年行程").font(.system(size: 15))
                    }
                }
                Spacer(minLength: 0)
                // 像素箭頭
                Text(">").pixelFont(size: PixelMetrics.FontSize.medium)
            }
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        }
        .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold,
                                      contentPadding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)))
        .foregroundStyle(PixelPalette.ink)
    }

    // MARK: 區塊與格子

    private func section(title: String, items: [Entry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            NamePlate(text: title)
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 8
            ) {
                ForEach(items) { item in
                    cell(item)
                }
            }
        }
    }

    private func cell(_ item: Entry) -> some View {
        NavigationLink(destination: item.dest) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    CampusGlyphView(glyph: item.glyph, scale: 3)
                        .foregroundStyle(item.tint == PixelPalette.orange ? PixelPalette.ink : item.tint)
                    Spacer(minLength: 0)
                    Text(">").pixelFont(size: PixelMetrics.FontSize.small)
                }
                Text(item.title)
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .lineLimit(1)
                Text(item.sub)
                    .font(.system(size: 15))
                    .foregroundStyle(PixelPalette.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        }
        .buttonStyle(.pixel)
        .foregroundStyle(PixelPalette.ink)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PixelCampusHubView()
        .environment(\.appearanceStyle, .pixel)
}
