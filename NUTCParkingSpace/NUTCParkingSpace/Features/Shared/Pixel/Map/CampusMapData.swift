//
//  CampusMapData.swift
//  NUTCParkingSpace
//
//  像素校園地圖的資料層：只描述「格子座標」，不含任何繪製邏輯。
//  座標系：104 欄 x 72 列，原點在左上，x 向右、y 向下。
//  依新版三民校區地圖（design-demos/pixel/reference/sanmin-campus-map.webp，1456x1024）
//  的相對位置量化而來（每格約 14 x 14.2 原圖像素），北在上：
//  中商在北、中科在西、操場在中央偏東、體育館在南偏東、男女宿舍在東、
//  錦平街縱貫東側，中技大樓在錦平街東側的獨立街區。
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
    case track      // 操場跑道
    case gate       // 校門
    case outside    // 校外建築（太平國小）：只畫淡色方塊與名牌
}

struct CampusBuilding: Identifiable, Equatable {
    let id: String
    /// 完整名稱（無障礙／除錯用）
    let name: String
    /// 地圖上的名牌文字（2–4 字）
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

    /// 從課程教室字串（例如「中科大樓 702」「中正大樓 702」「資訊大樓 405」）比對到建築；對不到回傳 nil。
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
    /// 即時標記中心（格，校園鏡頭）
    let markerAt: GridPoint
    /// 停車鏡頭的標記中心（格）；nil 表示與校園鏡頭相同。展開版標記較大，需要時另外錯開。
    var parkingMarkerAt: GridPoint? = nil
    /// 是否有對應的 API 資料（false＝只畫地坪，不放即時標記）
    var live: Bool = true
    /// 車種：機車標記兩種鏡頭都畫；汽車標記只在停車鏡頭畫
    var vehicle: ParkingType = .motorcycle

    func accepts(name lotName: String, type: ParkingType) -> Bool {
        guard live, type == vehicle else { return false }
        if excludes.contains(where: { lotName.contains($0) }) { return false }
        return keywords.contains(where: { lotName.contains($0) })
    }
}

// MARK: - 校園資料

enum CampusMapData {
    static let columns = 104
    static let rows = 72

    // MARK: 道路與地面

    /// 土路（tan）
    static let roads: [GridRect] = [
        GridRect(x: 0, y: 1, w: 104, h: 4),    // 中華路（北）
        GridRect(x: 0, y: 67, w: 104, h: 3),   // 三民路（南）
        GridRect(x: 86, y: 0, w: 3, h: 72),    // 錦平街（東，南北向）
        GridRect(x: 15, y: 52, w: 3, h: 15),   // 西南汽機車車道（接三民路）
        GridRect(x: 57, y: 21, w: 3, h: 4),    // 中商南側步道
    ]

    /// 錦平街中線虛線
    static let roadDashes: [GridRect] = stride(from: 2, to: 70, by: 6).map {
        GridRect(x: 87, y: $0, w: 1, h: 3)
    }

    /// 操場內側草地
    static let trackInfield = GridRect(x: 56, y: 36, w: 17, h: 9)

    /// 花園廣場鋪面
    static let plaza = GridRect(x: 36, y: 46, w: 15, h: 14)
    /// 花園廣場噴水池中心（格）；池面 6x6
    static let fountainAt = GridPoint(x: 43, y: 51)
    /// 弘業樓與體育館之間的水池
    static let ponds: [GridRect] = [GridRect(x: 55, y: 52, w: 2, h: 8)]

    // MARK: 建築

