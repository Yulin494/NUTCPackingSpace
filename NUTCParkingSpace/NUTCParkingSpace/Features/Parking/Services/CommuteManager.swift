import Foundation
import ActivityKit
import CoreLocation
import Combine
import NUTCParkingShared

class CommuteManager: NSObject, ObservableObject {
    static let shared = CommuteManager()

    /// 正在追蹤的停車場名稱（依加入順序）。空集合代表沒有進行中的即時動態。
    @Published private(set) var trackedLotNames: [String] = []

    var isCommuting: Bool { !trackedLotNames.isEmpty }

    /// 橫幅說明：單一時顯示名稱，多個時顯示數量
    var trackingDescription: String? {
        switch trackedLotNames.count {
        case 0: return nil
        case 1: return "正在追蹤 \(trackedLotNames[0])"
        default: return "正在追蹤 \(trackedLotNames.count) 個停車場"
        }
    }

    private var currentActivity: Activity<ParkingAttributes>?
    private var timer: Timer?
    /// 最近一次取得的各停車場資料（以名稱索引），用來在增減追蹤時立即組出新內容
    private var liteCache: [String: LiteLot] = [:]
    private var debugStarted = false
    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        setupLocationManager()
        restoreIfNeeded()
    }

    private func setupLocationManager() {
        // 背景執行必要設定。
        // 這裡的定位僅用於在追蹤期間保持 App 喚醒（實際車位資料靠 30 秒計時器抓取），
        // 因此使用較省電的精度即可，不需要 kCLLocationAccuracyBest 持續高精度定位。
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // 每移動約 50m 才更新，降低耗電
        locationManager.delegate = self
    }

    // MARK: - 追蹤集合

    func isTracking(_ lot: ParkingLot) -> Bool {
        trackedLotNames.contains(lot.name)
    }

    /// 長按選單：不在集合就加入，在就移除；移除到空集合時結束即時動態
    func toggleTracking(for lot: ParkingLot) {
        if let index = trackedLotNames.firstIndex(of: lot.name) {
            trackedLotNames.remove(at: index)
            if trackedLotNames.isEmpty {
                stopCommuting()
            } else {
                pushCurrentState()
            }
        } else {
            add([lot])
        }
    }

    /// 把所有機車場加入集合（已在追蹤時合併，不重開即時動態）
    func startTrackingAll() {
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            self?.add(lots.filter { $0.type == .motorcycle })
        }
    }

    func stopCommuting() {
        // 結束即時動態（先取出參考再清除，避免和緊接著的新會話互相覆蓋）
        let activity = currentActivity
        currentActivity = nil
        Task { await activity?.end(dismissalPolicy: .immediate) }

        // 停止定位與計時器
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil

        trackedLotNames = []
        print("停止通勤模式")
    }

    /// App 被系統終止後重開：若即時動態仍在進行，從其內容還原集合與計時器
    func restoreIfNeeded() {
        guard currentActivity == nil,
              let activity = Activity<ParkingAttributes>.activities.first(where: { $0.activityState == .active })
        else { return }
        let lots = activity.content.state.lots
        guard !lots.isEmpty else {
            Task { await activity.end(dismissalPolicy: .immediate) }
            return
        }
        currentActivity = activity
        // 只保留一個，其餘殘留的即時動態一併結束
        for extra in Activity<ParkingAttributes>.activities where extra.id != activity.id {
            Task { await extra.end(dismissalPolicy: .immediate) }
        }
        for lot in lots { liteCache[lot.name] = lot }
        trackedLotNames = lots.map(\.name)
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        startTimer()
    }

    private func add(_ lots: [ParkingLot]) {
        let newLots = lots.filter { !trackedLotNames.contains($0.name) }
        // 已在追蹤的也順便刷新資料
        for lot in lots { liteCache[lot.name] = Self.lite(lot) }
        guard !newLots.isEmpty else { pushCurrentState(); return }

        let isFirst = currentActivity == nil
        if isFirst {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("即時動態功能未啟用")
                return
            }
            guard requestActivity(lots: newLots.map(Self.lite)) else { return }
        }
        trackedLotNames.append(contentsOf: newLots.map(\.name))
        if isFirst {
            // 背景定位 (保持 App 喚醒) 與計時器抓取資料
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            startTimer()
        } else {
            pushCurrentState()
        }
    }

    /// 只在第一個追蹤時呼叫：開啟即時動態
    private func requestActivity(lots: [LiteLot]) -> Bool {
        let state = ParkingAttributes.ContentState(lots: lots, lastUpdated: Date())
        do {
            let activity = try Activity.request(
                attributes: ParkingAttributes(title: "停車追蹤"),
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("啟動即時動態: \(activity.id)")
            return true
        } catch {
            print("啟動即時動態失敗: \(error)")
            return false
        }
    }

    private static func lite(_ lot: ParkingLot) -> LiteLot {
        LiteLot(name: lot.name, available: lot.availableCount, total: lot.totalCapacity)
    }

    /// 用快取依集合順序組出目前內容並更新即時動態
    private func pushCurrentState() {
        send(trackedLotNames.compactMap { liteCache[$0] })
    }

    private func startTimer() {
        timer?.invalidate()
        // 在 main run loop 排程計時器
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchAndUpdate()
        }
    }

    private func fetchAndUpdate() {
        guard isCommuting else { return }
        print("正在抓取資料更新動態...")

        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            guard let self = self else { return }
            // 依集合順序挑出最新資料，找不到的名稱略過
            let targets = self.trackedLotNames.compactMap { name in
                lots.first(where: { $0.name == name }).map(Self.lite)
            }
            for lot in targets { self.liteCache[lot.name] = lot }
            if !targets.isEmpty { self.send(targets) }
        }
    }

    /// 只更新內容，不重開即時動態
    private func send(_ liteLots: [LiteLot]) {
        guard let activity = currentActivity, !liteLots.isEmpty else { return }
        let contentState = ParkingAttributes.ContentState(lots: liteLots, lastUpdated: Date())
        Task {
            await activity.update(ActivityContent(state: contentState, staleDate: nil))
            print("更新即時動態: \(liteLots.count) 筆資料")
        }
    }
}

