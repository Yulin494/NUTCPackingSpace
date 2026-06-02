import WidgetKit
import SwiftUI
import NUTCParkingShared

// MARK: - Entry

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let todayCourses: [SharedCourse]
    let weekdayName: String
}

// MARK: - Provider

struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        makeEntry(from: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(makeEntry(from: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(from: now)
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry(from now: Date) -> ScheduleEntry {
        let cal = Calendar.current
        let rawWeekday = cal.component(.weekday, from: now) // 1=Sun
        let nutcWeekday = rawWeekday == 1 ? 7 : rawWeekday - 1 // 1=Mon..7=Sun
        let all = SharedScheduleCache.load()
        let today = all
            .filter { $0.weekday == nutcWeekday }
            .sorted { $0.startPeriod < $1.startPeriod }
        let names = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
        let name = nutcWeekday >= 1 && nutcWeekday <= 7 ? names[nutcWeekday - 1] : ""
        return ScheduleEntry(date: now, todayCourses: today, weekdayName: name)
    }
}

// MARK: - Views

struct ScheduleWidgetView: View {
    var entry: ScheduleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if family == .accessoryRectangular {
            scheduleLockScreenView
                .containerBackground(for: .widget) { Color.clear }
        } else {
            scheduleMainView
        }
    }

    private var scheduleLockScreenView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("課表 · \(entry.weekdayName)", systemImage: "book.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            if let next = entry.todayCourses.first,
               let time = next.startTime {
                HStack {
                    Text(String(format: "%02d:%02d", time.hour, time.minute))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                    Text(next.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Spacer()
                    Text(next.room)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("今天沒有課").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }

    private var scheduleMainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("課表", systemImage: "book.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.weekdayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            if entry.todayCourses.isEmpty {
                VStack {
                    Image(systemName: "sun.max")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                    Text("今天沒有課")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let limit = family == .systemSmall ? 2 : 4
                ForEach(Array(entry.todayCourses.prefix(limit).enumerated()), id: \.offset) { _, course in
                    CourseRow(course: course)
                    if course.id != entry.todayCourses.prefix(limit).last?.id {
                        Divider().padding(.vertical, 3)
                    }
                }

                if entry.todayCourses.count > limit {
                    Text("還有 \(entry.todayCourses.count - limit) 堂課...")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }
}

struct CourseRow: View {
    let course: SharedCourse

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: course.color) ?? .blue)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(course.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("第\(course.startPeriod)-\(course.endPeriod)節")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(course.room)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let time = course.startTime {
                Text(String(format: "%02d:%02d", time.hour, time.minute))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let val = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >>  8) & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}

// MARK: - Widget

struct ScheduleWidget: Widget {
    let kind = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("今日課表")
        .description("顯示今天的課程時間表。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: Date(),
        todayCourses: [
            SharedCourse(id: "1", name: "資料結構", instructor: "王教授", room: "A101", weekday: 1, startPeriod: 1, endPeriod: 2, color: "#007AFF"),
            SharedCourse(id: "2", name: "作業系統", instructor: "李教授", room: "B205", weekday: 1, startPeriod: 5, endPeriod: 6, color: "#FF3B30"),
            SharedCourse(id: "3", name: "計算機組織", instructor: "陳教授", room: "C301", weekday: 1, startPeriod: 7, endPeriod: 8, color: "#34C759"),
        ],
        weekdayName: "週一"
    )
}
