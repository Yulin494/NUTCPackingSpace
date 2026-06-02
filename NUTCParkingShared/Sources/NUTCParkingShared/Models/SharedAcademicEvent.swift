import Foundation

public struct SharedAcademicEvent: Codable {
    public let title: String
    public let date: Date
    public let type: String

    public init(title: String, date: Date, type: String) {
        self.title = title
        self.date = date
        self.type = type
    }
}

public struct SharedAcademicCalendar {
    public static let events: [SharedAcademicEvent] = {
        let cal = Calendar.current
        func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
            var c = DateComponents(); c.year = y; c.month = m; c.day = d
            return cal.date(from: c) ?? Date()
        }
        return [
            SharedAcademicEvent(title: "114-1 開學日",         date: date(2025,  9, 15), type: "其他"),
            SharedAcademicEvent(title: "加退選截止（114-1）",   date: date(2025,  9, 26), type: "加退選"),
            SharedAcademicEvent(title: "教師節放假",             date: date(2025,  9, 28), type: "放假"),
            SharedAcademicEvent(title: "中秋節放假",             date: date(2025, 10,  6), type: "放假"),
            SharedAcademicEvent(title: "國慶日放假",             date: date(2025, 10, 10), type: "放假"),
            SharedAcademicEvent(title: "台灣光復節放假",         date: date(2025, 10, 24), type: "放假"),
            SharedAcademicEvent(title: "期中考開始（114-1）",   date: date(2025, 11, 10), type: "考試"),
            SharedAcademicEvent(title: "期中考結束（114-1）",   date: date(2025, 11, 15), type: "考試"),
            SharedAcademicEvent(title: "校慶",                   date: date(2025, 12,  1), type: "其他"),
            SharedAcademicEvent(title: "行憲紀念日放假",         date: date(2025, 12, 25), type: "放假"),
            SharedAcademicEvent(title: "元旦放假",               date: date(2026,  1,  1), type: "放假"),
            SharedAcademicEvent(title: "期末考開始（114-1）",   date: date(2026,  1, 12), type: "考試"),
            SharedAcademicEvent(title: "期末考結束（114-1）",   date: date(2026,  1, 17), type: "考試"),
            SharedAcademicEvent(title: "114-1 學期結束",         date: date(2026,  1, 31), type: "其他"),
            SharedAcademicEvent(title: "除夕",                   date: date(2026,  2, 16), type: "放假"),
            SharedAcademicEvent(title: "春節放假",               date: date(2026,  2, 17), type: "放假"),
            SharedAcademicEvent(title: "和平紀念日放假",         date: date(2026,  2, 27), type: "放假"),
            SharedAcademicEvent(title: "114-2 開學日",           date: date(2026,  2, 23), type: "其他"),
            SharedAcademicEvent(title: "加退選截止（114-2）",   date: date(2026,  3,  6), type: "加退選"),
            SharedAcademicEvent(title: "校慶補假",               date: date(2026,  4,  2), type: "放假"),
            SharedAcademicEvent(title: "兒童節放假",             date: date(2026,  4,  4), type: "放假"),
            SharedAcademicEvent(title: "清明節放假",             date: date(2026,  4,  5), type: "放假"),
            SharedAcademicEvent(title: "期中考開始（114-2）",   date: date(2026,  4, 20), type: "考試"),
            SharedAcademicEvent(title: "期中考結束（114-2）",   date: date(2026,  4, 24), type: "考試"),
            SharedAcademicEvent(title: "勞動節放假",             date: date(2026,  5,  1), type: "放假"),
            SharedAcademicEvent(title: "畢業典禮",               date: date(2026,  6, 12), type: "其他"),
            SharedAcademicEvent(title: "端午節放假",             date: date(2026,  6, 19), type: "放假"),
            SharedAcademicEvent(title: "期末考開始（114-2）",   date: date(2026,  6, 22), type: "考試"),
            SharedAcademicEvent(title: "期末考結束（114-2）",   date: date(2026,  6, 27), type: "考試"),
            SharedAcademicEvent(title: "114-2 學期結束",         date: date(2026,  7, 31), type: "其他"),
        ].sorted { $0.date < $1.date }
    }()

    public static func nextEvent(from now: Date = Date()) -> SharedAcademicEvent? {
        let today = Calendar.current.startOfDay(for: now)
        return events.first { Calendar.current.startOfDay(for: $0.date) >= today }
    }

    public static func daysUntil(_ event: SharedAcademicEvent, from now: Date = Date()) -> Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day],
                                      from: cal.startOfDay(for: now),
                                      to: cal.startOfDay(for: event.date)).day ?? 0
        return max(0, days)
    }
}
