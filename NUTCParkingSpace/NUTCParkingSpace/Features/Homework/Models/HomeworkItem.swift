//
//  HomeworkItem.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftData
import Foundation

@Model
final class HomeworkItem {
    var title: String
    var courseName: String
    var dueDate: Date
    var isCompleted: Bool
    var note: String?
    var createdAt: Date

    init(
        title: String,
        courseName: String,
        dueDate: Date,
        isCompleted: Bool = false,
        note: String? = nil
    ) {
        self.title = title
        self.courseName = courseName
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.note = note
        self.createdAt = Date()
    }
}