extension CommuteManager {
    /// 外觀切換後重繪進行中的即時動態：用目前資料再 update 一次（樣式由 widget 讀 App Group）
    func refreshAppearance() {
        guard let activity = currentActivity else { return }
        let state = activity.content.state
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    #if DEBUG
    /// DEBUG：啟動參數 `-DebugStartLiveActivity N`（N=1…8，`YES` 視同 4）時，用假資料開 N 個停車場的即時動態（截圖用）
    func debugStartIfRequested() {
        guard !debugStarted,
              let raw = UserDefaults.standard.string(forKey: "DebugStartLiveActivity"),
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let count = Int(raw).map { min(max($0, 1), 8) } ?? (raw.uppercased() == "YES" ? 4 : 0)
        guard count > 0 else { return }
        debugStarted = true
        stopCommuting() // 清掉還原回來的舊即時動態
        let all = [
            LiteLot(name: "中技大樓", available: 86, total: 120),
            LiteLot(name: "資訊館", available: 31, total: 100),
            LiteLot(name: "中科平面", available: 9, total: 80),
            LiteLot(name: "錦平街", available: 0, total: 60),
            LiteLot(name: "中商停車場", available: 24, total: 40),
            LiteLot(name: "中技停車場", available: 3, total: 50),
            LiteLot(name: "中科停車場", available: 12, total: 30),
            LiteLot(name: "測試停車場", available: 45, total: 90),
        ]
        let state = ParkingAttributes.ContentState(lots: Array(all.prefix(count)), lastUpdated: Date())
        Task { @MainActor in
            // 先等舊的全部結束，避免超過同時進行的即時動態上限
            for old in Activity<ParkingAttributes>.activities {
                await old.end(dismissalPolicy: .immediate)
            }
            self.currentActivity = try? Activity.request(
                attributes: ParkingAttributes(title: "停車追蹤"),
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        }
    }
    #endif
}

extension CommuteManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 背景位置更新以保持 App 存活。
        // 我們不需要在此處理位置資料，
        // 但接收更新可確保系統知道我們仍處於活躍狀態。
        // print("收到保持喚醒位置更新")
    }
}
