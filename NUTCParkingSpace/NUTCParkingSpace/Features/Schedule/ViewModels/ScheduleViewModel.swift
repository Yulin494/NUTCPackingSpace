//
//  ScheduleViewModel.swift
//  NUTCParkingSpace
//
//  Created by Claude
//

import SwiftUI
import SwiftData
import Foundation

class ScheduleViewModel: ObservableObject {
    var weekDays = ["週一", "週二", "週三", "週四", "週五", "週六", "週日"]
    var periods = (1...14).map { "\($0)" }
}