    static let buildings: [CampusBuilding] = [
        CampusBuilding(
            id: "taiping", name: "太平國小（校外）", plate: "太平國小", aliases: [],
            rects: [GridRect(x: 18, y: 9, w: 20, h: 8)],
            kind: .outside, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 28, y: 13), flagAt: GridPoint(x: 28, y: 9)),
        CampusBuilding(
            id: "zhongshang", name: "中商大樓", plate: "中商", aliases: ["中商", "圖書館"],
            rects: [GridRect(x: 54, y: 7, w: 10, h: 14)],
            kind: .building, roof: PixelPalette.red,
            plateAt: GridPoint(x: 59, y: 14), flagAt: GridPoint(x: 59, y: 7)),
        CampusBuilding(
            id: "activity", name: "學生活動中心", plate: "學活", aliases: ["學生活動中心", "活動中心", "學活"],
            rects: [GridRect(x: 26, y: 26, w: 6, h: 12)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 29, y: 32), flagAt: GridPoint(x: 29, y: 26)),
        CampusBuilding(
            id: "chungming", name: "昌明樓", plate: "昌明", aliases: ["昌明"],
            rects: [GridRect(x: 34, y: 33, w: 5, h: 10), GridRect(x: 47, y: 33, w: 5, h: 10),
                    GridRect(x: 39, y: 37, w: 8, h: 4)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 43, y: 39), flagAt: GridPoint(x: 43, y: 37)),
        CampusBuilding(
            id: "hanying", name: "翰英樓", plate: "翰英", aliases: ["翰英"],
            rects: [GridRect(x: 52, y: 25, w: 23, h: 5)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 63, y: 28), flagAt: GridPoint(x: 63, y: 25)),
        CampusBuilding(
            id: "track", name: "運動場", plate: "運動場", aliases: ["運動場", "操場"],
            rects: [GridRect(x: 53, y: 34, w: 24, h: 13)],
            kind: .track, roof: PixelPalette.orange,
            plateAt: GridPoint(x: 65, y: 41), flagAt: GridPoint(x: 65, y: 34)),
        CampusBuilding(
            id: "girls-dorm", name: "女生宿舍", plate: "女宿", aliases: ["女生宿舍", "女宿"],
            rects: [GridRect(x: 78, y: 25, w: 5, h: 19)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 81, y: 34), flagAt: GridPoint(x: 80, y: 25)),
        CampusBuilding(
            id: "boys-dorm", name: "男生宿舍", plate: "男宿", aliases: ["男生宿舍", "男宿"],
            rects: [GridRect(x: 78, y: 45, w: 5, h: 11)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 81, y: 47), flagAt: GridPoint(x: 80, y: 45)),
        CampusBuilding(
            id: "qixiu", name: "奇秀樓", plate: "奇秀", aliases: ["奇秀"],
            rects: [GridRect(x: 65, y: 52, w: 12, h: 5)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 73, y: 53), flagAt: GridPoint(x: 71, y: 52)),
        CampusBuilding(
            id: "hongye", name: "弘業樓", plate: "弘業", aliases: ["弘業"],
            rects: [GridRect(x: 52, y: 49, w: 3, h: 15)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 50, y: 53), flagAt: GridPoint(x: 53, y: 49)),
        CampusBuilding(
            id: "gym", name: "體育館", plate: "體育館", aliases: ["體育館", "體育"],
            rects: [GridRect(x: 57, y: 50, w: 8, h: 14)],
            kind: .building, roof: PixelPalette.orange, striped: true,
            plateAt: GridPoint(x: 60, y: 59), flagAt: GridPoint(x: 61, y: 50)),
        // 中科大樓（原中正大樓）：舊名「中正」仍是課表常見寫法，一併比對
        CampusBuilding(
            id: "zhongke", name: "中科大樓", plate: "中科", aliases: ["中科", "中正"],
            rects: [GridRect(x: 19, y: 40, w: 9, h: 12), GridRect(x: 28, y: 42, w: 5, h: 9),
                    GridRect(x: 21, y: 39, w: 4, h: 1)],
            kind: .building, roof: PixelPalette.blue,
            plateAt: GridPoint(x: 24, y: 46), flagAt: GridPoint(x: 23, y: 39)),
        CampusBuilding(
            id: "info", name: "資訊館", plate: "資訊館", aliases: ["資訊大樓", "資訊館", "資訊"],
            rects: [GridRect(x: 19, y: 55, w: 8, h: 10)],
            kind: .building, roof: PixelPalette.teal,
            plateAt: GridPoint(x: 23, y: 62), flagAt: GridPoint(x: 22, y: 55)),
        CampusBuilding(
            id: "admin", name: "行政大樓", plate: "行政", aliases: ["行政"],
            rects: [GridRect(x: 27, y: 55, w: 6, h: 5)],
            kind: .building, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 32, y: 56), flagAt: GridPoint(x: 30, y: 55)),
        CampusBuilding(
            id: "incubator", name: "創新育成中心", plate: "育成", aliases: ["育成"],
            rects: [GridRect(x: 4, y: 57, w: 6, h: 8)],
            kind: .building, roof: PixelPalette.tan,
            plateAt: GridPoint(x: 7, y: 61), flagAt: GridPoint(x: 7, y: 57),
            plateVisible: false),  // 西南角擁擠且被資訊館停車標記占用，省略名牌
        CampusBuilding(
            id: "gate", name: "校門", plate: "校門", aliases: ["校門", "正門"],
            rects: [GridRect(x: 39, y: 63, w: 8, h: 3)],
            kind: .gate, roof: PixelPalette.paper2,
            plateAt: GridPoint(x: 43, y: 60), flagAt: GridPoint(x: 43, y: 63)),
        CampusBuilding(
            id: "zhongji", name: "中技大樓", plate: "中技", aliases: ["中技"],
            rects: [GridRect(x: 93, y: 32, w: 6, h: 11)],
            kind: .building, roof: PixelPalette.blue,
            plateAt: GridPoint(x: 96, y: 37), flagAt: GridPoint(x: 96, y: 32)),
    ]

    // MARK: 停車場

    /// 校區地圖上的停車區。`live == false` 者只畫地坪（API 沒有對應名稱）。
    /// 機車對照：中科平面、資訊館、錦平街、中技大樓；汽車對照：中商、中技、中科（只在停車鏡頭畫標記）。
    static let zones: [CampusParkingZone] = [
        // API 的「中科平面」＝新圖中科大樓西側的平面機車停車場
        CampusParkingZone(
            id: "zhongke-lot", name: "中科平面", keywords: ["中科平面"],
            rects: [GridRect(x: 8, y: 43, w: 9, h: 8)],
            markerAt: GridPoint(x: 11, y: 46), parkingMarkerAt: GridPoint(x: 12, y: 42)),
        // 新圖未標示資訊館停車場（舊圖為資訊館地下機車停車場）；API 仍有「資訊館」，沿用舊圖位置：
        // 標記放在資訊館／汽機車車道附近，不畫地坪
        CampusParkingZone(
            id: "info-basement", name: "資訊館", keywords: ["資訊館"],
            rects: [], underground: true,
            markerAt: GridPoint(x: 10, y: 62), parkingMarkerAt: GridPoint(x: 38, y: 62)),
        // 東南角近錦平街的機車停車場
        CampusParkingZone(
            id: "jinping", name: "錦平街", keywords: ["錦平街"],
            rects: [GridRect(x: 71, y: 58, w: 12, h: 6)],
            markerAt: GridPoint(x: 79, y: 62), parkingMarkerAt: GridPoint(x: 70, y: 63)),
        // 中技大樓南側機車停車場（錦平街東側街區）
        CampusParkingZone(
            id: "zhongji-moto", name: "中技大樓", keywords: ["中技大樓"], excludes: ["後方", "花園"],
            rects: [GridRect(x: 96, y: 47, w: 5, h: 5)],
            markerAt: GridPoint(x: 98, y: 50), parkingMarkerAt: GridPoint(x: 98, y: 52)),
        // 中商大樓西側機車停車場：API 沒有對應名稱，只畫地坪
        CampusParkingZone(
            id: "zhongshang-moto", name: "中商機車", keywords: [],
            rects: [GridRect(x: 47, y: 8, w: 4, h: 11)],
            markerAt: GridPoint(x: 49, y: 13), live: false),
        // 汽車：中商大樓東側汽車停車場
        CampusParkingZone(
            id: "zhongshang-car", name: "中商汽車", keywords: ["中商停車場"],
            rects: [GridRect(x: 70, y: 8, w: 4, h: 11)],
            markerAt: GridPoint(x: 72, y: 14), vehicle: .car),
        // 汽車：中技大樓南側汽車停車場
        CampusParkingZone(
            id: "zhongji-car", name: "中技汽車", keywords: ["中技停車場"],
            rects: [GridRect(x: 90, y: 47, w: 5, h: 5)],
            markerAt: GridPoint(x: 92, y: 49), parkingMarkerAt: GridPoint(x: 92, y: 32), vehicle: .car),
        // 汽車：中科停車場。新圖沒有明確標示，暫放西南汽機車車道（地下）——未查證
        CampusParkingZone(
            id: "zhongke-car", name: "中科汽車", keywords: ["中科停車場"],
            rects: [GridRect(x: 15, y: 56, w: 3, h: 9)], underground: true,
            markerAt: GridPoint(x: 16, y: 60), parkingMarkerAt: GridPoint(x: 13, y: 58), vehicle: .car),
    ]

    /// 把 API 回傳的停車場對到地圖上的停車區；對不到回傳 nil（呼叫端不畫標記）。
    static func zone(for lot: ParkingLot) -> CampusParkingZone? {
        zones.first { $0.accepts(name: lot.name, type: lot.type) }
    }

    // MARK: 樹

    /// 樹冠左上角（格）；樹冠 3x3 格
    static let trees: [GridPoint] = [
        // 中商兩側
        GridPoint(x: 44, y: 6), GridPoint(x: 44, y: 12), GridPoint(x: 44, y: 17),
        GridPoint(x: 66, y: 6), GridPoint(x: 66, y: 12), GridPoint(x: 66, y: 17),
        GridPoint(x: 75, y: 8), GridPoint(x: 75, y: 15),
        // 學活、中科周邊
        GridPoint(x: 22, y: 26), GridPoint(x: 22, y: 32), GridPoint(x: 27, y: 22), GridPoint(x: 33, y: 22),
        GridPoint(x: 4, y: 41), GridPoint(x: 4, y: 52), GridPoint(x: 33, y: 44), GridPoint(x: 33, y: 48),
        // 翰英與操場之間、操場西側
        GridPoint(x: 55, y: 31), GridPoint(x: 60, y: 31), GridPoint(x: 66, y: 31), GridPoint(x: 71, y: 31),
        GridPoint(x: 50, y: 35), GridPoint(x: 50, y: 40),
        // 宿舍東側
        GridPoint(x: 83, y: 27), GridPoint(x: 83, y: 33), GridPoint(x: 83, y: 39), GridPoint(x: 83, y: 47),
        GridPoint(x: 83, y: 53),
        // 花園廣場兩側、校門兩側
        GridPoint(x: 36, y: 47), GridPoint(x: 36, y: 56), GridPoint(x: 48, y: 47), GridPoint(x: 48, y: 56),
        GridPoint(x: 34, y: 62), GridPoint(x: 48, y: 62),
        // 東南角
        GridPoint(x: 67, y: 58), GridPoint(x: 83, y: 59),
        // 中技街區
        GridPoint(x: 90, y: 8), GridPoint(x: 98, y: 8), GridPoint(x: 90, y: 18), GridPoint(x: 98, y: 18),
        GridPoint(x: 90, y: 28), GridPoint(x: 99, y: 28), GridPoint(x: 90, y: 38), GridPoint(x: 99, y: 38),
    ]
}
