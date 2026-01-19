import Foundation
import ActivityKit
import CoreLocation
import Combine

class CommuteManager: NSObject, ObservableObject {
    static let shared = CommuteManager()
    
    @Published var isCommuting = false
    @Published var trackingDescription: String?
    
    enum TrackingMode {
        case single(String)
        case all
    }
    
    private var trackingMode: TrackingMode?
    private var currentActivity: Activity<ParkingAttributes>?
    private var timer: Timer?
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        // 背景執行必要設定
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // 接收所有更新以保持 App 喚醒
        locationManager.delegate = self
    }
    
    func startCommuting(for lot: ParkingLot) {
        startTracking(mode: .single(lot.name), initialLots: [lot])
    }
    
    func startTrackingAll() {
        // Fetch all lots first to start immediately
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            // Filter motorcycle lots for "all" tracking usually
            let motorLots = lots.filter { $0.type == .motorcycle }
            self?.startTracking(mode: .all, initialLots: motorLots)
        }
    }
    
    private func startTracking(mode: TrackingMode, initialLots: [ParkingLot]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("即時動態功能未啟用")
            return
        }
        
        stopCommuting() // 停止之前的會話
        
        self.trackingMode = mode
        self.isCommuting = true
        
        // Setup initial content
        let liteLots = initialLots.map {
            ParkingAttributes.LiteLot(name: $0.name, available: $0.availableCount, total: $0.totalCapacity)
        }
        
        let title: String
        switch mode {
        case .single(let name):
            title = name
            self.trackingDescription = "正在監控 \(name)"
        case .all:
            title = "全校車位概況"
            self.trackingDescription = "正在監控所有車位"
        }
        
        let attributes = ParkingAttributes(title: title)
        let contentState = ParkingAttributes.ContentState(
            lots: liteLots,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
            print("啟動即時動態: \(activity.id)")
        } catch {
            print("啟動即時動態失敗: \(error)")
        }
        
        // 2. 啟動背景定位 (保持 App 喚醒)
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // 3. 啟動計時器進行資料抓取
        startTimer()
    }
    
    func stopCommuting() {
        guard isCommuting else { return }
        
        // 結束即時動態
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
        
        // 停止定位與計時器
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        
        self.trackingMode = nil
        self.isCommuting = false
        self.trackingDescription = nil
        print("停止通勤模式")
    }
    
    private func startTimer() {
        // 在 main run loop 排程計時器
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchAndUpdate()
        }
    }
    
    private func fetchAndUpdate() {
        guard let mode = trackingMode else { return }
        print("正在抓取資料更新動態...")
        
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            guard let self = self else { return }
            
            var targetLots: [ParkingLot] = []
            
            switch mode {
            case .single(let name):
                if let lot = lots.first(where: { $0.name == name }) {
                    targetLots = [lot]
                }
            case .all:
                targetLots = lots.filter { $0.type == .motorcycle } // Assuming preference for motorcycle or we take all
            }
            
            if !targetLots.isEmpty {
                self.updateActivity(with: targetLots)
            }
        }
    }
    
    private func updateActivity(with lots: [ParkingLot]) {
        guard let activity = currentActivity else { return }
        
        let liteLots = lots.map {
            ParkingAttributes.LiteLot(name: $0.name, available: $0.availableCount, total: $0.totalCapacity)
        }
        
        let contentState = ParkingAttributes.ContentState(
            lots: liteLots,
            lastUpdated: Date()
        )
        
        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
            print("更新即時動態: \(liteLots.count) 筆資料")
        }
    }
}

extension CommuteManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 背景位置更新以保持 App 存活。
        // 我們不需要在此處理位置資料，
        // 但接收更新可確保系統知道我們仍處於活躍狀態。
        // print("收到保持喚醒位置更新")
    }
}
