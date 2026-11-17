//
//  AppearanceStyle.swift
//  NUTCParkingSpace
//
//  外觀風格：標準（系統原生）或像素（概念 C 像素校園地圖）。
//

import SwiftUI

/// 外觀風格。以 `@AppStorage("appearanceStyle")` 儲存 rawValue，預設 `.standard`。
enum AppearanceStyle: String, CaseIterable, Identifiable {
    case standard
    case pixel

    var id: String { rawValue }

    /// 設定頁顯示用名稱
    var title: String {
        switch self {
        case .standard: return "標準"
        case .pixel: return "像素"
        }
    }
}

// MARK: - Environment 注入

private struct AppearanceStyleKey: EnvironmentKey {
    static let defaultValue: AppearanceStyle = .standard
}

extension EnvironmentValues {
    /// 目前外觀風格，由 App 入口讀取 AppStorage 後注入。
    var appearanceStyle: AppearanceStyle {
        get { self[AppearanceStyleKey.self] }
        set { self[AppearanceStyleKey.self] = newValue }
    }
}
