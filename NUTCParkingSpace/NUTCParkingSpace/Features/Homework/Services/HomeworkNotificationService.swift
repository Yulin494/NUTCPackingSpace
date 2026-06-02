import UserNotifications
import Foundation

actor HomeworkNotificationService {
    static let shared = HomeworkNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let idPrefix = "nutc.homework."

    func reschedule(homeworks: [HomeworkItem]) async {
        guard UserDefaults.standard.object(forKey: "homeworkNotificationsEnabled")
                .map({ $0 as? Bool ?? true }) ?? true
        else {
            removeAll()
            return
        }

        let settings = await center.notificationSettings()
        if settings.authorizationStatus != .authorized {
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true
            else { return }
        }

        removeAll()

        let today = Calendar.current.startOfDay(for: Date())

        for hw in homeworks where !hw.isCompleted {
            let due = Calendar.current.startOfDay(for: hw.dueDate)
            guard due >= today else { continue }

            // 到期前一天（早上 9 點）
            let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: due)!
            if dayBefore >= today {
                schedule(
                    id: "\(idPrefix)early-\(hw.title.hashValue)-\(hw.dueDate.timeIntervalSince1970)",
                    title: "作業明天到期",
                    body: "\(hw.courseName)：\(hw.title)",
                    at: at(date: dayBefore, hour: 9, minute: 0)
                )
            }

            // 到期當天（早上 9 點）
            schedule(
                id: "\(idPrefix)due-\(hw.title.hashValue)-\(hw.dueDate.timeIntervalSince1970)",
                title: "作業今天到期",
                body: "\(hw.courseName)：\(hw.title) 今天截止！",
                at: at(date: due, hour: 9, minute: 0)
            )
        }
    }

    private func removeAll() {
        Task {
            let pending = await center.pendingNotificationRequests()
            let ids = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func schedule(id: String, title: String, body: String, at date: Date) {
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        Task {
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    private func at(date: Date, hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour; comps.minute = minute
        return Calendar.current.date(from: comps) ?? date
    }
}
