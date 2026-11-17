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

private let previewAttributes = ParkingAttributes(title: "停車追蹤")

private let previewAllLots = [
    LiteLot(name: "中技大樓", available: 86, total: 120),
    LiteLot(name: "資訊館", available: 31, total: 100),
    LiteLot(name: "中科平面", available: 9, total: 80),
    LiteLot(name: "錦平街", available: 0, total: 60),
    LiteLot(name: "中商停車場", available: 24, total: 40),
    LiteLot(name: "中技停車場", available: 3, total: 50),
    LiteLot(name: "中科停車場", available: 12, total: 30),
    LiteLot(name: "測試停車場", available: 45, total: 90),
    LiteLot(name: "備用停車場", available: 7, total: 20),
]

private func previewState(_ count: Int) -> ParkingAttributes.ContentState {
    ParkingAttributes.ContentState(lots: Array(previewAllLots.prefix(count)), lastUpdated: Date())
}

private let previewSingle = previewState(1)
private let previewMulti = previewState(4)

#Preview("像素 鎖定畫面", as: .content, using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .pixel)
} contentStates: {
    previewState(1)
    previewState(3)
    previewState(6)
    previewState(8)
    previewState(9)
}

#Preview("標準 鎖定畫面", as: .content, using: previewAttributes) {
    ParkingLiveActivity(appearanceOverride: .standard)
} contentStates: {
    previewState(1)
    previewState(3)
    previewState(6)
    previewState(8)
    previewState(9)
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
    previewSingle
}
