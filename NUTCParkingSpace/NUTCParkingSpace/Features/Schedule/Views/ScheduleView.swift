//
//  ScheduleView.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddCourse = false
    @Query(sort: \Course.weekday) var courses: [Course]

    var currentDayCourses: [Course] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayOfWeek = weekday == 1 ? 7 : weekday - 1
        return courses.filter { $0.weekday == dayOfWeek }
    }

    var body: some View {
        List {
            Section(header: Text("今日課程")) {
                if currentDayCourses.isEmpty {
                    Text("今天沒有課")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(currentDayCourses.sorted(by: { $0.startPeriod < $1.startPeriod })) { course in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.name)
                                .font(.headline)
                            Text("第 \(course.startPeriod)-\(course.endPeriod) 節")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(course.room)
                                Spacer()
                                Text(course.instructor)
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("本週課程")) {
                if courses.isEmpty {
                    Text("尚無課程，點「+」新增")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(courses.sorted { $0.weekday < $1.weekday }) { course in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(course.name)
                                    .font(.headline)
                                Spacer()
                                Text("第 \(course.startPeriod)-\(course.endPeriod) 節")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            HStack {
                                Text(weekdayName(course.weekday))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(course.room)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indices in
                        let sorted = courses.sorted { $0.weekday < $1.weekday }
                        indices.forEach { modelContext.delete(sorted[$0]) }
                    }
                }
            }
        }
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
    }

    private func weekdayName(_ weekday: Int) -> String {
        let names = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        return weekday >= 1 && weekday <= 7 ? names[weekday - 1] : ""
    }
}

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var courseName = ""
    @State private var instructor = ""
    @State private var room = ""
    @State private var selectedWeekday = 1
    @State private var selectedStartPeriod = 1
    @State private var selectedEndPeriod = 1

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
                        addCourse()
                        isPresented = false
                    }
                    .disabled(courseName.isEmpty)
                }
            }
        }
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
