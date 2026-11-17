//
//  PixelCampusMapView.swift
//  NUTCParkingSpace
//
//  像素校園地圖：Canvas 逐格繪製靜態地形，動態內容（名牌、標記、旗標、天氣）
//  以 SwiftUI View 疊在上面。所有座標對齊裝置實體像素，不使用模糊與陰影。
//

import SwiftUI
import CoreLocation

/// 地圖鏡頭
enum PixelMapCamera {
    /// 整個校園：建築上色、顯示名牌（給首頁）
    case campus
    /// 停車場鏡頭：非停車場建築淡化為單色、隱藏名牌，停車區加金色外框，
    /// 標記改為展開版（含停車場名稱與狀態章），給停車頁用。
    case parking
}

// MARK: - 版面換算

private struct MapLayout {
    /// 名目每格邊長（pt）= floor(寬 x displayScale / 格數) / displayScale，為整數實體像素
    let cell: CGFloat
    let size: CGSize
    private let scale: CGFloat
    /// 每格的實體像素數（可含小數）；各格邊界各自四捨五入到整數像素，
    /// 讓地圖撐滿寬度（誤差 < 1 實體像素），格寬只會是 floor 或 floor+1 像素
    private let pxPerCell: CGFloat

    init(width: CGFloat, scale: CGFloat) {
        let s = max(scale, 1)
        self.scale = s
        let widthPx = (width * s).rounded(.down)
        pxPerCell = widthPx / CGFloat(CampusMapData.columns)
        cell = max(1, pxPerCell.rounded(.down)) / s
        size = CGSize(width: widthPx / s,
                      height: (pxPerCell * CGFloat(CampusMapData.rows)).rounded() / s)
    }

    /// 格座標轉 pt，並對齊實體像素
    func x(_ g: Int) -> CGFloat { (CGFloat(g) * pxPerCell).rounded() / scale }
    func y(_ g: Int) -> CGFloat { (CGFloat(g) * pxPerCell).rounded() / scale }

    /// 任意 pt 值對齊實體像素
    func snap(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }

    func rect(_ r: GridRect) -> CGRect {
        CGRect(x: x(r.x), y: y(r.y), width: x(r.maxX) - x(r.x), height: y(r.maxY) - y(r.y))
    }

    func point(_ p: GridPoint) -> CGPoint {
        CGPoint(x: x(p.x), y: y(p.y))
    }
}

// MARK: - 繪製

/// 靜態地形繪製器（資料與繪製分離：只讀 CampusMapData）
private struct CampusPainter {
    let layout: MapLayout
    let context: GraphicsContext
    let dimmed: Bool
    let highlightZones: Bool

    private var c: CGFloat { layout.cell }
    private var u: CGFloat { PixelMetrics.unit }

    private func fill(_ rect: CGRect, _ color: Color) {
        context.fill(Path(rect), with: .color(color))
    }

    /// 兩塊矩形組成的「切角塊」：四角各缺 cut 的一格
    private func blob(_ rect: CGRect, cut: CGFloat, inflate: CGFloat = 0, color: Color) {
        fill(CGRect(x: rect.minX + cut - inflate, y: rect.minY - inflate,
                    width: rect.width - 2 * cut + 2 * inflate, height: rect.height + 2 * inflate), color)
        fill(CGRect(x: rect.minX - inflate, y: rect.minY + cut - inflate,
                    width: rect.width + 2 * inflate, height: rect.height - 2 * cut + 2 * inflate), color)
    }

    func paint() {
        paintGround()
        paintRoads()
        paintPlaza()
        paintTrack()
        paintZones()
        CampusMapData.buildings.filter { $0.kind == .building || $0.kind == .outside }.forEach(paintBuilding)
        CampusMapData.buildings.filter { $0.kind == .gate }.forEach(paintGate)
        paintTrees()
    }

    // 草地與草叢（確定性雜湊，每次畫面相同）
    private func paintGround() {
        fill(CGRect(origin: .zero, size: layout.size), PixelPalette.grass)
        for gy in 0..<CampusMapData.rows {
            for gx in 0..<CampusMapData.columns where (gx * 73 + gy * 151 + gx * gy * 7) % 37 == 0 {
                let x = layout.x(gx)
                let y = layout.y(gy)
                fill(CGRect(x: x, y: y, width: u, height: u), PixelPalette.grassD)
                fill(CGRect(x: x + u, y: y + u, width: u, height: u), PixelPalette.grassD)
            }
        }
    }

