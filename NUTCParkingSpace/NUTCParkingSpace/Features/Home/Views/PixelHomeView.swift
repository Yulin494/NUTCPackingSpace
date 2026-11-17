//
//  PixelHomeView.swift
//  NUTCParkingSpace
//
//  像素模式首頁（概念 C「像素校園地圖」第一個畫面）。
//  資料全部由 HomeView 傳入（課程、作業、天氣、車位、刷新動作），本檔不另抓資料。
//  上半：像素校園地圖＋天氣小卡；下半：今日課程、待辦作業、機車車位、行事曆。
//

import SwiftUI
import NUTCParkingShared

struct PixelHomeView: View {
    /// 全部課程（只用來判斷是否已匯入課表，沿用原 HomeView 的空狀態規則）
    let courses: [Course]
    /// 今日課程（已排序）
    let todayCourses: [Course]
    /// 待辦作業（已排序、最多 3 筆）
    let pendingHomework: [HomeworkItem]
    let weather: SharedWeatherData?
    let parkingLots: [ParkingLotData]
    /// 節次對應的開始時間（時、分）
    let periodTimes: [(Int, Int)]
    /// 下拉刷新與首次載入共用 HomeView 的 refresh
    let refresh: () async -> Void

    @State private var selectedLot: ParkingLot?

    // MARK: 衍生資料

    private var mapLots: [ParkingLot] { parkingLots.map(ParkingLot.init(data:)) }

    private var pixelWeather: PixelWeather {
        guard let weather else { return .clear }
        return PixelWeather(weatherCode: weather.weatherCode)
    }

    private func startTime(_ course: Course) -> (Int, Int)? {
        guard course.startPeriod >= 1, course.startPeriod <= periodTimes.count else { return nil }
        return periodTimes[course.startPeriod - 1]
    }

    /// 下一堂（今天尚未開始的第一堂）與距離分鐘數
    private var nextCourse: (course: Course, minutes: Int)? {
        let c = Calendar.current
        let now = c.component(.hour, from: Date()) * 60 + c.component(.minute, from: Date())
        for course in todayCourses {
            guard let t = startTime(course) else { continue }
            let start = t.0 * 60 + t.1
            if start > now { return (course, start - now) }
        }
        return nil
    }

