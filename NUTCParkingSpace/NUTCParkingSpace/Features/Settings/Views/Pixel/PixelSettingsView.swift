//
//  PixelSettingsView.swift
//  NUTCParkingSpace
//
//  像素模式設定頁：自繪區塊（名牌標題 + 缺角框），不使用系統 Form 外觀。
//  設定鍵與副作用（定位監控、課程／作業通知重排）與 SettingsView 完全一致。
//

import SwiftUI
import SwiftData
import NUTCParkingShared

// MARK: - 像素開關

/// 像素開關：2pt 框、方塊滑塊、ON/OFF 文字；點擊時輕觸覺，無動畫（離散切換）。
struct PixelToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .font(.system(size: 17))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                switchBody(isOn: configuration.isOn)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(trigger: configuration.isOn) { _, _ in .impact(weight: .light) }
        .accessibilityValue(configuration.isOn ? "開" : "關")
        .accessibilityAddTraits(.isButton)
    }

    /// 開關本體：左右兩格，滑塊所在位置 + 文字同時表示狀態
    private func switchBody(isOn: Bool) -> some View {
        let d = PixelMetrics.shadowOffset
        return HStack(spacing: 0) {
            if isOn {
                Text("ON").pixelFont(size: PixelMetrics.FontSize.small)
                    .frame(maxWidth: .infinity)
                Rectangle().fill(PixelPalette.ink).frame(width: 20, height: 20)
            } else {
                Rectangle().fill(PixelPalette.ink).frame(width: 20, height: 20)
                Text("OFF").pixelFont(size: PixelMetrics.FontSize.small)
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(PixelPalette.ink)
        .padding(4)
        .frame(width: 76, height: 32)
        .pixelFrame(fill: isOn ? PixelPalette.gold : PixelPalette.paper)
        .background(PixelFrameShape().fill(PixelPalette.ink).offset(x: d, y: d))
        .padding(.trailing, d)
        .padding(.bottom, d)
    }
}

// MARK: - 像素分段

/// 像素分段選擇：選中者金底、粗框並帶勾選圖示（不只靠顏色）
private struct PixelSegmented<Value: Hashable>: View {
    let options: [(value: Value, title: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let selected = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    HStack(spacing: 4) {
                        if selected {
                            PixelIcon(kind: .check, scale: 1)
                        }
                        Text(option.title).pixelFont(size: PixelMetrics.FontSize.small)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(PixelButtonStyle(
                    fill: selected ? PixelPalette.gold : PixelPalette.paper,
                    contentPadding: EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .foregroundStyle(PixelPalette.ink)
    }
}

// MARK: - 設定頁

struct PixelSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HomeworkItem.dueDate) private var homeworks: [HomeworkItem]

    @AppStorage("appearanceStyle")              private var appearanceStyle: AppearanceStyle = .standard
    @AppStorage("hasShownOnboarding")           private var hasShownOnboarding: Bool = false
    @AppStorage("isMonitoringEnabled")          private var isMonitoringEnabled: Bool = true
    @AppStorage("courseNotificationsEnabled")   private var courseNotificationsEnabled: Bool = true
    @AppStorage("notifyMinutesBefore")          private var notifyMinutesBefore: Int = 15
    @AppStorage("homeworkNotificationsEnabled") private var homeworkNotificationsEnabled: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    // 外觀
                    block("外觀") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("風格").font(.system(size: 17))
                            PixelSegmented(
                                options: AppearanceStyle.allCases.map { ($0, $0.title) },
                                selection: $appearanceStyle)
                        }
                    }

                    // 停車通知
                    block("停車通知") {
                        Toggle("接近校園自動通知", isOn: $isMonitoringEnabled)
                            .toggleStyle(PixelToggleStyle())
                            .onChange(of: isMonitoringEnabled) { newValue in
                                LocationService.shared.updateMonitoring(enabled: newValue)
                            }
                    }

                    // 課程通知
                    block("課程通知") {
                        Toggle("上課前提醒", isOn: $courseNotificationsEnabled)
                            .toggleStyle(PixelToggleStyle())
                            .onChange(of: courseNotificationsEnabled) { _ in rescheduleAll() }

                        if courseNotificationsEnabled {
                            divider
                            VStack(alignment: .leading, spacing: 10) {
                                Text("提前提醒（分鐘）").font(.system(size: 17))
                                PixelSegmented(
                                    options: [(10, "10 分"), (15, "15 分"), (20, "20 分"), (30, "30 分")],
                                    selection: $notifyMinutesBefore)
                            }
                            .onChange(of: notifyMinutesBefore) { _ in rescheduleAll() }
                        }
                    }

                    // 作業通知
                    block("作業通知") {
                        Toggle("截止前一天提醒", isOn: $homeworkNotificationsEnabled)
                            .toggleStyle(PixelToggleStyle())
                            .onChange(of: homeworkNotificationsEnabled) { _ in rescheduleHomework() }
                    }

                    // 一般
                    block("一般") {
                        Button {
                            hasShownOnboarding = false
                            dismiss()
                        } label: {
                            HStack {
                                Text("重新顯示教學").font(.system(size: 17))
                                Spacer(minLength: 8)
                                PixelIcon(kind: .triangle, scale: 2)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // 關於
                    block("關於") {
                        HStack {
                            Text("版本").font(.system(size: 17))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .pixelFont(size: PixelMetrics.FontSize.small)
                        }
                        .frame(minHeight: 44)
                        divider
                        NavigationLink {
                            FontLicenseView()
                        } label: {
                            HStack {
                                Text("開放原始碼授權").font(.system(size: 17))
                                Spacer(minLength: 8)
                                Text(">").pixelFont(size: PixelMetrics.FontSize.medium)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .foregroundStyle(PixelPalette.ink)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(PixelPalette.paper2.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: 版面元件

    private var header: some View {
        HStack(spacing: 12) {
            NamePlate(text: "設定", fontSize: PixelMetrics.FontSize.medium)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.grass)
    }

    /// 區塊：名牌標題 + 缺角框內容
    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NamePlate(text: title)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: PixelPalette.paper)
        }
    }

    private var divider: some View {
        Rectangle().fill(PixelPalette.tan).frame(height: 2)
    }

    // MARK: 通知重排（與 SettingsView 相同）

    private func rescheduleAll() {
        let courses = SharedScheduleCache.load()
        Task { await ScheduleNotificationService.shared.reschedule(courses: courses) }
    }

    private func rescheduleHomework() {
        let snapshot = homeworks.map {
            HomeworkReminder(title: $0.title, courseName: $0.courseName,
                             dueDate: $0.dueDate, isCompleted: $0.isCompleted)
        }
        Task { await HomeworkNotificationService.shared.reschedule(homeworks: snapshot) }
    }
}

#Preview {
    PixelSettingsView()
        .modelContainer(for: HomeworkItem.self, inMemory: true)
        .environment(\.appearanceStyle, .pixel)
}
