import WidgetKit
import SwiftUI
import NUTCParkingShared

// MARK: - Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let nextEvent: SharedAcademicEvent?
    let daysUntil: Int
    let upcomingEvents: [SharedAcademicEvent]
}

// MARK: - Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        makeEntry(from: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(makeEntry(from: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(from: now)
        // Refresh at midnight so the day counter is accurate
        let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func makeEntry(from now: Date) -> CalendarEntry {
        let next = SharedAcademicCalendar.nextEvent(from: now)
        let days = next.map { SharedAcademicCalendar.daysUntil($0, from: now) } ?? 0
        let upcoming = Array(SharedAcademicCalendar.events
            .filter { Calendar.current.startOfDay(for: $0.date) >= Calendar.current.startOfDay(for: now) }
            .prefix(4))
        return CalendarEntry(date: now, nextEvent: next, daysUntil: days, upcomingEvents: upcoming)
    }
}

// MARK: - Views

struct CalendarCountdownWidgetView: View {
    var entry: CalendarEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular: lockScreenView
        case .systemSmall:          smallView
        default:                    mediumView
        }
    }

    private var lockScreenView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("行事曆", systemImage: "calendar")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            if let event = entry.nextEvent {
                HStack {
                    Text(entry.daysUntil == 0 ? "今天" : "\(entry.daysUntil) 天後")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentColor(for: event.type))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(event.title)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            } else {
                Text("學期結束").font(.system(size: 12))
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("行事曆", systemImage: "calendar")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)

            Spacer()

            if let event = entry.nextEvent {
                Text(daysLabel(entry.daysUntil))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor(for: event.type))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(entry.daysUntil == 0 ? "就是今天！" : "天後")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("學期結束")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            // Left: countdown
            VStack(alignment: .leading, spacing: 4) {
                Label("下個行程", systemImage: "calendar")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if let event = entry.nextEvent {
                    Text(daysLabel(entry.daysUntil))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor(for: event.type))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    Text(entry.daysUntil == 0 ? "就是今天！" : "天後")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text(event.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                } else {
                    Text("學期結束")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right: upcoming list
            VStack(alignment: .leading, spacing: 6) {
                Text("近期行程")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)

                ForEach(entry.upcomingEvents.prefix(3), id: \.title) { event in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accentColor(for: event.type))
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Text(event.date, style: .date)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }

    private func daysLabel(_ days: Int) -> String {
        days == 0 ? "今" : "\(days)"
    }

    private func accentColor(for type: String) -> Color {
        switch type {
        case "考試":   return .red
        case "放假":   return .green
        case "加退選": return .orange
        default:       return .blue
        }
    }
}

// MARK: - Widget

struct CalendarCountdownWidget: Widget {
    let kind = "CalendarCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarCountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("行事曆倒數")
        .description("顯示下一個學校重要日程的倒數天數。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CalendarCountdownWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        nextEvent: SharedAcademicEvent(title: "期末考開始（114-2）", date: Date().addingTimeInterval(86400 * 20), type: "考試"),
        daysUntil: 20,
        upcomingEvents: []
    )
}
