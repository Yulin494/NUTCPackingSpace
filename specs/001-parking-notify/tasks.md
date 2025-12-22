---
description: "Task list for Parking Notify feature"
---

# Tasks: 機車車位查詢與推播 (Parking Notify)

**Input**: Design documents from `specs/001-parking-notify/`
**Prerequisites**: plan.md, spec.md

**Tests**: Tests are OPTIONAL - only included if explicitly requested.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Project Initialization)

**Purpose**: 初始化專案結構與權限。

- [x] T001 建立名為 `NUTCParkingSpace` 的新 iOS App 專案 (SwiftUI, Swift)
- [x] T002 建立專案資料夾結構：`Features/Parking/` 及其子資料夾 `Models`, `Services`, `ViewModels`, `Views`
- [x] T003 設定 `Info.plist` 加入位置使用權限描述 (`NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`)
- [x] T004 在專案設定中啟用 "Background Modes" 功能 (Location updates, Background fetch)

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 所有故事所需的核心資料模型與服務。

- [x] T005 [US1] 在 `NUTCParkingSpace/Features/Parking/Models/ParkingLot.swift` 建立 `ParkingLot` struct (屬性: name, availableCount, coordinate)
- [x] T006 [US1] 在 `NUTCParkingSpace/Features/Parking/Services/ParkingDataService.swift` 建立 `ParkingDataService` class (Singleton 或依賴注入)
- [x] T007 [US1] 在 `ParkingDataService.swift` 實作 HTML 解析邏輯，從 `https://apps.nutc.edu.tw/getParking/showParkingData.php` 提取停車場表格資料
- [x] T008 [US2] 在 `NUTCParkingSpace/Features/Parking/Services/LocationService.swift` 建立 `LocationService` class，繼承自 `NSObject`, `CLLocationManagerDelegate`

## Phase 3: User Story 1 - 查詢車位列表 (Priority: P1)

**Goal**: 使用者可以查看停車場列表及其剩餘車位。
**Independent Test**: 執行 App，看到停車場列表與網頁資料一致。

- [x] T009 [US1] 在 `ParkingDataService.swift` 使用 `URLSession` 實作 `fetchParkingData` 方法
- [x] T010 [US1] 在 `NUTCParkingSpace/Features/Parking/ViewModels/ParkingListViewModel.swift` 建立 `ParkingListViewModel` (ObservableObject, 發布 `parkingLots`)
- [x] T011 [P] [US1] 在 `NUTCParkingSpace/Features/Parking/Views/ParkingRowView.swift` 建立 `ParkingRowView` 以顯示單一停車場資訊
- [x] T012 [US1] 在 `NUTCParkingSpace/Features/Parking/Views/ParkingListView.swift` 建立 `ParkingListView`，使用 `List` 與 `ParkingRowView`
- [x] T013 [US1] 將 `ParkingListViewModel` 整合至 `ParkingListView` 並在出現時觸發資料抓取

## Phase 4: User Story 2 - 鄰近車位推播 (Priority: P2)

**Goal**: 使用者接近校園中心時收到通知。
**Independent Test**: 在模擬器模擬位置至 `24.149691, 120.683974`，確認通知出現。

- [x] T014 [US2] 在 `LocationService.swift` 實作 `requestPermissions` 以請求 Always/WhenInUse 授權
- [x] T015 [US2] 在 `LocationService.swift` 實作 `startMonitoring` 以監控 `24.149691, 120.683974` 周圍 500m 半徑
- [x] T016 [US2] 在 `NUTCParkingSpaceApp.swift` 或專用 `NotificationManager` 實作 `UNUserNotificationCenter` 設定
- [x] T017 [US2] 在 `LocationService.swift` 實作 `locationManager(_:didEnterRegion:)` 以觸發 `ParkingDataService.fetchParkingData`
- [x] T018 [US2] 在 `LocationService.swift` 實作發送本地通知邏輯 (或透過 delegate 回傳給 ViewModel/App)
- [x] T019 [US2] 在 `LocationService.swift` 實作冷卻機制 (例如 `lastNotificationTime`) 以避免重複通知

## Phase 5: Polish & Cross-Cutting

**Purpose**: UX 改進與最後修飾。

- [x] T020 [US1] 為 `ParkingListView` 加入 "下拉更新" (Pull to Refresh) 支援
- [x] T021 [US1] 為 `ParkingListView` 加入網路失敗時的錯誤處理 UI (Alert 或 Placeholder)
- [x] T022 [Polish] 檢查所有 UI 標籤確保使用繁體中文

## Dependencies

1. **Setup** (T001-T004) -> **Foundational** (T005-T008)
2. **Foundational** -> **US1** (T009-T013)
3. **Foundational** -> **US2** (T014-T019)
4. **US1** & **US2** can be developed in parallel after Foundational phase.

## Implementation Strategy

1. **MVP (US1)**: Focus on getting the data on screen first. This validates the API parsing and basic UI.
2. **Enhancement (US2)**: Add the location layer on top. Since `LocationService` is separate, it won't break US1.
3. **Polish**: Handle edge cases like network errors and "spammy" notifications last.
