//
//  AcademicEvent.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import Foundation

struct AcademicEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let type: EventType
}

enum EventType: String {
    case exam = "考試"
    case holiday = "放假"
    case registration = "加退選"
    case general = "其他"
}
