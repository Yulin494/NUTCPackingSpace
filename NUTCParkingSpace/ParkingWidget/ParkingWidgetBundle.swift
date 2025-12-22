//
//  ParkingWidgetBundle.swift
//  ParkingWidget
//
//  Created by imac-3700 on 2025/12/22.
//

import WidgetKit
import SwiftUI

@main
struct ParkingWidgetBundle: WidgetBundle {
    var body: some Widget {
        ParkingWidget()
        ParkingLiveActivity()
    }
}
