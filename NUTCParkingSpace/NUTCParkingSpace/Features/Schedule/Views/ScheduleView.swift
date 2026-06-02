//
//  ScheduleView.swift
//  NUTCParkingSpace
//

import SwiftUI
import SwiftData
import UIKit
import NUTCParkingShared
import WidgetKit

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCourse = false
    @Query(sort: \Course.weekday) var courses: [Course]

    // 今天的 NUTC weekday (1=Mon..7=Sun)
    @State private var selectedWeekday: Int = {
        let wd = Calendar.current.component(.weekday, from: Date())
        return wd == 1 ? 7 : wd - 1
    }()

    // 每節課開始時間
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

    // 取得本週的日期（週一到週日）
    private func weekDates() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today) // 1=Sun
        let mondayOffset = weekday == 1 ? -6 : -(weekday - 2)
        let monday = cal.date(byAdding: .day, value: mondayOffset, to: today)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 週日選擇器
                weekDayPicker

                // 選中日課程
                if selectedDayCourses.isEmpty {
                    emptyDayCard
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(selectedDayCourses) { course in
                            CourseCard(course: course, periodStartTimes: periodStartTimes)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("課表")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { showAddCourse = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCourse) {
            AddCourseView(isPresented: $showAddCourse)
        }
        .onAppear { syncCache() }
        .onChange(of: courses.count) { syncCache() }
    }

    // MARK: - Week Day Picker

    private var weekDayPicker: some View {
        let dates = weekDates()
        let cal = Calendar.current

        return HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { index in
                let date = dates[index]
                let dayNum = cal.component(.day, from: date)
                let isToday = index + 1 == todayWeekday
                let isSelected = index + 1 == selectedWeekday

                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedWeekday = index + 1
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(weekLabels[index])
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : .secondary)
                        Text("\(dayNum)")
                            .font(.subheadline)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected
                            ? Color.blue
                            : (isToday ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    // MARK: - Empty State

    private var emptyDayCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("今天沒有課")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("享受你的空堂時光")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }

    // MARK: - Sync

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

// MARK: - CourseCard

struct CourseCard: View {
    let course: Course
    let periodStartTimes: [String]

    private var courseColor: Color {
        Color(courseHex: course.color) ?? .blue
    }

    private var startTime: String {
        let idx = course.startPeriod - 1
        guard idx >= 0 && idx < periodStartTimes.count else { return "" }
        return periodStartTimes[idx]
    }

    private var endTimeStr: String {
        let idx = course.endPeriod - 1
        guard idx >= 0 && idx < periodStartTimes.count else { return "" }
        // Add 50 minutes to start time of last period
        let parts = periodStartTimes[idx].split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return "" }
        let totalMin = parts[0] * 60 + parts[1] + 50
        return String(format: "%02d:%02d", totalMin / 60, totalMin % 60)
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左側彩色色條
            Rectangle()
                .fill(courseColor)
                .frame(width: 5)
                .clipShape(RoundedRectangle(cornerRadius: 2.5))
                .padding(.vertical, 12)

            HStack(spacing: 12) {
                // 節次標籤
                VStack(spacing: 2) {
                    Text("第\(course.startPeriod)")
                        .font(.caption2)
                        .foregroundColor(courseColor)
                    if course.endPeriod > course.startPeriod {
                        Text("〜")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(course.endPeriod)節")
                            .font(.caption2)
                            .foregroundColor(courseColor)
                    } else {
                        Text("節")
                            .font(.caption2)
                            .foregroundColor(courseColor)
                    }
                }
                .frame(width: 36)

                // 時間
                VStack(alignment: .leading, spacing: 2) {
                    Text(startTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(endTimeStr)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 40)

                // 課程資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if !course.room.isEmpty {
                            Label(course.room, systemImage: "mappin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if !course.instructor.isEmpty {
                            Label(course.instructor, systemImage: "person")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }
}

// MARK: - AddCourseView

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var existingCourses: [Course]
    @Binding var isPresented: Bool
    @State private var courseName = ""
    @State private var instructor = ""
    @State private var room = ""
    @State private var selectedWeekday = 1
    @State private var selectedStartPeriod = 1
    @State private var selectedEndPeriod = 1
    @State private var showConflictAlert = false
    @State private var conflictMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("課程資訊")) {
                    TextField("課程名稱", text: $courseName)
                    TextField("授課教師", text: $instructor)
                    TextField("教室位置", text: $room)
                }

                Section(header: Text("上課時間")) {
                    Picker("星期", selection: $selectedWeekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(weekdayName(day)).tag(day)
                        }
                    }

                    Picker("開始節次", selection: $selectedStartPeriod) {
                        ForEach(1...14, id: \.self) { period in
                            Text("第 \(period) 節").tag(period)
                        }
                    }

                    Picker("結束節次", selection: $selectedEndPeriod) {
                        ForEach(selectedStartPeriod...14, id: \.self) { period in
                            Text("第 \(period) 節").tag(period)
                        }
                    }
                }
            }
            .navigationTitle("新增課程")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        if let conflict = checkConflict() {
                            conflictMessage = conflict
                            showConflictAlert = true
                        } else {
                            addCourse()
                            isPresented = false
                        }
                    }
                    .disabled(courseName.isEmpty)
                }
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
            endPeriod: selectedEndPeriod
        )
        modelContext.insert(course)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        return weekday >= 1 && weekday <= 7 ? names[weekday - 1] : ""
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
    }
}
