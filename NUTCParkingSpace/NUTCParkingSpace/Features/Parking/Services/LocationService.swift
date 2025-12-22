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
    private let coolDownInterval: TimeInterval = 600 // 10 minutes
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // Enable background location updates
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        authorizationStatus = locationManager.authorizationStatus
        UNUserNotificationCenter.current().delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
        
        // Also request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startMonitoring() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        
        let region = CLCircularRegion(center: campusCenter, radius: regionRadius, identifier: regionIdentifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            startMonitoring()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == regionIdentifier {
            checkAndNotify()
        }
    }
    
    private func checkAndNotify() {
        // Check cool-down
        if let lastTime = lastNotificationTime, Date().timeIntervalSince(lastTime) < coolDownInterval {
            return
        }
        
        // Request background execution time to ensure data fetch completes
        var bgTaskID: UIBackgroundTaskIdentifier = .invalid
        bgTaskID = UIApplication.shared.beginBackgroundTask(withName: "FetchParkingData") {
            // End the task if time expires
            UIApplication.shared.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        }
        
        // Fetch data
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            self?.sendNotification(lots: lots)
            
            // End the task when done
            if bgTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskID)
                bgTaskID = .invalid
            }
        }
    }
    
    func testNotification() {
        ParkingDataService.shared.fetchParkingData { [weak self] lots in
            self?.sendNotification(lots: lots)
        }
    }
    
    private func sendNotification(lots: [ParkingLot]) {
        let content = UNMutableNotificationContent()
        content.title = "附近機車停車位資訊"
        
        // Filter for motorcycle lots only
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
