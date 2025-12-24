import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 用於控制是否顯示初始引導頁面
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    // 用於控制是否開啟 1 公里範圍自動通知
    @AppStorage("isMonitoringEnabled") var isMonitoringEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("一般設定")) {
                    // 切換開關：開啟或關閉 1 公里自動通知
                    Toggle("一公里自動通知", isOn: $isMonitoringEnabled)
                        .onChange(of: isMonitoringEnabled) { newValue in
                            // 當開關改變時，呼叫 LocationService 更新監控狀態
                            LocationService.shared.updateMonitoring(enabled: newValue)
                        }
                    
                    // 按鈕：重設引導頁面狀態，並關閉設定頁面以顯示引導
                    Button(action: {
                        hasShownOnboarding = false
                        dismiss()
                    }) {
                        HStack {
                            Text("顯示初始教學")
                            Spacer()
                            Image(systemName: "questionmark.circle")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
