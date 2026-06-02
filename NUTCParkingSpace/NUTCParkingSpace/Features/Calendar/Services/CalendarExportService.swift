import EventKit
import Foundation
import UIKit

struct CalendarExportService {
    private static let store = EKEventStore()
    private static let calendarTitle = "NUTC 學年行事曆"

    enum ExportError: LocalizedError {
        case denied
        case calendarCreationFailed

        var errorDescription: String? {
            switch self {
            case .denied:                 return "未授權存取日曆，請至設定中開啟。"
            case .calendarCreationFailed: return "無法建立日曆。"
            }
        }
    }

    // MARK: - 匯出入口

    static func exportAll() async throws -> Int {
        let granted = try await store.requestFullAccessToEvents()
        guard granted else { throw ExportError.denied }

        let ekCalendar = try findOrCreateCalendar()
        let exportItems = buildExportItems(from: AcademicCalendarData.events)
        var added = 0

        for item in exportItems {
            // 重複檢查：在起訖範圍內找同標題
            let searchEnd = Calendar.current.date(byAdding: .day, value: 1, to: item.endDate)!
            let existing = store.events(matching: store.predicateForEvents(
                withStart: item.startDate, end: searchEnd, calendars: [ekCalendar]
            ))
            if existing.contains(where: { $0.title == item.title }) { continue }

            let ekEvent = EKEvent(eventStore: store)
            ekEvent.title     = item.title
            ekEvent.calendar  = ekCalendar
            ekEvent.isAllDay  = true
            ekEvent.startDate = item.startDate
            // EKEvent 全天事件的 endDate 是「最後一天的隔天凌晨」
            ekEvent.endDate   = Calendar.current.date(byAdding: .day, value: 1, to: item.endDate)!
            ekEvent.notes     = item.type
            try store.save(ekEvent, span: .thisEvent)
            added += 1
        }

        try store.commit()
        return added
    }

    // MARK: - 合併區段事件

    private struct ExportItem {
        let title: String
        let startDate: Date
        let endDate: Date
        let type: String
    }

    /// 把「期中考開始」+「期中考結束」合併成單一多天行程；其餘保持單天
    private static func buildExportItems(from events: [AcademicEvent]) -> [ExportItem] {
        var consumed = Set<String>()
        var items: [ExportItem] = []
        let cal = Calendar.current

        for event in events {
            guard !consumed.contains(event.title) else { continue }

            if event.title.contains("開始") {
                // 把「開始」拿掉後，比對同樣去掉「結束」或「截止」的標題
                let base = event.title.replacingOccurrences(of: "開始", with: "")

                if let endEvent = events.first(where: { ev in
                    !consumed.contains(ev.title) &&
                    ev.date >= event.date &&
                    (ev.title.replacingOccurrences(of: "結束", with: "") == base ||
                     ev.title.replacingOccurrences(of: "截止", with: "") == base)
                }) {
                    // 區段行程：標題去掉括號後的「開始」語意，顯示為「期中考（114-1）」
                    let rangeTitle = base.trimmingCharacters(in: .whitespaces)
                    items.append(ExportItem(
                        title: rangeTitle,
                        startDate: cal.startOfDay(for: event.date),
                        endDate:   cal.startOfDay(for: endEvent.date),
                        type: event.type.rawValue
                    ))
                    consumed.insert(event.title)
                    consumed.insert(endEvent.title)
                    continue
                }
            }

            // 單天行程
            items.append(ExportItem(
                title: event.title,
                startDate: cal.startOfDay(for: event.date),
                endDate:   cal.startOfDay(for: event.date),
                type: event.type.rawValue
            ))
            consumed.insert(event.title)
        }

        return items
    }

    // MARK: - 找或建立日曆

    private static func findOrCreateCalendar() throws -> EKCalendar {
        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            return existing
        }
        guard let source = store.defaultCalendarForNewEvents?.source
                        ?? store.sources.first(where: { $0.sourceType == .local })
        else { throw ExportError.calendarCreationFailed }

        let cal = EKCalendar(for: .event, eventStore: store)
        cal.title   = calendarTitle
        cal.source  = source
        cal.cgColor = UIColor.systemBlue.cgColor
        try store.saveCalendar(cal, commit: true)
        return cal
    }
}
