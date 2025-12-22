# Feature Specification: 機車車位查詢與推播 (Parking Notify)

**Feature Branch**: `001-parking-notify`
**Created**: 2025-12-21
**Status**: Draft
**Input**: User description: "目前我想要做的是一個停車場的查詢剩餘車位的系統 因為是機車的車位，使用者沒有時間去搜尋，所以我想要使用者距離500公尺就本地推播哪些機車停車場有位置和剩餘多少機車停車位，搜尋車位的話就直接打api Get https://apps.nutc.edu.tw/getParking/showParkingData.php"

## Clarifications

### Session 2025-12-21
- Q: How should the provided coordinate (`24.149691, 120.683974`) be used for multiple parking lots? → A: Use it as the **Campus Center** reference point. Entering the 500m radius of this point triggers notifications for all available lots.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 查詢車位列表 (Priority: P1)

使用者打開 App，希望能立即看到所有機車停車場的剩餘車位資訊，以便決定前往哪個停車場。

**Why this priority**: 這是最基礎的功能，確保使用者能主動獲取資訊。

**Independent Test**: 
- 打開 App，確認列表顯示正確的停車場名稱與剩餘車位數。
- 比對 App 顯示的數據與網頁版 (https://apps.nutc.edu.tw/getParking/showParkingData.php) 是否一致。

**Acceptance Scenarios**:

1. **Given** 使用者打開 App, **When** 網路連線正常, **Then** 顯示所有機車停車場列表，包含名稱與剩餘車位數。
2. **Given** 使用者打開 App, **When** 網路連線失敗, **Then** 顯示錯誤訊息並提供重試按鈕。
3. **Given** 停車場資料更新, **When** 使用者手動下拉更新, **Then** 列表顯示最新數據。

---

### User Story 2 - 鄰近車位推播 (Priority: P2)

當使用者騎車接近某個機車停車場（距離 500 公尺內）時，App 主動發送推播通知，告知該停車場的剩餘車位，讓使用者無需停車操作手機即可得知資訊。

**Why this priority**: 解決使用者「沒有時間搜尋」的痛點，提供主動式服務。

**Independent Test**: 
- 使用 Xcode 模擬位置功能，將位置移動到距離某停車場 500 公尺內。
- 確認手機收到本地推播通知，內容包含停車場名稱與剩餘車位。

**Acceptance Scenarios**:

1. **Given** App 在背景執行且授權位置服務, **When** 使用者進入停車場 500 公尺範圍內, **Then** 發送本地推播通知：「[停車場名稱] 還有 [N] 個車位」。
2. **Given** 使用者已收到某停車場通知, **When** 使用者仍在該範圍內徘徊, **Then** 在短時間內（例如 10 分鐘）不重複發送相同通知，避免干擾。
3. **Given** 停車場已滿（0 車位）, **When** 使用者進入範圍, **Then** 發送通知告知已滿，建議前往其他停車場（若有）。

---

### Edge Cases

- **API 格式變更**: 若學校網頁改版，解析失敗時應顯示「維護中」或舊資料（標示時間）。
- **無位置權限**: 若使用者拒絕位置權限，應在首頁提示開啟權限以使用推播功能。
- **多個停車場重疊**: 若同時進入多個停車場範圍，應合併通知或僅推播最近/最多車位的一個。

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系統必須能發送 HTTP GET 請求至 `https://apps.nutc.edu.tw/getParking/showParkingData.php`。
- **FR-002**: 系統必須能解析回傳的 HTML，提取「機車停車場」區塊的表格資料（停車場名稱、尚有車位數）。
- **FR-003**: 系統必須內建「校園中心座標」(`24.149691, 120.683974`) 作為統一參考點。
- **FR-004**: 系統必須請求使用者的位置權限（建議 `Always` 或 `When In Use` 搭配背景模式）。
- **FR-005**: 系統必須監控使用者位置，當距離「校園中心座標」小於 500 公尺時觸發事件。
- **FR-006**: 系統必須發送本地推播通知 (Local Notification)，顯示停車場名稱與剩餘車位。
- **FR-007**: 系統必須具備冷卻機制 (Cool-down)，避免同一停車場在短時間內重複推播。

### Key Entities *(include if feature involves data)*

- **ParkingLot**: 代表一個停車場，包含名稱 (Name)、剩餘車位 (AvailableCount)、座標 (Coordinate)、最後更新時間 (LastUpdated)。

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: App 能在 3 秒內完成資料抓取與解析並顯示於列表。
- **SC-002**: 當使用者進入 500 公尺範圍內，通知應在 30 秒內觸發。
- **SC-003**: 解析邏輯能正確處理 API 回傳的 HTML 表格，準確率 100%。

## Assumptions

- 假設學校 API 的 HTML 結構短期內不會大幅變動。
- 假設使用者願意開啟位置權限以獲取推播服務。
- 假設停車場的經緯度座標是固定的，將由開發者手動測量並寫入 App。

