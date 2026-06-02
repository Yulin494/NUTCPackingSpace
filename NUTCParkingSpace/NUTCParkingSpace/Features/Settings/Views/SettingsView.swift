import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    // 用於控制是否顯示初始引導頁面
    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false
    // 用於控制是否開啟 1 公里範圍自動通知
    @AppStorage("isMonitoringEnabled") var isMonitoringEnabled: Bool = true

    // Optional binding for sheet presentation mode
    var isPresented: Binding<Bool>?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("一般設定")) {
                    Toggle("一公里自動通知", isOn: $isMonitoringEnabled)
                        .onChange(of: isMonitoringEnabled) { newValue in
                            LocationService.shared.updateMonitoring(enabled: newValue)
                        }

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
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
