//
//  ParkingLiveActivityPreviews.swift
//  ParkingWidget
//
//  即時動態 Preview：像素與標準各一組（用 appearanceOverride 注入樣式，不讀 App Group）。
//

import ActivityKit
import SwiftUI
import WidgetKit
import NUTCParkingShared

private let previewAttributes = ParkingAttributes(title: "全校車位概況")

private let previewMulti = ParkingAttributes.ContentState(
    lots: [
        LiteLot(name: "機車一場", available: 86, total: 120),
        LiteLot(name: "機車二場", available: 31, total: 100),
        LiteLot(name: "機車三場", available: 9, total: 80),
        LiteLot(name: "機車四場", available: 0, total: 60),
    ],
    lastUpdated: Date()
)

private let previewSingle = ParkingAttributes.ContentState(
    lots: [LiteLot(name: "機車一場", available: 17, total: 120)],
    lastUpdated: Date()
)

#Preview("像素 鎖定畫面", as: .content, using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .pixel)
} contentStates: {
    previewMulti
    previewSingle
}

#Preview("標準 鎖定畫面", as: .content, using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .standard)
} contentStates: {
    previewMulti
    previewSingle
}

#Preview("像素 動態島 expanded", as: .dynamicIsland(.expanded), using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .pixel)
} contentStates: {
    previewMulti
}

#Preview("像素 動態島 compact", as: .dynamicIsland(.compact), using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .pixel)
} contentStates: {
    previewMulti
    previewSingle
}

#Preview("像素 動態島 minimal", as: .dynamicIsland(.minimal), using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .pixel)
} contentStates: {
    previewMulti
}

#Preview("標準 動態島 expanded", as: .dynamicIsland(.expanded), using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .standard)
} contentStates: {
    previewMulti
}

#Preview("標準 動態島 compact", as: .dynamicIsland(.compact), using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .standard)
} contentStates: {
    previewMulti
}
