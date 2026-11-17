//
//  PixelStudyHubView.swift
//  NUTCParkingSpace
//
//  像素模式課業頁（概念 C）：「建築名牌」串起今日課表。
//  資料一律由 StudyHubView 傳入（沿用同一份 @Query），本檔不另抓資料。
//

import SwiftUI
import SwiftData

struct PixelStudyHubView: View {
    let courses: [Course]
    let homeworks: [HomeworkItem]
    /// 距期末考天數字串（沿用 StudyHubView.nextExamDays）
    let examDays: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // 與 StudyHubView 相同的節次起始時間
    private let periodTimes: [(Int, Int)] = [
        (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10), (14, 10),
        (15, 10), (16, 10), (17, 10), (18, 10), (19, 10), (20, 10), (21, 10)
    ]
    private let weekdayNames = ["一", "二", "三", "四", "五", "六", "日"]

    private var todayWeekday: Int {
        let w = Calendar.current.component(.weekday, from: Date())
        return w == 1 ? 7 : w - 1
    }

    private var todayCourses: [Course] {
        courses.filter { $0.weekday == todayWeekday }.sorted { $0.startPeriod < $1.startPeriod }
    }

    private var pendingHW: [HomeworkItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return homeworks.filter { !$0.isCompleted && $0.dueDate >= today }.sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    statsRow
                    todaySection
                    weekSection
                    homeworkSection
                    quickActions
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

    // MARK: - 標題名牌

    private var header: some View {
        // 草地道路橫帶：標題名牌 + 今日日期與堂數
        HStack(alignment: .center, spacing: 12) {
            NamePlate(text: "課業", fontSize: PixelMetrics.FontSize.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateText(Date()))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                Text(todayCourses.isEmpty ? "今日無課" : "今日 \(todayCourses.count) 堂課")
                    .font(.system(size: 15))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.grass)
        .accessibilityElement(children: .combine)
    }

    private static func dateText(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.month, .day, .weekday], from: date)
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return "\(c.month ?? 0)月\(c.day ?? 0)日 週\(names[(c.weekday ?? 1) - 1])"
    }

    // MARK: - 統計

    private var statsRow: some View {
        HStack(spacing: 8) {
            statCell(value: "\(courses.count)", label: "門課程")
            statCell(value: "\(pendingHW.count)", label: "件待辦")
            statCell(value: examDays, label: "天後期末考")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).pixelFont(size: PixelMetrics.FontSize.medium)
            Text(label).font(.system(size: 15))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .pixelFrame(fill: PixelPalette.paper)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 今日課程

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                NamePlate(text: "今日課程")
                Spacer()
                NavigationLink(destination: ScheduleView()) {
                    Text("完整課表").font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            if todayCourses.isEmpty {
                emptyPanel(title: "今日無課", message: "今天沒有課，好好休息。", icon: .home)
            } else {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let nextID = nextCourseIndex(now: context.date)
                    VStack(spacing: 0) {
                        ForEach(Array(todayCourses.enumerated()), id: \.element.id) { i, course in
                            courseStop(course, now: context.date, isNext: i == nextID)
                            if i < todayCourses.count - 1 { routeConnector }
                        }
                    }
                }
            }
        }
    }

    /// 土路虛線連接兩站
    private var routeConnector: some View {
        HStack {
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(PixelPalette.tan).frame(width: 4, height: 4)
                }
            }
            .frame(width: 48)
            Spacer()
        }
        .padding(.vertical, 2)
        .accessibilityHidden(true)
    }

    private func startDate(of course: Course, now: Date) -> Date? {
        guard course.startPeriod >= 1, course.startPeriod <= 14 else { return nil }
        let t = periodTimes[course.startPeriod - 1]
        return Calendar.current.date(bySettingHour: t.0, minute: t.1, second: 0, of: now)
    }

    private func endDate(of course: Course, now: Date) -> Date? {
        // 一節 50 分鐘：結束節次起始 + 50 分
        let p = max(course.endPeriod, course.startPeriod)
        guard p >= 1, p <= 14 else { return nil }
        let t = periodTimes[p - 1]
        guard let s = Calendar.current.date(bySettingHour: t.0, minute: t.1, second: 0, of: now) else { return nil }
        return s.addingTimeInterval(50 * 60)
    }

    /// 第一堂「尚未開始」的課的索引
    private func nextCourseIndex(now: Date) -> Int? {
        todayCourses.firstIndex { c in
            if let s = startDate(of: c, now: now) { return s > now }
            return false
        }
    }

    private func timeText(_ course: Course) -> String {
        guard course.startPeriod >= 1, course.startPeriod <= 14 else { return "第\(course.startPeriod)節" }
        let t = periodTimes[course.startPeriod - 1]
        let range = course.endPeriod > course.startPeriod ? "第\(course.startPeriod)-\(course.endPeriod)節" : "第\(course.startPeriod)節"
        return String(format: "%02d:%02d  %@", t.0, t.1, range)
    }

    private func countdownText(minutes: Int) -> String {
        if minutes >= 60 { return "下一堂 \(minutes / 60) 小時 \(minutes % 60) 分後" }
        return "下一堂 \(minutes) 分鐘後"
    }

    private func courseStop(_ course: Course, now: Date, isNext: Bool) -> some View {
        let building = CampusBuilding.match(location: course.room)
        let start = startDate(of: course, now: now)
        let end = endDate(of: course, now: now)
        let inProgress = (start != nil && end != nil) ? (start! <= now && now < end!) : false
        let minutes = start.map { Int($0.timeIntervalSince(now) / 60) }
        let highlight = isNext || inProgress

        return HStack(alignment: .top, spacing: 12) {
            PixelBuildingIcon(building: building)
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    NamePlate(text: building?.plate ?? "教室",
                              fill: highlight ? PixelPalette.gold : PixelPalette.ink,
                              textColor: highlight ? PixelPalette.ink : PixelPalette.paper)
                    if inProgress {
                        NamePlate(text: "上課中", fill: PixelPalette.grass, textColor: PixelPalette.ink)
                    }
                }
                Text(course.name)
                    .font(.system(size: 17, weight: .semibold))
                Text(course.room.isEmpty ? "教室未填" : course.room)
                    .font(.system(size: 15))
                Text(timeText(course))
                    .pixelFont(size: PixelMetrics.FontSize.small)
                if isNext, let m = minutes, m >= 0 {
                    NamePlate(text: countdownText(minutes: m),
                              fill: PixelPalette.gold, textColor: PixelPalette.ink)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 下一堂/上課中：加粗框（不只靠顏色）
        .pixelFrame(fill: PixelPalette.paper, borderWidth: highlight ? 4 : PixelMetrics.border)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 本週課表

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NamePlate(text: "本週課表")
            VStack(spacing: 8) {
                ForEach(visibleWeekdays, id: \.self) { d in
                    weekRow(weekday: d)
                }
            }
        }
    }

    private var visibleWeekdays: [Int] {
        let weekend = courses.contains { $0.weekday >= 6 }
        return Array(1...(weekend ? 7 : 5))
    }

    private func weekRow(weekday: Int) -> some View {
        let isToday = weekday == todayWeekday
        let list = courses.filter { $0.weekday == weekday }.sorted { $0.startPeriod < $1.startPeriod }
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                NamePlate(text: "週" + weekdayNames[weekday - 1],
                          fill: isToday ? PixelPalette.gold : PixelPalette.ink,
                          textColor: isToday ? PixelPalette.ink : PixelPalette.paper)
                if isToday {
                    Text("今天").font(.system(size: 15, weight: .bold))
                }
            }
            .frame(width: 64)

            VStack(alignment: .leading, spacing: 6) {
                if list.isEmpty {
                    Text("無課").font(.system(size: 15)).foregroundStyle(PixelPalette.muted)
                } else {
                    ForEach(list, id: \.id) { c in
                        let b = CampusBuilding.match(location: c.room)
                        HStack(spacing: 8) {
                            // 色塊 = 所在建築屋頂色
                            Rectangle().fill(b?.roof ?? PixelPalette.muted)
                                .frame(width: 10, height: 10)
                                .overlay(Rectangle().stroke(PixelPalette.ink, lineWidth: 2))
                                .accessibilityHidden(true)
                            Text("\(c.startPeriod)  \(c.name)")
                                .font(.system(size: 15))
                                .lineLimit(2)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: isToday ? PixelPalette.paper : PixelPalette.paper,
                    borderWidth: isToday ? 4 : PixelMetrics.border)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 待辦作業

    private var homeworkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                NamePlate(text: "待辦作業")
                Spacer()
                NavigationLink(destination: HomeworkView()) {
                    Text("全部作業").font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }

            if pendingHW.isEmpty {
                emptyPanel(title: "全部完成", message: "所有作業都完成了。", icon: .check)
            } else {
                VStack(spacing: 8) {
                    ForEach(pendingHW.prefix(4), id: \.id) { hw in
                        hwRow(hw)
                    }
                    if pendingHW.count > 4 {
                        Text("還有 \(pendingHW.count - 4) 件作業…")
                            .font(.system(size: 15))
                            .foregroundStyle(PixelPalette.muted)
                    }
                }
            }
        }
    }

    private func hwRow(_ hw: HomeworkItem) -> some View {
        let days = Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: hw.dueDate)).day ?? 0
        let label = days == 0 ? "今天" : days == 1 ? "明天" : "\(days)天後"
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hw.title).font(.system(size: 17, weight: .semibold))
                Text(hw.courseName).font(.system(size: 15)).foregroundStyle(PixelPalette.muted)
            }
            Spacer(minLength: 8)
            HomeworkChip(days: days, label: label)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 快速操作

    private var quickActions: some View {
        HStack(spacing: 8) {
            NavigationLink(destination: ScheduleView()) {
                Text("完整課表").pixelFont(size: PixelMetrics.FontSize.small)
                    .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.pixel)

            NavigationLink(destination: HomeworkView(autoPresentAdd: true)) {
                Text("新增作業").pixelFont(size: PixelMetrics.FontSize.small)
                    .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
        }
        .foregroundStyle(PixelPalette.ink)
    }

    // MARK: - 空狀態

    private func emptyPanel(title: String, message: String, icon: PixelIconKind) -> some View {
        HStack(spacing: 12) {
            PixelIcon(kind: icon, scale: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).pixelFont(size: PixelMetrics.FontSize.small)
                Text(message).font(.system(size: 15))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 作業狀態章（形狀 + 文字 + 底色）

private struct HomeworkChip: View {
    let days: Int
    let label: String

    private var kind: PixelIconKind { days <= 0 ? .triangle : .dot }
    private var fill: Color {
        days <= 0 ? PixelPalette.orange : days <= 2 ? PixelPalette.gold : PixelPalette.grass
    }

    var body: some View {
        HStack(spacing: 4) {
            PixelIcon(kind: kind, scale: 1)
            Text(label).pixelFont(size: PixelMetrics.FontSize.small)
        }
        .foregroundStyle(PixelPalette.ink)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .pixelFrame(fill: fill)
    }
}

// MARK: - 小建築圖示（12×12 格，每格 4pt = 48pt）

struct PixelBuildingIcon: View {
    let building: CampusBuilding?

    var body: some View {
        let roof = building?.roof ?? PixelPalette.muted
        let striped = building?.striped ?? false
        Canvas { ctx, _ in
            let u: CGFloat = 4
            func fill(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ c: Color) {
                ctx.fill(Path(CGRect(x: CGFloat(x) * u, y: CGFloat(y) * u,
                                     width: CGFloat(w) * u, height: CGFloat(h) * u)), with: .color(c))
            }
            // 外框
            fill(1, 1, 10, 10, PixelPalette.ink)
            // 屋頂（3 列）
            fill(2, 2, 8, 3, roof)
            if striped {
                for x in stride(from: 2, to: 10, by: 2) { fill(x, 2, 1, 3, PixelPalette.orange) }
            }
            // 牆面
            fill(2, 5, 8, 5, PixelPalette.paper2)
            // 窗
            fill(3, 6, 2, 2, PixelPalette.water)
            fill(7, 6, 2, 2, PixelPalette.water)
            // 門
            fill(5, 8, 2, 2, PixelPalette.ink)
            // 找不到建築：中央加問號點標記（形狀區分）
            if building == nil { fill(5, 3, 2, 1, PixelPalette.paper) }
        }
        .frame(width: 48, height: 48)
    }
}

// MARK: - Preview（假資料）

#Preview {
    let container = try! ModelContainer(
        for: Course.self, HomeworkItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let ctx = container.mainContext
    let w = { () -> Int in let x = Calendar.current.component(.weekday, from: Date()); return x == 1 ? 7 : x - 1 }()
    ctx.insert(Course(name: "資料結構", instructor: "王老師", room: "資訊大樓 405", weekday: w, startPeriod: 2, endPeriod: 4))
    ctx.insert(Course(name: "微積分", instructor: "李老師", room: "中商大樓 702", weekday: w, startPeriod: 6, endPeriod: 7))
    ctx.insert(Course(name: "體育", instructor: "張老師", room: "體育館", weekday: 3, startPeriod: 8, endPeriod: 9))
    ctx.insert(HomeworkItem(title: "第三章習題", courseName: "微積分", dueDate: Date()))
    ctx.insert(HomeworkItem(title: "期中專案報告", courseName: "資料結構", dueDate: Date().addingTimeInterval(86400 * 5)))
    return PixelStudyHubView(courses: (try? ctx.fetch(FetchDescriptor<Course>())) ?? [],
                             homeworks: (try? ctx.fetch(FetchDescriptor<HomeworkItem>())) ?? [],
                             examDays: "42")
        .modelContainer(container)
        .environment(\.appearanceStyle, .pixel)
}
