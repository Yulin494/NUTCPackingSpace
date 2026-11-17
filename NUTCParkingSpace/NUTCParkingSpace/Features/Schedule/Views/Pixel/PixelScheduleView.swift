//
//  PixelScheduleView.swift
//  NUTCParkingSpace
//
//  像素模式課表頁與「新增課程」表單。資料操作（新增、刪除、衝突檢查、
//  Widget 快取與上課通知同步）與 ScheduleView / AddCourseView 完全一致。
//

import SwiftUI
import SwiftData
import NUTCParkingShared
import WidgetKit

// MARK: - 共用小元件（僅本檔使用）

/// 子頁骨架：紙色背景、像素標題、紙色導覽列底
private struct SchedPxChrome: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .background(PixelPalette.paper2.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .pixelFont(size: PixelMetrics.FontSize.medium)
                        .foregroundStyle(PixelPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .toolbarBackground(PixelPalette.paper2, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

/// 課程顏色：原本存的是系統色票 hex，像素版對應到像素色盤（依色票順序）
private enum SchedPxColor {
    /// (底色, 其上文字色)，順序與 AddCourseView.palette 相同
    static let swatches: [(fill: Color, text: Color)] = [
        (PixelPalette.blue, PixelPalette.paper),
        (PixelPalette.grassD, PixelPalette.ink),
        (PixelPalette.orange, PixelPalette.ink),
        (PixelPalette.red, PixelPalette.paper),
        (PixelPalette.muted, PixelPalette.paper),
        (PixelPalette.teal, PixelPalette.paper),
        (PixelPalette.gold, PixelPalette.ink),
        (PixelPalette.water, PixelPalette.ink)
    ]

    static func swatch(forHex hex: String) -> (fill: Color, text: Color) {
        if let i = AddCourseView.palette.firstIndex(of: hex.uppercased()) { return swatches[i] }
        return swatches[0]
    }
}

/// 缺角小名牌（取代膠囊標籤）
private struct SchedPxTag: View {
    let text: String
    var fill: Color = PixelPalette.ink
    var textColor: Color = PixelPalette.paper

    var body: some View {
        Text(text)
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .pixelFrame(fill: fill)
    }
}

/// 像素「＋」圖示（12x12，2pt 方格）
private struct SchedPxPlus: View {
    var body: some View {
        ZStack {
            Rectangle().frame(width: 16, height: 4)
            Rectangle().frame(width: 4, height: 16)
        }
        .foregroundStyle(PixelPalette.ink)
        .frame(width: 20, height: 20)
        .accessibilityHidden(true)
    }
}

/// 像素分段：選中者金底並帶勾
private struct SchedPxChoiceRow<Value: Hashable>: View {
    let options: [(value: Value, title: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    VStack(spacing: 2) {
                        Text(option.title)
                            .pixelFont(size: PixelMetrics.FontSize.small)
                            .lineLimit(1)
                        if selected {
                            PixelIcon(kind: .check, scale: 1)
                        } else {
                            Color.clear.frame(width: 12, height: 12)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: selected ? PixelPalette.gold : PixelPalette.paper,
                    contentPadding: EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2)))
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .foregroundStyle(PixelPalette.ink)
    }
}

/// 表單區塊：名牌標題 + 缺角框
private struct SchedPxBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NamePlate(text: title)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: PixelPalette.paper)
        }
    }
}

/// 輸入框外框
private struct SchedPxFieldFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17))
            .foregroundStyle(PixelPalette.ink)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .pixelFrame(fill: PixelPalette.paper)
    }
}

// MARK: - 課表頁

