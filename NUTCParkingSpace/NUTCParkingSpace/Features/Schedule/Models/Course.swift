//
//  Course.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftData
import Foundation

@Model
final class Course {
    var name: String
    var instructor: String
    var room: String
    var weekday: Int          // 1=週一 ... 7=週日
    var startPeriod: Int      // 節次（1-14）
    var endPeriod: Int
    var color: String         // hex color string
    var semester: String      // "113-2"
    var createdAt: Date

    init(
        name: String,
        instructor: String,
        room: String,
        weekday: Int,
        startPeriod: Int,
        endPeriod: Int,
        color: String = "#007AFF",
        semester: String = "114-1"
    ) {
        self.name = name
        self.instructor = instructor
        self.room = room
        self.weekday = weekday
        self.startPeriod = startPeriod
        self.endPeriod = endPeriod
        self.color = color
        self.semester = semester
        self.createdAt = Date()
    }
}
