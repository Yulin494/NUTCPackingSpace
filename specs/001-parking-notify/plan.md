# Implementation Plan: 機車車位查詢與推播 (Parking Notify)

**Branch**: `001-parking-notify` | **Date**: 2025-12-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-parking-notify/spec.md`

## Summary

本功能旨在解決機車族尋找車位的痛點。透過解析學校網頁數據獲取即時車位資訊，並利用 CoreLocation 監測使用者位置，當接近校園中心 (500m) 時主動推播剩餘車位資訊。

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: 
- **SwiftUI**: UI 框架
- **CoreLocation**: 位置監測 (Geofencing)
- **UserNotifications**: 本地推播
- **Foundation (URLSession)**: 網路請求
- **SwiftSoup** (Optional): 用於解析 HTML 表格，若不引入則使用 String/Regex 處理。
**Architecture**: MVVM (Model-View-ViewModel)
**Storage**: UserDefaults (用於儲存最後一次已知位置或設定，若有)
**Testing**: XCTest (Unit Tests for Parser, ViewModel)
**Target Platform**: iOS 15.0+
**Project Type**: Mobile App (iOS)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Language First**: 介面與文件使用繁體中文。
- [x] **Modern iOS Stack**: 使用 Swift + SwiftUI。
- [x] **Architecture**: 採用 MVVM 架構。
- [x] **User Value**: 專注於準確查詢與即時推播。

## Project Structure

### Documentation (this feature)

```text
specs/001-parking-notify/
├── plan.md              # This file
├── spec.md              # Feature specification
└── tasks.md             # Implementation tasks
```

### Source Code (Proposed)

```text
NUTCParkingSpace/
├── App/
│   └── NUTCParkingSpaceApp.swift
├── Features/
│   └── Parking/
│       ├── Models/
│       │   └── ParkingLot.swift
│       ├── Services/
│       │   ├── ParkingDataService.swift (API & Parsing)
│       │   └── LocationService.swift (Geofencing)
│       ├── ViewModels/
│       │   └── ParkingListViewModel.swift
│       └── Views/
│           ├── ParkingListView.swift
│           └── ParkingRowView.swift
└── Shared/
    └── Extensions/
        └── Notification+Ext.swift
```
