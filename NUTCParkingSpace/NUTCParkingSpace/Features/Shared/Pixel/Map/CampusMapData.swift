//
//  CampusMapData.swift
//  NUTCParkingSpace
//
//  像素校園地圖的資料層：只描述「格子座標」，不含任何繪製邏輯。
//  座標系：96 欄 x 64 列，原點在左上，x 向右、y 向下。
//  依三民校區機車停車場位置圖（CampusMap.imageset）的相對位置量化而來，
//  北在上：中商在北、中正在西南、操場在中央偏東、體育館在南、錦平街在東。
//

import SwiftUI

// MARK: - 基本型別

/// 格子座標的矩形（單位：格）
struct GridRect: Equatable {
    let x: Int
    let y: Int
    let w: Int
    let h: Int

    var maxX: Int { x + w }
    var maxY: Int { y + h }
}

/// 格子座標的點（單位：格）
struct GridPoint: Equatable {
    let x: Int
    let y: Int
}

/// 天氣狀態（地圖只需要分「晴」與「有雲」）
enum PixelWeather {
    case clear   // 晴天：小太陽，不移動
    case cloudy  // 多雲／陰／雨：雲緩慢橫移

    /// 由 Open-Meteo 天氣碼轉換（0、1 為晴）
    init(weatherCode: Int) {
        self = (weatherCode == 0 || weatherCode == 1) ? .clear : .cloudy
    }
}

// MARK: - 建築

enum CampusBuildingKind {
    case building   // 一般建築：屋頂＋牆面
    case court      // 球場
    case track      // 操場跑道
    case gate       // 校門
}

struct CampusBuilding: Identifiable, Equatable {
    let id: String
    /// 完整名稱（無障礙／除錯用）
    let name: String
    /// 地圖上的名牌文字（2–5 字）
    let plate: String
    /// 課程教室字串比對用的關鍵字
    let aliases: [String]
    let rects: [GridRect]
    let kind: CampusBuildingKind
    let roof: Color
    /// 屋頂改畫斜條紋（只有體育館）
    var striped: Bool = false
    /// 名牌中心（格）
    let plateAt: GridPoint
    /// 旗標底部（格）：建築上緣中央
    let flagAt: GridPoint
    /// 是否在校園鏡頭顯示名牌（擁擠處省略次要名牌）
    var plateVisible: Bool = true

    static func == (lhs: CampusBuilding, rhs: CampusBuilding) -> Bool { lhs.id == rhs.id }

    /// 從課程教室字串（例如「中正大樓 702」「資訊大樓 405」）比對到建築；對不到回傳 nil。
    /// 規則：關鍵字出現在字串中即命中，多個命中時取關鍵字最長者。
    static func match(location: String) -> CampusBuilding? {
        let text = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        var best: (building: CampusBuilding, length: Int)?
        for building in CampusMapData.buildings {
            for alias in building.aliases where text.contains(alias) {
                if best == nil || alias.count > best!.length {
                    best = (building, alias.count)
                }
            }
        }
        return best?.building
    }
}

// MARK: - 停車場

struct CampusParkingZone: Identifiable, Equatable {
    let id: String
    /// 地圖上的顯示名稱
    let name: String
    /// API 停車場名稱含有任一關鍵字即視為此區
    let keywords: [String]
    /// 名稱含有這些字則排除（避免「中技大樓」誤配到「中技大樓後方花園」）
    var excludes: [String] = []
    let rects: [GridRect]
    /// 地下停車場（用棋盤抖色表示）
    var underground: Bool = false
    /// 即時標記中心（格）
    let markerAt: GridPoint
    /// 是否有對應的 API 資料（false＝只畫地坪，不放即時標記）
    var live: Bool = true

    func accepts(name lotName: String, type: ParkingType) -> Bool {
        guard live, type == .motorcycle else { return false }
        if excludes.contains(where: { lotName.contains($0) }) { return false }
        return keywords.contains(where: { lotName.contains($0) })
    }
}

// MARK: - 校園資料

enum CampusMapData {
    static let columns = 96
    static let rows = 64

    // MARK: 道路與地面

    /// 土路（tan）
    static let roads: [GridRect] = [
        GridRect(x: 0, y: 22, w: 74, h: 2),    // 北側橫向步道（中商與翰英之間）
        GridRect(x: 0, y: 62, w: 74, h: 2),    // 南側校前道路
        GridRect(x: 74, y: 0, w: 4, h: 64),    // 錦平街（東側道路）
        GridRect(x: 44, y: 24, w: 1, h: 24),   // 中央縱向小徑
    ]

