//
//  ParkingWidgetControl.swift
//  ParkingWidget
//
//  Created by imac-3700 on 2025/12/22.
//

import AppIntents
import SwiftUI
import WidgetKit

struct ParkingWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.yulin494.NUTCParkingSpace.ParkingWidget",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value,
                action: StartTimerIntent()
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }

        .displayName("計時器")
        .description("一個顯示如何執行計時器的範例控制項。")
    }
}

extension ParkingWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool {
            false
        }

        func currentValue() async throws -> Bool {
            let isRunning = true // 檢查計時器是否正在執行
            return isRunning
        }
    }
}

struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer is running")
    var value: Bool

    func perform() async throws -> some IntentResult {
        // 根據 `value` 啟動/停止計時器
        return .result()
    }
}
