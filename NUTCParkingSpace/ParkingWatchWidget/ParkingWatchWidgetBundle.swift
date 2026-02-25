//
//  ParkingWatchWidgetBundle.swift
//  ParkingWatchWidget
//
//  Created by imac-3888 on 2026/2/23.
//

import WidgetKit
import SwiftUI

@main
struct ParkingWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        ParkingWatchWidget()
        // ParkingWatchWidgetControl() // 暫時註解掉預設的 Control
    }
}
