import UserNotifications
import Foundation
import NUTCParkingShared

actor ScheduleNotificationService {
    static let shared = ScheduleNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let idPrefix = "nutc.schedule."

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func reschedule(courses: [SharedCourse]) async {
        guard UserDefaults.standard.object(forKey: "courseNotificationsEnabled")
                .map({ $0 as? Bool ?? true }) ?? true
        else {
            let pending = await center.pendingNotificationRequests()
            let ids = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            return
        }

        // 移除所有舊的上課通知
        let pending = await center.pendingNotificationRequests()
        let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)

        let settings = await center.notificationSettings()
        if settings.authorizationStatus != .authorized {
            let ok = await requestPermission()
            if !ok { return }
        }

        let minutesBefore = UserDefaults.standard.integer(forKey: "notifyMinutesBefore")
        let advance = minutesBefore > 0 ? minutesBefore : 15

        for course in courses {
            guard course.startPeriod >= 1, course.startPeriod <= 14,
                  let startTime = course.startTime
            else { continue }

            // 提前 N 分鐘
            var notifyMin = startTime.minute - advance
            var notifyHour = startTime.hour
            if notifyMin < 0 { notifyMin += 60; notifyHour -= 1 }

            var dc = DateComponents()
            // NUTC 1=Mon..7=Sun → Calendar.weekday 2=Mon..1=Sun
            dc.weekday = (course.weekday % 7) + 1
            dc.hour    = notifyHour
            dc.minute  = notifyMin

            let content = UNMutableNotificationContent()
            content.title = "即將上課"
            content.body  = "\(course.name)（\(course.room)）\(advance) 分鐘後開始"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let id = "\(idPrefix)\(course.weekday)-\(course.startPeriod)-\(abs(course.name.hashValue))"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