    private func paintRoads() {
        for road in CampusMapData.roads { fill(layout.rect(road), PixelPalette.tan) }
        for dash in CampusMapData.roadDashes { fill(layout.rect(dash), PixelPalette.paper2) }
    }

    private func paintTrack() {
        guard let track = CampusMapData.buildings.first(where: { $0.kind == .track }) else { return }
        let outer = layout.rect(track.rects[0])
        blob(outer, cut: 2 * c, inflate: u, color: PixelPalette.ink)
        // 紅色跑道、綠色場地（停車鏡頭淡化為單色）
        blob(outer, cut: 2 * c, color: dimmed ? PixelPalette.paper2 : track.roof)
        let infield = layout.rect(CampusMapData.trackInfield)
        blob(infield, cut: 2 * c, inflate: u, color: PixelPalette.ink)
        blob(infield, cut: 2 * c, color: dimmed ? PixelPalette.paper : PixelPalette.grass)
    }

    /// 花園廣場：鋪面（淡色方磚交錯）＋噴水池＋弘業樓旁水池
    private func paintPlaza() {
        let plaza = layout.rect(CampusMapData.plaza)
        fill(plaza.insetBy(dx: -u, dy: -u), PixelPalette.ink)
        fill(plaza, PixelPalette.paper)
        if !dimmed {
            let tile = 2 * c
            let cols = Int((plaza.width / tile).rounded(.down))
            let rows = Int((plaza.height / tile).rounded(.down))
            for j in 0..<rows {
                for i in 0..<cols where (i + j) % 2 == 0 {
                    fill(CGRect(x: plaza.minX + CGFloat(i) * tile, y: plaza.minY + CGFloat(j) * tile,
                                width: tile, height: tile), PixelPalette.paper2)
                }
            }
        }
        let center = layout.point(CampusMapData.fountainAt)
        let pool = CGRect(x: center.x - 3 * c, y: center.y - 3 * c, width: 6 * c, height: 6 * c)
        blob(pool, cut: c, inflate: u, color: PixelPalette.ink)
        blob(pool, cut: c, color: dimmed ? PixelPalette.paper2 : PixelPalette.water)
        fill(CGRect(x: center.x - c, y: center.y - c, width: 2 * c, height: 2 * c), PixelPalette.paper)
        for pond in CampusMapData.ponds {
            let r = layout.rect(pond)
            fill(r.insetBy(dx: -u, dy: -u), PixelPalette.ink)
            fill(r, dimmed ? PixelPalette.paper2 : PixelPalette.water)
        }
    }

    private func paintZones() {
        for zone in CampusMapData.zones {
            let rects = zone.rects.map(layout.rect)
            if highlightZones && zone.live {
                // 金色外框：標出有即時資料的停車區
                for r in rects { fill(r.insetBy(dx: -2 * u, dy: -2 * u), PixelPalette.gold) }
            }
            for r in rects { fill(r.insetBy(dx: -u, dy: -u), PixelPalette.ink) }
            for r in rects { fill(r, PixelPalette.asphalt) }
            for r in rects {
                if zone.underground {
                    paintChecker(r)
                } else {
                    paintStalls(r)
                }
            }
        }
    }

    /// 車格紋：寬面在上下緣畫短線，窄長面在左右緣畫短線
    private func paintStalls(_ r: CGRect) {
        let line = PixelPalette.paper2
        if r.height > r.width * 1.5 {
            var y = r.minY + c
            while y < r.maxY - c {
                fill(CGRect(x: r.minX + c, y: y, width: c, height: u), line)
                fill(CGRect(x: r.maxX - 2 * c, y: y, width: c, height: u), line)
                y += 2 * c
            }
        } else {
            var x = r.minX + c
            while x < r.maxX - c {
                fill(CGRect(x: x, y: r.minY + c, width: u, height: 2 * c), line)
                if r.height >= 8 * c {
                    fill(CGRect(x: x, y: r.maxY - 3 * c, width: u, height: 2 * c), line)
                }
                x += 2 * c
            }
        }
    }

