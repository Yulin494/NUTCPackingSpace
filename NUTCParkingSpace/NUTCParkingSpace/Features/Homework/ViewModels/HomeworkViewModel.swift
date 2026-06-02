//
//  HomeworkViewModel.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI
import SwiftData
import UserNotifications

class HomeworkViewModel: ObservableObject {
    @Published var homeworks: [HomeworkItem] = []

    func scheduleNotification(for homework: HomeworkItem) {
        let content = UNMutableNotificationContent()
        content.title = "作業提醒"
        content.body = "《\(homework.courseName)》的《\(homework.title)》明天截止"
        content.sound = .default

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: homework.dueDate)
        components.hour = 9
        components.minute = 0

        if let notifyDate = calendar.date(from: components) {
            let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notifyDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
}