struct PixelScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCourse = false
    @State private var courseToDelete: Course?
    @Query(sort: \Course.weekday) var courses: [Course]

    @State private var selectedWeekday: Int = {
        let wd = Calendar.current.component(.weekday, from: Date())
        return wd == 1 ? 7 : wd - 1
    }()

    private let periodStartTimes = [
        "08:10", "09:10", "10:10", "11:10", "12:10", "13:10",
        "14:10", "15:10", "16:10", "17:10", "18:10", "19:10", "20:10", "21:10"
    ]
    private let weekLabels = ["一", "二", "三", "四", "五", "六", "日"]

    private var todayWeekday: Int {
        let wd = Calendar.current.component(.weekday, from: Date())
        return wd == 1 ? 7 : wd - 1
    }

    private var selectedDayCourses: [Course] {
        courses.filter { $0.weekday == selectedWeekday }
            .sorted { $0.startPeriod < $1.startPeriod }
    }

    private func weekDates() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let mondayOffset = weekday == 1 ? -6 : -(weekday - 2)
        let monday = cal.date(byAdding: .day, value: mondayOffset, to: today)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                weekDayPicker

                HStack(spacing: 8) {
                    NamePlate(text: "週\(weekLabels[selectedWeekday - 1])課程",
                              fill: PixelPalette.gold, textColor: PixelPalette.ink)
                    if selectedWeekday == todayWeekday {
                        SchedPxTag(text: "今天", fill: PixelPalette.water, textColor: PixelPalette.ink)
                    }
                }

                if selectedDayCourses.isEmpty {
                    emptyDayCard
                } else {
                    VStack(spacing: 12) {
                        ForEach(selectedDayCourses) { course in
                            PixelCourseCard(course: course, periodStartTimes: periodStartTimes)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        courseToDelete = course
                                    } label: {
                                        Label("刪除課程", systemImage: "trash")
                                    }
                                }
                                .accessibilityAction(named: "刪除課程") { courseToDelete = course }
                        }
                    }

                    Text("長按課程可刪除")
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .modifier(SchedPxChrome(title: "課表"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { showAddCourse = true } label: {
                    SchedPxPlus().frame(minWidth: 28, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: PixelPalette.gold,
                    contentPadding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)))
                .accessibilityLabel("新增課程")
            }
        }
        .sheet(isPresented: $showAddCourse) {
            AddCourseView(isPresented: $showAddCourse)
        }
        .confirmationDialog(
            "刪除課程",
            isPresented: Binding(
                get: { courseToDelete != nil },
                set: { if !$0 { courseToDelete = nil } }
            ),
            presenting: courseToDelete
        ) { course in
            Button("刪除「\(course.name)」", role: .destructive) {
                deleteCourse(course)
            }
            Button("取消", role: .cancel) { courseToDelete = nil }
        } message: { course in
            Text("確定要刪除「\(course.name)」嗎？此動作無法復原。")
        }
        .onAppear { syncCache() }
        .onChange(of: courses.count) { syncCache() }
    }

    // MARK: Delete

    private func deleteCourse(_ course: Course) {
        modelContext.delete(course)
        try? modelContext.save()
        courseToDelete = nil
        // 刪除後 courses.count 改變會觸發 syncCache()，不在此重複呼叫（同 ScheduleView）
    }

    // MARK: Week Day Picker

    private var weekDayPicker: some View {
        let dates = weekDates()
        let cal = Calendar.current

        return HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { index in
                let dayNum = cal.component(.day, from: dates[index])
                let isToday = index + 1 == todayWeekday
                let isSelected = index + 1 == selectedWeekday

                Button {
                    selectedWeekday = index + 1
                } label: {
                    VStack(spacing: 2) {
                        Text(weekLabels[index])
                            .pixelFont(size: PixelMetrics.FontSize.small)
                        Text("\(dayNum)")
                            .pixelFont(size: PixelMetrics.FontSize.medium)
                            .lineLimit(1)
                        // 今天：加一個點（不只靠顏色）
                        if isToday {
                            PixelIcon(kind: .dot, scale: 1)
                        } else {
                            Color.clear.frame(width: 12, height: 12)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: isSelected ? PixelPalette.gold : (isToday ? PixelPalette.water : PixelPalette.paper),
                    contentPadding: EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)))
                .accessibilityLabel("週\(weekLabels[index])，\(dayNum) 日\(isToday ? "，今天" : "")")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .foregroundStyle(PixelPalette.ink)
    }

    // MARK: Empty State

    private var emptyDayCard: some View {
        VStack(spacing: 12) {
            PixelIcon(kind: .cloud, scale: 4)
                .foregroundStyle(PixelPalette.muted)
            Text("今天沒有課")
                .pixelFont(size: PixelMetrics.FontSize.medium)
                .foregroundStyle(PixelPalette.ink)
            Text("享受你的空堂時光")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .pixelFrame(fill: PixelPalette.paper)
    }

    // MARK: Sync（同 ScheduleView.syncCache）

    private func syncCache() {
        let shared = courses.map { c in
            SharedCourse(
                id: "\(c.weekday)-\(c.startPeriod)-\(c.name)",
                name: c.name, instructor: c.instructor, room: c.room,
                weekday: c.weekday, startPeriod: c.startPeriod,
                endPeriod: c.endPeriod, color: c.color
            )
        }
        SharedScheduleCache.save(shared)
        WidgetCenter.shared.reloadTimelines(ofKind: "ScheduleWidget")
        Task { await ScheduleNotificationService.shared.reschedule(courses: shared) }
    }
}

// MARK: - 課程卡

private struct PixelCourseCard: View {
    let course: Course
    let periodStartTimes: [String]

    private var swatch: (fill: Color, text: Color) { SchedPxColor.swatch(forHex: course.color) }

    private var startTime: String {
        let idx = course.startPeriod - 1
        guard idx >= 0 && idx < periodStartTimes.count else { return "" }
        return periodStartTimes[idx]
    }

    private var endTimeStr: String {
        let idx = course.endPeriod - 1
        guard idx >= 0 && idx < periodStartTimes.count else { return "" }
        let parts = periodStartTimes[idx].split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return "" }
        let totalMin = parts[0] * 60 + parts[1] + 50
        return String(format: "%02d:%02d", totalMin / 60, totalMin % 60)
    }

    private var periodText: String {
        course.endPeriod > course.startPeriod
            ? "第\(course.startPeriod)〜\(course.endPeriod)節"
            : "第\(course.startPeriod)節"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 左側色塊（方角）
            Rectangle()
                .fill(swatch.fill)
                .frame(width: 8)
                .overlay(Rectangle().stroke(PixelPalette.ink, lineWidth: 2))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    SchedPxTag(text: periodText, fill: swatch.fill, textColor: swatch.text)
                    Text("\(startTime)–\(endTimeStr)")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(PixelPalette.muted)
                }

                Text(course.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PixelPalette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !course.room.isEmpty || !course.instructor.isEmpty {
                    HStack(spacing: 8) {
                        if let building = CampusBuilding.match(location: course.room) {
                            NamePlate(text: building.plate)
                        }
                        if !course.room.isEmpty {
                            Text(course.room)
                                .font(.system(size: 15))
                                .foregroundStyle(PixelPalette.muted)
                        }
                        if !course.instructor.isEmpty {
                            Text(course.instructor)
                                .font(.system(size: 15))
                                .foregroundStyle(PixelPalette.muted)
                        }
                    }
                    .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 新增課程

struct PixelAddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var existingCourses: [Course]
    @Binding var isPresented: Bool
    @State private var courseName = ""
    @State private var instructor = ""
    @State private var room = ""
    @State private var selectedWeekday = 1
    @State private var selectedStartPeriod = 1
    @State private var selectedEndPeriod = 1
    @State private var selectedColor = AddCourseView.palette.first!
    @State private var selectedSemester = AddCourseView.currentSemester
    @State private var showConflictAlert = false
    @State private var conflictMessage = ""

    private let weekLabels = ["一", "二", "三", "四", "五", "六", "日"]

    private var semesterOptions: [String] {
        let base = AddCourseView.currentSemester
        let parts = base.split(separator: "-")
        guard parts.count == 2, let y = Int(parts[0]), let t = Int(parts[1]) else { return [base] }
        func label(_ y: Int, _ t: Int) -> String { "\(y)-\(t)" }
        let prev = t == 1 ? label(y - 1, 2) : label(y, 1)
        let next = t == 1 ? label(y, 2)     : label(y + 1, 1)
        return [prev, base, next]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SchedPxBlock(title: "課程資訊") {
                        TextField("課程名稱", text: $courseName).modifier(SchedPxFieldFrame())
                        TextField("授課教師", text: $instructor).modifier(SchedPxFieldFrame())
                        TextField("教室位置", text: $room).modifier(SchedPxFieldFrame())
                    }

                    SchedPxBlock(title: "上課時間") {
                        Text("星期").font(.system(size: 17)).foregroundStyle(PixelPalette.ink)
                        SchedPxChoiceRow(
                            options: (1...7).map { ($0, weekLabels[$0 - 1]) },
                            selection: $selectedWeekday)

                        periodMenu(title: "開始節次", selection: $selectedStartPeriod, range: 1...14)
                        periodMenu(title: "結束節次", selection: $selectedEndPeriod,
                                   range: selectedStartPeriod...14)

                        Text("學期").font(.system(size: 17)).foregroundStyle(PixelPalette.ink)
                        SchedPxChoiceRow(
                            options: semesterOptions.map { ($0, $0) },
                            selection: $selectedSemester)
                    }

                    SchedPxBlock(title: "顏色") {
                        colorGrid
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .modifier(SchedPxChrome(title: "新增課程"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { isPresented = false } label: {
                        Text("取消").font(.system(size: 15)).foregroundStyle(PixelPalette.ink)
                    }
                    .buttonStyle(PixelButtonStyle(
                        contentPadding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if let conflict = checkConflict() {
                            conflictMessage = conflict
                            showConflictAlert = true
                        } else {
                            addCourse()
                            isPresented = false
                        }
                    } label: {
                        Text("完成").font(.system(size: 15)).foregroundStyle(PixelPalette.ink)
                    }
                    .buttonStyle(PixelButtonStyle(
                        fill: PixelPalette.gold,
                        contentPadding: EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)))
                    .disabled(courseName.isEmpty)
                    .opacity(courseName.isEmpty ? 0.4 : 1)
                }
            }
            .onChange(of: selectedStartPeriod) {
                if selectedEndPeriod < selectedStartPeriod { selectedEndPeriod = selectedStartPeriod }
            }
        }
        .alert("課程時間衝突", isPresented: $showConflictAlert) {
            Button("取消", role: .cancel) {}
            Button("仍然新增", role: .destructive) {
                addCourse()
                isPresented = false
            }
        } message: {
            Text(conflictMessage)
        }
    }

    private func periodMenu(title: String, selection: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(title).font(.system(size: 17)).foregroundStyle(PixelPalette.ink)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(range, id: \.self) { period in
                    Text("第 \(period) 節").tag(period)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(PixelPalette.ink)
        }
        .modifier(SchedPxFieldFrame())
    }

    private var colorGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(AddCourseView.palette.enumerated()), id: \.offset) { index, hex in
                let swatch = SchedPxColor.swatches[index]
                let selected = selectedColor == hex
                Button {
                    selectedColor = hex
                } label: {
                    ZStack {
                        if selected {
                            PixelIcon(kind: .check, scale: 2, color: swatch.text)
                        } else {
                            Color.clear.frame(width: 24, height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: swatch.fill,
                    contentPadding: EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)))
                .accessibilityLabel("顏色 \(index + 1)")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    // MARK: 資料操作（同 AddCourseView）

    private func checkConflict() -> String? {
        let names = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        let dayName = selectedWeekday >= 1 && selectedWeekday <= 7 ? names[selectedWeekday - 1] : ""
        for existing in existingCourses
        where existing.weekday == selectedWeekday
           && existing.startPeriod <= selectedEndPeriod
           && existing.endPeriod   >= selectedStartPeriod {
            return "\(dayName) 第\(selectedStartPeriod)-\(selectedEndPeriod)節 與「\(existing.name)」（第\(existing.startPeriod)-\(existing.endPeriod)節）時間重疊。"
        }
        return nil
    }

    private func addCourse() {
        let course = Course(
            name: courseName,
            instructor: instructor,
            room: room,
            weekday: selectedWeekday,
            startPeriod: selectedStartPeriod,
            endPeriod: selectedEndPeriod,
            color: selectedColor,
            semester: selectedSemester
        )
        modelContext.insert(course)
    }
}