    /// 錦平街中線虛線（每 4 格一段）
    static let roadDashes: [GridRect] = stride(from: 2, to: 62, by: 6).map {
        GridRect(x: 75, y: $0, w: 2, h: 3)
    }

    /// 操場內側草地
    static let trackInfield = GridRect(x: 48, y: 33, w: 15, h: 8)

    // MARK: 建築

    static let buildings: [CampusBuilding] = [
        CampusBuilding(
            id: "zhongshang", name: "中商大樓", plate: "中商", aliases: ["中商"],
            rects: [GridRect(x: 45, y: 4, w: 10, h: 16), GridRect(x: 56, y: 4, w: 3, h: 16)],
            kind: .building, roof: PixelPalette.red,
            plateAt: GridPoint(x: 50, y: 11), flagAt: GridPoint(x: 50, y: 4)),
        CampusBuilding(
            id: "hanying", name: "翰英樓", plate: "翰英", aliases: ["翰英"],
            rects: [GridRect(x: 45, y: 25, w: 22, h: 5)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 56, y: 27), flagAt: GridPoint(x: 56, y: 25)),
        CampusBuilding(
            id: "dorm", name: "學生宿舍", plate: "宿舍", aliases: ["宿舍"],
            rects: [GridRect(x: 68, y: 24, w: 5, h: 29)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 70, y: 38), flagAt: GridPoint(x: 70, y: 24)),
        CampusBuilding(
            id: "activity", name: "學生活動中心", plate: "學活", aliases: ["學生活動中心", "活動中心", "學活"],
            rects: [GridRect(x: 20, y: 24, w: 7, h: 10)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 23, y: 28), flagAt: GridPoint(x: 23, y: 24)),
        CampusBuilding(
            id: "volleyball", name: "排球場", plate: "排球", aliases: ["排球場", "排球"],
            rects: [GridRect(x: 28, y: 24, w: 8, h: 5)],
            kind: .court, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 32, y: 26), flagAt: GridPoint(x: 32, y: 24)),
        CampusBuilding(
            id: "basketball", name: "籃球場", plate: "籃球", aliases: ["籃球場", "籃球"],
            rects: [GridRect(x: 37, y: 24, w: 7, h: 5)],
            kind: .court, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 40, y: 26), flagAt: GridPoint(x: 40, y: 24)),
        CampusBuilding(
            id: "chungming", name: "昌明樓", plate: "昌明", aliases: ["昌明"],
            rects: [GridRect(x: 28, y: 31, w: 4, h: 13), GridRect(x: 39, y: 31, w: 4, h: 13),
                    GridRect(x: 32, y: 36, w: 7, h: 3)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 35, y: 37), flagAt: GridPoint(x: 35, y: 36)),
        CampusBuilding(
            id: "track", name: "操場", plate: "操場", aliases: ["操場"],
            rects: [GridRect(x: 45, y: 31, w: 22, h: 12)],
            kind: .track, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 56, y: 37), flagAt: GridPoint(x: 56, y: 31)),
        CampusBuilding(
            id: "zhongzheng", name: "中正大樓", plate: "中正", aliases: ["中正"],
            rects: [GridRect(x: 13, y: 39, w: 14, h: 13), GridRect(x: 16, y: 37, w: 4, h: 2)],
            kind: .building, roof: PixelPalette.blue,
            plateAt: GridPoint(x: 20, y: 43), flagAt: GridPoint(x: 18, y: 37)),
        CampusBuilding(
            id: "admin", name: "行政大樓", plate: "行政", aliases: ["行政"],
            rects: [GridRect(x: 20, y: 53, w: 7, h: 4)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 27, y: 50), flagAt: GridPoint(x: 24, y: 53),
            plateVisible: false),
        CampusBuilding(
            id: "info", name: "資訊館", plate: "資訊館", aliases: ["資訊大樓", "資訊館", "資訊"],
            rects: [GridRect(x: 13, y: 53, w: 7, h: 4)],
            kind: .building, roof: PixelPalette.teal,
            plateAt: GridPoint(x: 16, y: 51), flagAt: GridPoint(x: 16, y: 53)),
        CampusBuilding(
            id: "gym", name: "體育館", plate: "體育館", aliases: ["體育館", "體育"],
            rects: [GridRect(x: 47, y: 48, w: 9, h: 14)],
            kind: .building, roof: PixelPalette.orange, striped: true,
            plateAt: GridPoint(x: 51, y: 57), flagAt: GridPoint(x: 51, y: 48)),
        CampusBuilding(
            id: "qixiu", name: "奇秀樓", plate: "奇秀", aliases: ["奇秀"],
            rects: [GridRect(x: 57, y: 48, w: 8, h: 5)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 62, y: 50), flagAt: GridPoint(x: 61, y: 48)),
        CampusBuilding(
            id: "zhongji", name: "中技大樓", plate: "中技", aliases: ["中技"],
            rects: [GridRect(x: 78, y: 18, w: 10, h: 10)],
            kind: .building, roof: PixelPalette.blue,
            plateAt: GridPoint(x: 83, y: 23), flagAt: GridPoint(x: 83, y: 18)),
        CampusBuilding(
            id: "frontgate", name: "正門", plate: "正門", aliases: ["正門"],
            rects: [GridRect(x: 29, y: 60, w: 14, h: 2)],
            kind: .gate, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 36, y: 58), flagAt: GridPoint(x: 36, y: 60)),
        CampusBuilding(
            id: "sidegate", name: "側門", plate: "側門", aliases: ["側門"],
            rects: [GridRect(x: 1, y: 60, w: 10, h: 2)],
            kind: .gate, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 6, y: 58), flagAt: GridPoint(x: 6, y: 60)),
    ]

    // MARK: 停車場

    /// 校區地圖上的 6 個機車停車場。`live == false` 者只畫地坪（API 沒有對應名稱）。
    static let zones: [CampusParkingZone] = [
        CampusParkingZone(
            id: "info-basement", name: "資訊館", keywords: ["資訊館"],
            rects: [GridRect(x: 13, y: 53, w: 14, h: 9)], underground: true,
            markerAt: GridPoint(x: 21, y: 60)),
        CampusParkingZone(
            id: "jinping", name: "錦平街", keywords: ["錦平街"],
            rects: [GridRect(x: 65, y: 55, w: 9, h: 4), GridRect(x: 70, y: 59, w: 4, h: 3)],
            markerAt: GridPoint(x: 68, y: 58)),
        CampusParkingZone(
            id: "zhongji-basement", name: "中技大樓", keywords: ["中技大樓"], excludes: ["後方", "花園"],
            rects: [GridRect(x: 78, y: 30, w: 10, h: 12)], underground: true,
            markerAt: GridPoint(x: 83, y: 36)),
        // API 的「中科平面」＝圖上中正大樓西側的中正機車停車場
        CampusParkingZone(
            id: "zhongzheng-lot", name: "中正機車", keywords: ["中科平面"],
            rects: [GridRect(x: 1, y: 39, w: 12, h: 13), GridRect(x: 1, y: 52, w: 4, h: 7)],
            markerAt: GridPoint(x: 7, y: 41)),
        // 以下兩處 API 沒有逐場資料，只畫地坪
        CampusParkingZone(
            id: "zhongshang-lot", name: "中商", keywords: [],
            rects: [GridRect(x: 39, y: 3, w: 4, h: 19)],
            markerAt: GridPoint(x: 41, y: 12), live: false),
        CampusParkingZone(
            id: "zhongji-garden-lot", name: "中技後方花園", keywords: ["後方花園"],
            rects: [GridRect(x: 89, y: 24, w: 7, h: 19)],
            markerAt: GridPoint(x: 92, y: 33), live: false),
    ]

    /// 把 API 回傳的停車場對到地圖上的停車區；對不到回傳 nil（呼叫端不畫標記）。
    static func zone(for lot: ParkingLot) -> CampusParkingZone? {
        zones.first { $0.accepts(name: lot.name, type: lot.type) }
    }

    // MARK: 樹

    /// 樹冠左上角（格）；樹冠 3x3 格
    static let trees: [GridPoint] = [
        GridPoint(x: 2, y: 4), GridPoint(x: 8, y: 9), GridPoint(x: 14, y: 3), GridPoint(x: 24, y: 8),
        GridPoint(x: 30, y: 14), GridPoint(x: 3, y: 28), GridPoint(x: 11, y: 31), GridPoint(x: 15, y: 25),
        GridPoint(x: 29, y: 46), GridPoint(x: 36, y: 49), GridPoint(x: 31, y: 54), GridPoint(x: 40, y: 52),
        GridPoint(x: 44, y: 55), GridPoint(x: 28, y: 20), GridPoint(x: 62, y: 14), GridPoint(x: 66, y: 8),
        GridPoint(x: 60, y: 56), GridPoint(x: 90, y: 6), GridPoint(x: 84, y: 48), GridPoint(x: 91, y: 52),
        GridPoint(x: 79, y: 56), GridPoint(x: 88, y: 12),
    ]
}
