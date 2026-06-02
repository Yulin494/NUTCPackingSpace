//
//  AcademicCalendarData.swift
//  NUTCParkingSpace
//
//  資料來源：國立臺中科技大學114學年度行事曆（教務處核備版）
//

import Foundation

struct AcademicCalendarData {
    static let events: [AcademicEvent] = makeEvents()

    private static func makeEvents() -> [AcademicEvent] {
        let cal = Calendar.current
        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
            var c = DateComponents()
            c.year = year; c.month = month; c.day = day
            return cal.date(from: c) ?? Date()
        }

        return [
            // MARK: - 114-1（2025 第一學期）
            AcademicEvent(title: "114-1 開學日", date: date(2025, 9, 15), type: .general),
            AcademicEvent(title: "加退選開始（114-1）", date: date(2025, 9, 15), type: .registration),
            AcademicEvent(title: "加退選截止（114-1）", date: date(2025, 9, 26), type: .registration),
            AcademicEvent(title: "教師節放假", date: date(2025, 9, 28), type: .holiday),
            AcademicEvent(title: "中秋節放假", date: date(2025, 10, 6), type: .holiday),
            AcademicEvent(title: "國慶日放假", date: date(2025, 10, 10), type: .holiday),
            AcademicEvent(title: "台灣光復節放假", date: date(2025, 10, 24), type: .holiday),
            AcademicEvent(title: "期中考開始（114-1）", date: date(2025, 11, 10), type: .exam),
            AcademicEvent(title: "期中考結束（114-1）", date: date(2025, 11, 15), type: .exam),
            AcademicEvent(title: "校慶", date: date(2025, 12, 1), type: .general),
            AcademicEvent(title: "行憲紀念日放假", date: date(2025, 12, 25), type: .holiday),
            AcademicEvent(title: "元旦放假", date: date(2026, 1, 1), type: .holiday),
            AcademicEvent(title: "期末考開始（114-1）", date: date(2026, 1, 12), type: .exam),
            AcademicEvent(title: "期末考結束（114-1）", date: date(2026, 1, 17), type: .exam),
            AcademicEvent(title: "114-1 學期結束", date: date(2026, 1, 31), type: .general),

            // MARK: - 114-2（2026 第二學期）
            AcademicEvent(title: "除夕", date: date(2026, 2, 16), type: .holiday),
            AcademicEvent(title: "春節放假", date: date(2026, 2, 17), type: .holiday),
            AcademicEvent(title: "114-2 開學日", date: date(2026, 2, 23), type: .general),
            AcademicEvent(title: "加退選開始（114-2）", date: date(2026, 2, 23), type: .registration),
            AcademicEvent(title: "和平紀念日放假", date: date(2026, 2, 27), type: .holiday),
            AcademicEvent(title: "加退選截止（114-2）", date: date(2026, 3, 6), type: .registration),
            AcademicEvent(title: "校慶補假", date: date(2026, 4, 2), type: .holiday),
            AcademicEvent(title: "兒童節放假", date: date(2026, 4, 4), type: .holiday),
            AcademicEvent(title: "清明節放假", date: date(2026, 4, 5), type: .holiday),
            AcademicEvent(title: "期中考開始（114-2）", date: date(2026, 4, 20), type: .exam),
            AcademicEvent(title: "期中考結束（114-2）", date: date(2026, 4, 24), type: .exam),
            AcademicEvent(title: "勞動節放假", date: date(2026, 5, 1), type: .holiday),
            AcademicEvent(title: "畢業典禮", date: date(2026, 6, 12), type: .general),
            AcademicEvent(title: "端午節放假", date: date(2026, 6, 19), type: .holiday),
            AcademicEvent(title: "期末考開始（114-2）", date: date(2026, 6, 22), type: .exam),
            AcademicEvent(title: "期末考結束（114-2）", date: date(2026, 6, 27), type: .exam),
            AcademicEvent(title: "114-2 學期結束", date: date(2026, 7, 31), type: .general),
        ].sorted { $0.date < $1.date }
    }
}
