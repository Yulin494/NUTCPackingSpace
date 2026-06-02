//
//  StudyHubView.swift
//  NUTCParkingSpace
//

import SwiftUI
import SwiftData
import NUTCParkingShared

struct StudyHubView: View {
    @Query(sort: \Course.weekday) var courses: [Course]
    @Query(sort: \HomeworkItem.dueDate) var homeworks: [HomeworkItem]

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

    private let periodTimes: [(Int, Int)] = [
        (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10), (14, 10),
        (15, 10), (16, 10), (17, 10), (18, 10), (19, 10), (20, 10), (21, 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 統計列
                    statsRow

                    // 今日課程
                    todaySection

                    // 作業
                    homeworkSection

                    // 快速操作
                    quickActions
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("課業管理")
        }
    }

    // MARK: - 統計
    private var statsRow: some View {
        HStack(spacing: 10) {
            StatBadge(value: "\(courses.count)", label: "門課程", color: .blue)
            StatBadge(value: "\(pendingHW.count)", label: "件待辦", color: pendingHW.isEmpty ? .green : .orange)
            StatBadge(value: nextExamDays, label: "天後期末考", color: .purple)
        }
    }

    private var nextExamDays: String {
        let today = Calendar.current.startOfDay(for: Date())
        let examKeyword = "期末考"
        let exam = AcademicCalendarData.events.first {
            $0.title.contains(examKeyword) && $0.title.contains("開始") &&
            Calendar.current.startOfDay(for: $0.date) >= today
        }
        guard let e = exam else { return "—" }
        let d = Calendar.current.dateComponents([.day],
            from: today,
            to: Calendar.current.startOfDay(for: e.date)).day ?? 0
        return "\(d)"
    }

    // MARK: - 今日課程
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日課程").font(.title3).bold()
                Spacer()
                NavigationLink("完整課表", destination: ScheduleView())
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            if todayCourses.isEmpty {
                NUTCCard {
                    HStack(spacing: 12) {
                        Image(systemName: "sun.max.fill").font(.title2).foregroundColor(.yellow)
                        Text("今天沒有課，好好休息！").foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                NUTCCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(todayCourses.enumerated()), id: \.element.id) { i, course in
                            courseTimelineRow(course)
                            if i < todayCourses.count - 1 {
                                Divider().padding(.leading, 72)
                            }
                        }
                    }
                }
            }
        }
    }

    private func courseTimelineRow(_ course: Course) -> some View {
        let accent = Color(courseHex: course.color) ?? .blue
        let time = course.startPeriod >= 1 && course.startPeriod <= 14
            ? periodTimes[course.startPeriod - 1] : (0, 0)
        return HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(String(format: "%02d:%02d", time.0, time.1))
                    .font(.caption2.monospacedDigit()).foregroundColor(.secondary)
                Text("第\(course.startPeriod)節")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .frame(width: 46)

            Rectangle()
                .fill(accent)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 3) {
                Text(course.name).font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 8) {
                    Label(course.room, systemImage: "location.fill")
                    Label(course.instructor, systemImage: "person.fill")
                }
                .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - 作業
    private var homeworkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("待辦作業").font(.title3).bold()
                Spacer()
                NavigationLink("全部作業", destination: HomeworkView())
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            if pendingHW.isEmpty {
                NUTCCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill").font(.title2).foregroundColor(.green)
                        Text("所有作業都完成了！").foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                NUTCCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(pendingHW.prefix(4).enumerated()), id: \.element.id) { i, hw in
                            hwRow(hw)
                            if i < min(pendingHW.count, 4) - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                        if pendingHW.count > 4 {
                            Text("還有 \(pendingHW.count - 4) 件作業…")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private func hwRow(_ hw: HomeworkItem) -> some View {
        let days = Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: hw.dueDate)).day ?? 0
        let color: Color = days == 0 ? .red : days <= 2 ? .orange : .primary

        return HStack(spacing: 12) {
            Image(systemName: "circle").foregroundColor(color).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(hw.title).font(.subheadline).fontWeight(.medium)
                Text(hw.courseName).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Text(days == 0 ? "今天" : days == 1 ? "明天" : "\(days)天後")
                .font(.caption).fontWeight(.semibold).foregroundColor(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - 快速操作
    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ScheduleView()) {
                Label("完整課表", systemImage: "calendar.badge.clock")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            NavigationLink(destination: HomeworkView()) {
                Label("新增作業", systemImage: "plus.circle")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    StudyHubView()
        .modelContainer(for: [Course.self, HomeworkItem.self], inMemory: true)
}
