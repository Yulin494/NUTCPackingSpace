import Foundation
import CoreLocation
import UserNotifications
import UIKit

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let campusCenter = CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974)
    private let regionRadius: CLLocationDistance = 1000.0
    private let regionIdentifier = "CampusCenterRegion"
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private var lastNotificationTime: Date?
    private let coolDownInterval: TimeInterval = 600 // 10 分鐘冷卻時間
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // 啟用背景位置更新
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        authorizationStatus = locationManager.authorizationStatus
        UNUserNotificationCenter.current().delegate = self
        
        // 註冊預設設定值：預設開啟監控
        UserDefaults.standard.register(defaults: ["isMonitoringEnabled": true])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
        
        // 同時請求通知權限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知權限錯誤: \(error)")
            }
        }
    }
    
    // 開始監測校園中心範圍
    func startMonitoring() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        
        let region = CLCircularRegion(center: campusCenter, radius: regionRadius, identifier: regionIdentifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
    }
    
    // 停止監測
    func stopMonitoring() {
        for region in locationManager.monitoredRegions {
            if region.identifier == regionIdentifier {
                locationManager.stopMonitoring(for: region)
            }
        }
    }
    
    // 根據設定開啟或關閉監測
    func updateMonitoring(enabled: Bool) {
        if enabled {
            requestPermissions() // 開啟時確保有權限
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                startMonitoring()
            }
        } else {
            stopMonitoring()
        }
    }
    
    // 當位置權限改變時觸發
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        // 檢查使用者設定是否開啟監控 (從 UserDefaults 讀取)
        let isEnabled = UserDefaults.standard.bool(forKey: "isMonitoringEnabled")
        
        // 只有在設定開啟且獲得授權時才開始監測
        if isEnabled && (manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse) {
            startMonitoring()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == regionIdentifier {
            checkAndNotify()
        }
    }
    
    private func checkAndNotify() {
        // 檢查冷卻時間
        if let lastTime = lastNotificationTime, Date().timeIntervalSince(lastTime) < coolDownInterval {
            return
        }
        
        // 請求背景執行時間以確保資料抓取完成
        var bgTaskID: UIBackgroundTaskIdentifier = .invalid
        bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "FetchParkingData") {
            // 如果時間耗盡則結束任務
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
        
        // 抓取資料
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            self?.sendNotification(lots: lots)
            
            // 完成後結束任務
            if bgTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskID)
                bgTaskID = .invalid
            }
        }
    }
    
    private func sendNotification(lots: [ParkingLot]) {
        let content = UNMutableNotificationContent()
        content.title = "附近機車停車位資訊"
        
        // 只過濾機車停車場
        let availableLots = lots.filter { $0.type == .motorcycle && $0.availableCount > 0 }
        
        if availableLots.isEmpty {
            content.body = "目前所有機車停車場皆已滿位。"
        } else {
            let summary = availableLots.prefix(4).map { "\($0.name): \($0.availableCount)" }.joined(separator: ", ")
            content.body = summary
        }
        
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        
        lastNotificationTime = Date()
    }
}