    /// 旗標文字：1 小時內顯示「N 分」，否則顯示開始時間
    private func flagText(_ next: (course: Course, minutes: Int)) -> String {
        if next.minutes < 60 { return "\(next.minutes) 分" }
        guard let t = startTime(next.course) else { return "下一堂" }
        return String(format: "%d:%02d", t.0, t.1)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "早安" }
        if h < 18 { return "午安" }
        return "晚安"
    }

    // MARK: 畫面

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    mapSection
                    selectionStrip
                    VStack(alignment: .leading, spacing: 24) {
                        headerRow
                        if !courses.isEmpty { coursesSection }
                        if !pendingHomework.isEmpty { homeworkSection }
                        if !parkingLots.isEmpty { parkingSection }
                        calendarSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(PixelPalette.paper2.ignoresSafeArea())
            .foregroundStyle(PixelPalette.ink)
            .navigationBarHidden(true)
            .refreshable { await refresh() }
            .task { await refresh() }
        }
    }

    // MARK: 地圖

    private var mapSection: some View {
        let next = nextCourse
        let building = next.flatMap { CampusBuilding.match(location: $0.course.room) }
        return ZStack(alignment: .topTrailing) {
            PixelCampusMapView(
                camera: .campus,
                lots: mapLots,
                highlightBuilding: building,
                highlightText: building == nil ? nil : next.map(flagText),
                weather: pixelWeather,
                onSelectLot: { selectedLot = $0 })
            weatherCard
                .padding(.top, 4)
                .padding(.trailing, 4)
        }
        // 草地色延伸到狀態列後方，地圖上方不留白
        .background(PixelPalette.grass.ignoresSafeArea(edges: .top))
    }

    private var weatherCard: some View {
        NavigationLink {
            WeatherView()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if let weather {
                    HStack(spacing: 4) {
                        PixelIcon(kind: .cloud, scale: 2, color: PixelPalette.ink)
                        Text("\(Int(weather.temperature.rounded()))°")
                            .pixelFont(size: PixelMetrics.FontSize.medium)
                    }
                    Text(weather.description)
                        .font(.subheadline)
                } else {
                    PixelIcon(kind: .cloud, scale: 2, color: PixelPalette.ink)
                    Text("看天氣")
                        .font(.subheadline)
                }
            }
            .foregroundStyle(PixelPalette.ink)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(PixelButtonStyle(
            fill: PixelPalette.paper,
            contentPadding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)))
        .accessibilityLabel(weather.map { "天氣 \(Int($0.temperature.rounded())) 度，\($0.description)" } ?? "查看天氣")
    }

    /// 點選停車標記後的回饋列（原 HomeView 沒有停車導覽，這裡只做選取回饋）
    private var selectionStrip: some View {
        HStack(spacing: 8) {
            if let lot = selectedLot {
                let status = PixelStatus.forLot(lot)
                Text(CampusMapData.zone(for: lot)?.name ?? lot.name)
                    .pixelFont(size: PixelMetrics.FontSize.small)
                Text("剩 \(lot.availableCount) 位")
                    .font(.subheadline)
                StatusChip(status: status)
            } else {
                Text(parkingLots.isEmpty ? "尚無即時車位資料，下拉可重新整理" : "點地圖上的停車標記，查看剩餘車位")
                    .font(.subheadline)
                    .foregroundStyle(PixelPalette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(PixelPalette.paper)
        .overlay(alignment: .top) {
            Rectangle().fill(PixelPalette.ink).frame(height: PixelMetrics.border)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(PixelPalette.ink).frame(height: PixelMetrics.border)
        }
    }

    // MARK: 問候列

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting)，同學")
                    .pixelFont(size: PixelMetrics.FontSize.medium)
                Text(Date().formatted(.dateTime.year().month().day().weekday(.wide).locale(Locale(identifier: "zh_Hant_TW"))))
                    .font(.subheadline)
                    .foregroundStyle(PixelPalette.muted)
            }
            Spacer(minLength: 0)
            NavigationLink {
                AcademicCalendarView()
            } label: {
                Text("行事曆")
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 36)
            }
            .buttonStyle(PixelButtonStyle(
                fill: PixelPalette.paper,
                contentPadding: EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10)))
        }
    }

    // MARK: 區塊標題與容器

    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title).pixelFont(size: PixelMetrics.FontSize.medium)
            Rectangle().fill(PixelPalette.tan).frame(height: PixelMetrics.border)
        }
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: PixelPalette.paper)
    }

    private var rowDivider: some View {
        Rectangle().fill(PixelPalette.tan).frame(height: PixelMetrics.border)
            .padding(.horizontal, 12)
    }

    // MARK: 今日課程

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                sectionTitle("今日課程")
                NavigationLink {
                    ScheduleView()
                } label: {
                    Text("完整課表")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 36)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: PixelPalette.paper,
                    contentPadding: EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10)))
            }

            if todayCourses.isEmpty {
                panel {
                    HStack(spacing: 10) {
                        PixelIcon(kind: .check, scale: 2, color: PixelPalette.ink)
                        Text("今天沒有課，好好休息")
                            .font(.body)
                    }
                    .padding(12)
                }
            } else {
                let next = nextCourse?.course
                panel {
                    ForEach(Array(todayCourses.enumerated()), id: \.offset) { index, course in
                        courseRow(course, isNext: next === course)
                        if index < todayCourses.count - 1 { rowDivider }
                    }
                }
            }
        }
    }

    private func courseRow(_ course: Course, isNext: Bool) -> some View {
        let t = startTime(course)
        let periods = course.endPeriod > course.startPeriod
            ? "第 \(course.startPeriod)–\(course.endPeriod) 節"
            : "第 \(course.startPeriod) 節"
        return HStack(alignment: .center, spacing: 12) {
            Text(t.map { String(format: "%02d:%02d", $0.0, $0.1) } ?? "--:--")
                .pixelFont(size: PixelMetrics.FontSize.medium)
                .fixedSize()
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                Text("\(course.room) · \(periods)")
                    .font(.subheadline)
                    .foregroundStyle(PixelPalette.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if isNext {
                // 下一堂：金底名牌（文字標示，不只靠顏色）
                NamePlate(text: "下一堂", fill: PixelPalette.gold, textColor: PixelPalette.ink)
                    .fixedSize()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(isNext ? PixelPalette.gold.opacity(0.25) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isNext ? "下一堂，" : "")\(t.map { String(format: "%d 點 %02d 分", $0.0, $0.1) } ?? "")，\(course.name)，\(course.room)，\(periods)")
    }

    // MARK: 待辦作業

    private var homeworkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("待辦作業")
            panel {
                ForEach(Array(pendingHomework.enumerated()), id: \.offset) { index, hw in
                    homeworkRow(hw)
                    if index < pendingHomework.count - 1 { rowDivider }
                }
            }
        }
    }

    private func homeworkRow(_ hw: HomeworkItem) -> some View {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: hw.dueDate)).day ?? 0
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hw.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                Text(hw.courseName)
                    .font(.subheadline)
                    .foregroundStyle(PixelPalette.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            UrgencyChip(days: days)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: 機車車位（沿用原 HomeView：剩餘最多的 4 個機車停車場）

    private var parkingSection: some View {
        let moto = Array(
            parkingLots
                .filter { $0.type == .motorcycle }
                .sorted { $0.availableCount > $1.availableCount }
                .prefix(4))
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("機車車位")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                      spacing: 12) {
                ForEach(moto) { lot in
                    let status = PixelStatus.forLot(available: lot.availableCount, total: lot.totalCapacity)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lot.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("\(lot.availableCount)")
                                .pixelFont(size: PixelMetrics.FontSize.medium)
                            StatusChip(status: status)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pixelFrame(fill: PixelPalette.paper)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(lot.name)，剩餘 \(lot.availableCount) 位，\(status.label)")
                }
            }
        }
    }

    // MARK: 行事曆

    private var calendarSection: some View {
        let next = SharedAcademicCalendar.nextEvent()
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("學術行事曆")
            NavigationLink {
                AcademicCalendarView()
            } label: {
                HStack(spacing: 12) {
                    if let event = next {
                        let days = SharedAcademicCalendar.daysUntil(event)
                        NamePlate(text: event.date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).locale(Locale(identifier: "en_US_POSIX"))),
                                  fill: PixelPalette.gold, textColor: PixelPalette.ink)
                            .fixedSize()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.body.weight(.semibold))
                                .lineLimit(2)
                            Text(days == 0 ? "今天" : "\(days) 天後")
                                .font(.subheadline)
                                .foregroundStyle(PixelPalette.muted)
                        }
                    } else {
                        Text("近期沒有行事曆事件，點此查看完整行事曆")
                            .font(.body)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(PixelButtonStyle(
                fill: PixelPalette.paper,
                contentPadding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)))
        }
    }
}

