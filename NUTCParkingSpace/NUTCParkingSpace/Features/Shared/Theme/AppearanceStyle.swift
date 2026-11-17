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

// MARK: - App Group 同步（供 Widget／即時動態讀取）

extension AppearanceStyle {
    /// App 與 Widget 共用的 App Group 名稱（與 SharedParkingCache 相同）
    static let appGroupSuiteName = "group.com.yulin494.NUTCParkingSpace"
    /// 與 `@AppStorage("appearanceStyle")` 相同的 key
    static let storageKey = "appearanceStyle"

    /// 把目前樣式寫進 App Group，讓 Widget extension 讀得到（App 的 standard UserDefaults 它讀不到）
    func syncToAppGroup() {
        UserDefaults(suiteName: Self.appGroupSuiteName)?.set(rawValue, forKey: Self.storageKey)
    }

    /// 從 App Group 讀取樣式；未同步過或讀不到時退回標準
    static func fromAppGroup() -> AppearanceStyle {
        guard let raw = UserDefaults(suiteName: appGroupSuiteName)?.string(forKey: storageKey),
              let style = AppearanceStyle(rawValue: raw) else { return .standard }
        return style
    }
}