    /// 地下停車場：棋盤抖色（2pt 方格交錯），表示「在地下、較暗」
    private func paintChecker(_ r: CGRect) {
        let cols = Int(r.width / u)
        let rows = Int(r.height / u)
        for j in 0..<rows {
            for i in 0..<cols where (i + j) % 2 == 0 {
                fill(CGRect(x: r.minX + CGFloat(i) * u, y: r.minY + CGFloat(j) * u, width: u, height: u),
                     PixelPalette.ink)
            }
        }
    }

    private func isBottomExposed(_ rect: GridRect, in building: CampusBuilding) -> Bool {
        !building.rects.contains { other in
            other != rect && other.y == rect.maxY && other.x < rect.maxX && other.maxX > rect.x
        }
    }

    private func paintBuilding(_ b: CampusBuilding) {
        let rects = b.rects.map(layout.rect)
        for r in rects { fill(r.insetBy(dx: -u, dy: -u), PixelPalette.ink) }
        // 校外建築（太平國小）一律淡色，不搶校內建築的視覺
        let roofColor = (dimmed || b.kind == .outside) ? PixelPalette.paper2 : b.roof
        for r in rects { fill(r, roofColor) }

        // 斜條紋屋頂（體育館）：橘色直條紋
        if b.striped && !dimmed {
            for r in rects {
                var x = r.minX
                while x < r.maxX {
                    fill(CGRect(x: x, y: r.minY, width: c, height: r.height), PixelPalette.paper2)
                    x += 2 * c
                }
            }
        }

        // 牆面：每個矩形下緣 2 格，墨線分隔，窗戶每 2 格一扇
        for (index, gridRect) in b.rects.enumerated() where isBottomExposed(gridRect, in: b) {
            let r = rects[index]
            let wallH = r.height >= 3 * c ? 2 * c : c
            let wallY = r.maxY - wallH
            fill(CGRect(x: r.minX, y: wallY, width: r.width, height: wallH),
                 dimmed ? PixelPalette.paper : PixelPalette.paper2)
            fill(CGRect(x: r.minX, y: wallY, width: r.width, height: u), PixelPalette.ink)
            if !dimmed && wallH - 2 * u > 0 {
                var x = r.minX + c
                while x + c <= r.maxX - c + 0.01 {
                    fill(CGRect(x: x, y: wallY + u, width: c, height: wallH - 2 * u), PixelPalette.water)
                    x += 2 * c
                }
            }
        }
    }

    private func paintGate(_ b: CampusBuilding) {
        let r = layout.rect(b.rects[0])
        fill(r.insetBy(dx: -u, dy: -u), PixelPalette.ink)
        fill(r, PixelPalette.paper2)
        // 兩端門柱
        fill(CGRect(x: r.minX, y: r.minY, width: c, height: r.height), PixelPalette.ink)
        fill(CGRect(x: r.maxX - c, y: r.minY, width: c, height: r.height), PixelPalette.ink)
    }

    private func paintTrees() {
        for t in CampusMapData.trees {
            let canopy = layout.rect(GridRect(x: t.x, y: t.y, w: 3, h: 3))
            blob(canopy, cut: c, inflate: u, color: PixelPalette.ink)
            blob(canopy, cut: c, color: PixelPalette.grassD)
            fill(CGRect(x: canopy.minX + c, y: canopy.maxY, width: c, height: u), PixelPalette.ink)
        }
    }
}

// MARK: - 小型點陣圖（雲、太陽、旗子）

/// 以字元表繪製的點陣圖；`.` 為空格，其他字元對應 palette
private struct PixelBitmap: View {
    let rows: [String]
    let palette: [Character: Color]
    let cell: CGFloat

    var body: some View {
        Canvas { context, _ in
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    context.fill(Path(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell,
                                             width: cell, height: cell)),
                                 with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(rows.first?.count ?? 0) * cell,
               height: CGFloat(rows.count) * cell)
        .accessibilityHidden(true)
    }
}

