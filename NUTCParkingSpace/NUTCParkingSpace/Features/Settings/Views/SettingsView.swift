import SwiftUI
import NUTCParkingShared

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("hasShownOnboarding")         var hasShownOnboarding: Bool = false
    @AppStorage("isMonitoringEnabled")         var isMonitoringEnabled: Bool = true
    @AppStorage("courseNotificationsEnabled")  var courseNotificationsEnabled: Bool = true
    @AppStorage("notifyMinutesBefore")         var notifyMinutesBefore: Int = 15
    @AppStorage("homeworkNotificationsEnabled") var homeworkNotificationsEnabled: Bool = true

    var isPresented: Binding<Bool>?

    var body: some View {
        NavigationView {
            List {
                // MARK: 停車通知
                Section(header: Text("停車通知")) {
                    Toggle("接近校園自動通知", isOn: $isMonitoringEnabled)
                        .onChange(of: isMonitoringEnabled) { newValue in
                            LocationService.shared.updateMonitoring(enabled: newValue)
                        }
                }

                // MARK: 課程通知
                Section(header: Text("課程通知")) {
                    Toggle("上課前提醒", isOn: $courseNotificationsEnabled)
                        .onChange(of: courseNotificationsEnabled) { _ in rescheduleAll() }

                    if courseNotificationsEnabled {
                        Picker("提前提醒", selection: $notifyMinutesBefore) {
                            Text("10 分鐘").tag(10)
                            Text("15 分鐘").tag(15)
                            Text("20 分鐘").tag(20)
                            Text("30 分鐘").tag(30)
                        }
                        .onChange(of: notifyMinutesBefore) { _ in rescheduleAll() }
                    }
                }

                // MARK: 作業通知
                Section(header: Text("作業通知")) {
                    Toggle("截止前一天提醒", isOn: $homeworkNotificationsEnabled)
                }

                // MARK: 一般
                Section(header: Text("一般")) {
                    Button(action: {
                        hasShownOnboarding = false
                        dismiss()
                    }) {
                        HStack {
                            Text("重新顯示教學")
                            Spacer()
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    .foregroundColor(.primary)
                }

                // MARK: 關於
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }

    private func rescheduleAll() {
        let courses = SharedScheduleCache.load()
        Task { await ScheduleNotificationService.shared.reschedule(courses: courses) }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
