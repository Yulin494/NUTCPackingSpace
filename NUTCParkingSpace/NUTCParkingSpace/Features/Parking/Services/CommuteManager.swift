import Foundation
import ActivityKit
import CoreLocation
import Combine

class CommuteManager: NSObject, ObservableObject {
    static let shared = CommuteManager()
    
    @Published var isCommuting = false
    @Published var currentLot: ParkingLot?
    
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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("即時動態功能未啟用")
            return
        }
        
        stopCommuting() // 停止之前的會話
        
        self.currentLot = lot
        self.isCommuting = true
        
        // 1. 啟動即時動態 (Live Activity)
        let attributes = ParkingAttributes(parkingName: lot.name)
        let contentState = ParkingAttributes.ContentState(
            availableCount: lot.availableCount,
            totalCapacity: lot.totalCapacity,
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
        
        // 立即抓取一次
        fetchAndUpdate()
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
        
        self.currentLot = nil
        self.isCommuting = false
        print("停止通勤模式")
    }
    
    private func startTimer() {
        // 在 main run loop 排程計時器
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchAndUpdate()
        }
    }
    
    private func fetchAndUpdate() {
        guard let lotName = currentLot?.name else { return }
        print("正在抓取資料: \(lotName)...")
        
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            guard let self = self else { return }
            
            if let updatedLot = lots.first(where: { $0.name == lotName }) {
                self.currentLot = updatedLot
                self.updateActivity(with: updatedLot)
            }
        }
    }
    
    private func updateActivity(with lot: ParkingLot) {
        guard let activity = currentActivity else { return }
        
        let contentState = ParkingAttributes.ContentState(
            availableCount: lot.availableCount,
            totalCapacity: lot.totalCapacity,
            lastUpdated: Date()
        )
        
        Task {
            await activity.update(
                ActivityContent(state: contentState, staleDate: nil)
            )
            print("更新即時動態數量: \(lot.availableCount)")
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