// MARK: - 急迫度標籤（形狀＋文字＋底色）

/// 作業截止標籤：今天＝三角、2 天內＝圓點、其餘＝圓點（淡底）
private struct UrgencyChip: View {
    let days: Int

    private var text: String {
        days <= 0 ? "今天" : days == 1 ? "明天" : "\(days) 天後"
    }
    private var icon: PixelIconKind { days <= 0 ? .triangle : .dot }
    private var fill: Color {
        days <= 0 ? PixelPalette.orange : days <= 2 ? PixelPalette.gold : PixelPalette.paper2
    }

    var body: some View {
        HStack(spacing: 4) {
            PixelIcon(kind: icon, scale: 1, color: PixelPalette.ink)
            Text(text).pixelFont(size: PixelMetrics.FontSize.small)
        }
        .foregroundStyle(PixelPalette.ink)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .pixelFrame(fill: fill)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text)截止")
    }
}

// MARK: - 預覽

#if DEBUG
#Preview("像素首頁") {
    let weekday: Int = {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }()
    let courses = [
        Course(name: "資料結構", instructor: "王老師", room: "資訊大樓 405", weekday: weekday, startPeriod: 2, endPeriod: 4),
        Course(name: "微積分", instructor: "李老師", room: "中正大樓 702", weekday: weekday, startPeriod: 6, endPeriod: 7),
        Course(name: "體育", instructor: "陳老師", room: "體育館", weekday: weekday, startPeriod: 9, endPeriod: 10),
    ]
    let day: TimeInterval = 86_400
    let homeworks = [
        HomeworkItem(title: "第三章習題", courseName: "微積分", dueDate: Date()),
        HomeworkItem(title: "期中專題報告", courseName: "資料結構", dueDate: Date().addingTimeInterval(2 * day)),
        HomeworkItem(title: "讀書心得", courseName: "通識", dueDate: Date().addingTimeInterval(6 * day)),
    ]
    let weather = SharedWeatherData(
        temperature: 24, apparentTemperature: 25, humidity: 70, windSpeed: 8, weatherCode: 3,
        fetchedAt: Date(), hourlyTemps: [], hourlyCodes: [], hourlyHours: [])
    func lot(_ name: String, _ total: Int, _ available: Int) -> ParkingLotData {
        ParkingLotData(name: name, totalCapacity: total, availableCount: available,
                       latitude: 24.1497, longitude: 120.684, lastUpdated: Date(), type: .motorcycle)
    }
    return PixelHomeView(
        courses: courses, todayCourses: courses, pendingHomework: homeworks,
        weather: weather,
        parkingLots: [lot("資訊館", 177, 58), lot("錦平街", 515, 7), lot("中技大樓", 449, 0), lot("中科平面", 120, 40)],
        periodTimes: (8...21).map { ($0, 10) },
        refresh: {})
    .environment(\.appearanceStyle, .pixel)
}
#endif
