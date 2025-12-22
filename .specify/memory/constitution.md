<!--
Sync Impact Report:
- Version Change: 0.0.0 -> 1.0.0
- Modified Principles:
  - Added: Language First (語言優先)
  - Added: Modern iOS Stack (現代 iOS 技術棧)
  - Added: Architecture (架構模式)
  - Added: User Value (用戶價值)
- Added Sections: Technical Constraints, Development Workflow
- Removed Sections: None
- Templates Requiring Updates: None
-->
# NUTCParkingSpace Constitution

## Core Principles

### I. Language First (語言優先)
App 介面與所有文件（包括程式碼註解、提交訊息、規格書）必須使用 **繁體中文 (Traditional Chinese)**。這確保了目標用戶與開發團隊的溝通無礙。

### II. Modern iOS Stack (現代 iOS 技術棧)
開發必須使用 **Swift** 語言與 **SwiftUI** 框架。禁止使用 Objective-C 或 UIKit（除非遇到 SwiftUI 無法實現的特定 API 限制，且需經過審核）。

### III. Architecture (架構模式)
程式碼必須遵循 **MVVM (Model-View-ViewModel)** 架構模式。程式碼需高度模組化，確保業務邏輯與 UI 分離，以提升可維護性與可測試性。

### IV. User Value (用戶價值)
核心價值在於提供 **準確的車位查詢** 與 **即時的剩餘車位推播**。這些功能必須被優先實作並經過嚴格測試，確保資料的即時性與準確性。

## Technical Constraints

- **Target Platform**: iOS 15.0+
- **Device Support**: iPhone (Portrait mode primarily)
- **Network**: Must handle offline/poor network states gracefully.

## Development Workflow

- **Branching**: Feature branches (`feat/name`) merged into `main` via PR.
- **Commits**: Conventional Commits format in Traditional Chinese (e.g., `feat: 新增車位列表頁面`).

## Governance

本憲章為專案最高指導原則。任何修改需經由 Pull Request 提出，並更新版本號。
所有 PR 審查必須驗證是否符合上述原則。

**Version**: 1.0.0 | **Ratified**: 2025-12-21 | **Last Amended**: 2025-12-21