private enum Sprites {
    static let cloud = [
        "......XXXX......",
        "...XXXXXXXXX.XX.",
        "..XXXXXXXXXXXXXX",
        ".XXXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXXXX",
        ".XXXXXXXXXXXXXX.",
    ]
    static let sun = [
        "....Y..Y....",
        "....Y..Y....",
        "..YYYYYYYY..",
        "...YYYYYY...",
        "YY.YYYYYY.YY",
        "...YYYYYY...",
        "..YYYYYYYY..",
        "....Y..Y....",
        "....Y..Y....",
    ]
    /// I = 墨色旗桿與框，G = 金色旗面
    static let flag = [
        "IIIIII..",
        "IGGGGGI.",
        "IGGGGGGI",
        "IGGGGGI.",
        "IIIIII..",
        "II......",
        "II......",
        "II......",
        "II......",
        "II......",
    ]
}

// MARK: - 地圖

struct PixelCampusMapView: View {
    var camera: PixelMapCamera = .campus
    /// 即時停車資料（對不到地圖位置的停車場不畫標記）
    var lots: [ParkingLot] = []
    /// 下一堂課所在建築；nil 不插旗
    var highlightBuilding: CampusBuilding? = nil
    /// 旗標文字，請保持在 5 字內（例如「28 分」「14:10」），避免蓋住其他名牌
    var highlightText: String? = nil
    var weather: PixelWeather = .cloudy
    var onSelectLot: (ParkingLot) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geo in
            let layout = MapLayout(width: geo.size.width, scale: displayScale)
            ZStack(alignment: .topLeading) {
                terrain(layout)
                if camera == .campus { plates(layout) }
                weatherLayer(layout)
                markers(layout)
                flag(layout)
            }
            .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
            .clipped()
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(CGFloat(CampusMapData.columns) / CGFloat(CampusMapData.rows), contentMode: .fit)
        .background(PixelPalette.grass)
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("三民校區地圖，機車剩餘共 \(totalMotorcycleAvailable) 位")
    }

    private var totalMotorcycleAvailable: Int {
        lots.filter { $0.type == .motorcycle }.reduce(0) { $0 + $1.availableCount }
    }

    // MARK: 圖層

    private func terrain(_ layout: MapLayout) -> some View {
        Canvas { context, _ in
            CampusPainter(layout: layout, context: context,
                          dimmed: camera == .parking, highlightZones: camera == .parking).paint()
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .accessibilityHidden(true)
    }

    private func plates(_ layout: MapLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(CampusMapData.buildings.filter { $0.plateVisible }) { b in
                NamePlate(text: b.plate)
                    .fixedSize()
                    .position(layout.point(b.plateAt))
            }
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    // 天氣：晴天為固定小太陽；其餘為雲，每秒推進一步（每步 2pt），Reduce Motion 時固定位置
    @ViewBuilder
    private func weatherLayer(_ layout: MapLayout) -> some View {
        let c = layout.cell
        switch weather {
        case .clear:
            PixelBitmap(rows: Sprites.sun, palette: ["Y": PixelPalette.gold], cell: c)
                .position(x: 6 * c + 6 * c, y: 3 * c + 4.5 * c)
                .accessibilityHidden(true)
        case .cloudy:
            let cloudW = CGFloat(Sprites.cloud[0].count) * c
            if reduceMotion {
                cloud(layout, x: layout.size.width * 0.55)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let period = Int((layout.size.width + cloudW) / PixelMetrics.unit)
                    let step = Int(timeline.date.timeIntervalSinceReferenceDate) % max(period, 1)
                    cloud(layout, x: -cloudW + CGFloat(step) * PixelMetrics.unit)
                }
            }
        }
    }

    private func cloud(_ layout: MapLayout, x: CGFloat) -> some View {
        let c = layout.cell
        return ZStack(alignment: .topLeading) {
            // 雲影：半透明墨色，位移 (8, 12)
            PixelBitmap(rows: Sprites.cloud, palette: ["X": PixelPalette.ink.opacity(0.18)], cell: c)
                .offset(x: 2 * PixelMetrics.shadowOffset, y: 3 * PixelMetrics.shadowOffset)
            PixelBitmap(rows: Sprites.cloud, palette: ["X": PixelPalette.paper], cell: c)
        }
        .offset(x: x, y: 2 * c)
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    // 即時停車標記：每個標記是獨立的按鈕元素
    private func markers(_ layout: MapLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(lots) { lot in
                // 汽車標記只在停車鏡頭畫；機車標記兩種鏡頭都畫
                if let zone = CampusMapData.zone(for: lot),
                   camera == .parking || zone.vehicle == .motorcycle {
                    LotMarker(lot: lot, zone: zone, expanded: camera == .parking) {
                        onSelectLot(lot)
                    }
                    .fixedSize()
                    .position(markerCenter(zone, layout))
                }
            }
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
    }

    // 下一堂課旗標：旗面在建築上緣，文字名牌依序嘗試「上、右、左」，避開其他名牌與停車標記
    @ViewBuilder
    private func flag(_ layout: MapLayout) -> some View {
        if let building = highlightBuilding {
            let text = highlightText ?? "下一堂"
            let geo = flagGeometry(layout, building: building, text: text)

            Group {
                if reduceMotion {
                    flagBody(geo: geo, text: text, layout: layout, up: false)
                } else {
                    // 2 格式（離散）跳動：每 0.5 秒在 0 與 -4pt 間切換
                    TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                        let up = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 1
                        flagBody(geo: geo, text: text, layout: layout, up: up)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("下一堂課 \(text)，\(building.name)")
        }
    }

    private struct FlagGeometry {
        let sprite: CGRect
        let label: CGRect
    }

    /// 名牌的估計尺寸（像素字 12pt 每字 12pt 寬，左右各 8pt、上下各 4pt 內距）
    private func plateSize(_ text: String) -> CGSize {
        CGSize(width: CGFloat(text.count) * 12 + 16, height: 24)
    }

    /// 地圖上已被占用的矩形：建築名牌與（首頁鏡頭的）停車標記
    private func occupiedRects(_ layout: MapLayout) -> [CGRect] {
        var rects: [CGRect] = []
        for b in CampusMapData.buildings where b.plateVisible {
            let size = plateSize(b.plate)
            let c = layout.point(b.plateAt)
            rects.append(CGRect(x: c.x - size.width / 2, y: c.y - size.height / 2,
                                width: size.width, height: size.height))
        }
        for lot in lots {
            guard let zone = CampusMapData.zone(for: lot),
                  camera == .parking || zone.vehicle == .motorcycle else { continue }
            let c = markerCenter(zone, layout)
            rects.append(CGRect(x: c.x - 30, y: c.y - 22, width: 60, height: 44))
        }
        return rects
    }

    private func markerCenter(_ zone: CampusParkingZone, _ layout: MapLayout) -> CGPoint {
        let p = layout.point(camera == .parking ? (zone.parkingMarkerAt ?? zone.markerAt) : zone.markerAt)
        // 展開版標記較高，避免被地圖下緣裁切
        // 左右也夾在地圖內，避免標記被裁切
        let half: CGFloat = camera == .parking ? 48 : 30
        return CGPoint(x: min(max(p.x, half), layout.size.width - half),
                       y: min(p.y, layout.size.height - (camera == .parking ? 32 : 24)))
    }

    private func flagGeometry(_ layout: MapLayout, building: CampusBuilding, text: String) -> FlagGeometry {
        let u = PixelMetrics.unit
        let spriteW = CGFloat(Sprites.flag[0].count) * u
        let spriteH = CGFloat(Sprites.flag.count) * u
        let label = plateSize(text)
        let base = layout.point(building.flagAt)
        let bx = min(max(base.x, 6), layout.size.width - spriteW)
        let by = max(base.y, spriteH + 2)
        let sprite = CGRect(x: bx - u, y: by - spriteH, width: spriteW, height: spriteH)

        let bounds = CGRect(origin: .zero, size: layout.size)
        let above = CGRect(x: min(max(bx - label.width / 2, 2), layout.size.width - label.width - 2),
                           y: sprite.minY - label.height, width: label.width, height: label.height)
        let right = CGRect(x: sprite.maxX, y: sprite.minY - 2, width: label.width, height: label.height)
        let left = CGRect(x: sprite.minX - label.width, y: sprite.minY - 2, width: label.width, height: label.height)

        let busy = occupiedRects(layout)
        func overlap(_ r: CGRect) -> CGFloat {
            busy.reduce(0) { sum, o in
                let i = r.intersection(o.insetBy(dx: -2, dy: -2))
                return sum + (i.isNull ? 0 : i.width * i.height)
            }
        }
        // 超出地圖邊界的候選加重罰分；其餘取重疊面積最小者（順序即偏好）
        let candidates = [above, right, left]
        let best = candidates.min { a, b in
            let pa = overlap(a) + (bounds.contains(a) ? 0 : 1_000_000)
            let pb = overlap(b) + (bounds.contains(b) ? 0 : 1_000_000)
            return pa < pb
        } ?? above
        return FlagGeometry(sprite: sprite, label: best)
    }

    private func flagBody(geo: FlagGeometry, text: String, layout: MapLayout, up: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            NamePlate(text: text, fill: PixelPalette.gold, textColor: PixelPalette.ink)
                .fixedSize()
                .position(x: geo.label.midX, y: geo.label.midY)
            PixelBitmap(rows: Sprites.flag,
                        palette: ["I": PixelPalette.ink, "G": PixelPalette.gold],
                        cell: PixelMetrics.unit)
                .position(x: geo.sprite.midX, y: geo.sprite.midY)
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        .offset(y: up ? -PixelMetrics.shadowOffset : 0)
    }
}

// MARK: - 停車標記

/// 沿用像素按鈕外觀，但觸控區至少 44x44pt（視覺大小不變，多出的範圍透明）
private struct LotMarkerButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        PixelButtonStyle(
            fill: fill,
            contentPadding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .makeBody(configuration: configuration)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

private struct LotMarker: View {
    let lot: ParkingLot
    let zone: CampusParkingZone
    /// true：停車鏡頭，顯示名稱與狀態章；false：首頁鏡頭，只顯示形狀圖示與剩餘數
    let expanded: Bool
    let onTap: () -> Void

    private var status: PixelStatus { .forLot(lot) }

    var body: some View {
        Button(action: onTap) {
            if expanded {
                VStack(spacing: 2) {
                    Text(zone.name)
                        .pixelFont(size: PixelMetrics.FontSize.small)
                    HStack(spacing: 4) {
                        StatusChip(status: status)
                        Text("\(lot.availableCount)")
                            .pixelFont(size: PixelMetrics.FontSize.small)
                    }
                }
                .foregroundStyle(PixelPalette.ink)
            } else {
                HStack(spacing: 4) {
                    // 形狀編碼：圓＝充足、三角＝緊張、叉＝滿位
                    PixelIcon(kind: status.icon, scale: 1, color: status.foreground)
                    Text("\(lot.availableCount)")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(status.foreground)
                }
            }
        }
        .buttonStyle(LotMarkerButtonStyle(
            fill: expanded ? PixelPalette.paper : status.fill))
        .accessibilityLabel("\(zone.name)\(zone.vehicle == .car ? "汽車" : "機車")停車場，剩餘 \(lot.availableCount) 位，\(status.label)")
        .accessibilityHint("查看停車場詳情")
    }
}

// MARK: - 預覽

#if DEBUG
enum PixelMapSampleData {
    static func lot(_ name: String, total: Int, available: Int, type: ParkingType = .motorcycle) -> ParkingLot {
        ParkingLot(name: name, totalCapacity: total, availableCount: available,
                   coordinate: CLLocationCoordinate2D(latitude: 24.1497, longitude: 120.6840),
                   lastUpdated: Date(), type: type)
    }

    /// 假資料：機車四處、汽車三處，外加一個對不到地圖的名稱
    static let lots: [ParkingLot] = [
        lot("資訊館", total: 177, available: 58),
        lot("錦平街", total: 515, available: 7),
        lot("中技大樓", total: 449, available: 0),
        lot("中科平面", total: 120, available: 40),
        lot("中商停車場", total: 90, available: 12, type: .car),
        lot("中技停車場", total: 60, available: 25, type: .car),
        lot("中科停車場", total: 80, available: 0, type: .car),
        lot("未知停車場", total: 30, available: 5),   // 對不到地圖：安全略過
    ]
}

#Preview("校園鏡頭") {
    PixelCampusMapView(camera: .campus,
                       lots: PixelMapSampleData.lots,
                       highlightBuilding: CampusBuilding.match(location: "中科大樓 702"),
                       highlightText: "28 分",
                       weather: .cloudy)
        .padding(.vertical, 24)
        .background(PixelPalette.paper2)
}

#Preview("停車鏡頭") {
    PixelCampusMapView(camera: .parking,
                       lots: PixelMapSampleData.lots,
                       weather: .clear)
        .padding(.vertical, 24)
        .background(PixelPalette.paper2)
}
#endif
