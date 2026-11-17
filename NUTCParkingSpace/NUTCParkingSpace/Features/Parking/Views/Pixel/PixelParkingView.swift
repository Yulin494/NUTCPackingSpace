//
//  PixelParkingView.swift
//  NUTCParkingSpace
//
//  像素版停車頁：上半像素地圖（停車鏡頭），下半摘要 + 分組列表 + 門檻說明。
//  資料來源沿用 ParkingListViewModel（由 ParkingListView 傳入），不另抓資料。
//

import SwiftUI

/// 包裝層：接 ViewModel 與通勤管理，處理生命週期與下拉重新整理。
struct PixelParkingView: View {
    @ObservedObject var viewModel: ParkingListViewModel
    @ObservedObject private var commuteManager = CommuteManager.shared

    var body: some View {
        NavigationStack {
            PixelParkingContent(
                lots: viewModel.parkingLots,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                isCommuting: commuteManager.isCommuting,
                trackingDescription: commuteManager.trackingDescription,
                onRetry: { viewModel.fetchParkingData() },
                onRefresh: {
                    // 與標準版相同：callback 轉 async，完成後依結果給觸覺回饋
                    await withCheckedContinuation { continuation in
                        viewModel.fetchParkingData { continuation.resume() }
                    }
                    if viewModel.errorMessage == nil {
                        HapticManager.shared.notification(type: .success)
                    } else {
                        HapticManager.shared.notification(type: .error)
                    }
                },
                onToggleTracking: {
                    HapticManager.shared.impact(style: .medium)
                    if commuteManager.isCommuting {
                        commuteManager.stopCommuting()
                    } else {
                        commuteManager.startTrackingAll()
                    }
                },
                trackedNames: Set(commuteManager.trackedLotNames),
                onToggleLotTracking: { commuteManager.toggleTracking(for: $0) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.startAutoRefresh()
                LocationService.shared.requestPermissions()
            }
            .onDisappear { viewModel.stopAutoRefresh() }
        }
    }
}

/// 內容層：純資料 + 回呼，方便 Preview 帶假資料。
struct PixelParkingContent: View {
    let lots: [ParkingLot]
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isCommuting: Bool = false
    var trackingDescription: String? = nil
    var onRetry: () -> Void = {}
    var onRefresh: () async -> Void = {}
    var onToggleTracking: () -> Void = {}
    var trackedNames: Set<String> = []
    var onToggleLotTracking: (ParkingLot) -> Void = { _ in }

    @State private var selectedID: UUID?

    private var updatedText: String? {
        guard let latest = lots.map(\.lastUpdated).max() else { return nil }
        return latest.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_Hant_TW")))
    }

    private var motorcycleTotal: Int {
        lots.filter { $0.type == .motorcycle }.reduce(0) { $0 + $1.availableCount }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    if isCommuting { trackingPanel }
                    PixelCampusMapView(camera: .parking, lots: lots, weather: .clear) { lot in
                        // 點地圖標記：選取並跳到下方對應列（無動畫，離散跳轉）
                        selectedID = lot.id
                        proxy.scrollTo(lot.id, anchor: .center)
                    }
                    .overlay(Rectangle().stroke(PixelPalette.ink, lineWidth: PixelMetrics.border))
                    content
                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .refreshable { await onRefresh() }
        }
        .background(PixelPalette.paper2.ignoresSafeArea())
    }

    // MARK: 頂部

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                NamePlate(text: "停車地圖", fontSize: PixelMetrics.FontSize.medium)
                if let updatedText {
                    Text("更新時間 \(updatedText)")
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                }
            }
            Spacer(minLength: 8)
            // 追蹤全部：對應標準版 toolbar 的眼睛按鈕
            Button(action: onToggleTracking) {
                Text(isCommuting ? "停止追蹤" : "追蹤全部")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.ink)
                    .frame(minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: isCommuting ? PixelPalette.gold : PixelPalette.paper))
            .accessibilityLabel(isCommuting ? "停止追蹤" : "追蹤全部停車場")
        }
    }

    private var trackingPanel: some View {
        HStack(spacing: 8) {
            NamePlate(text: "追蹤中", fill: PixelPalette.gold, textColor: PixelPalette.ink)
            Text(trackingDescription ?? "正在追蹤車位")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.ink)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
    }

    // MARK: 主體（載入 / 錯誤 / 列表）

    @ViewBuilder
    private var content: some View {
        if isLoading && lots.isEmpty {
            PixelLoadingPanel()
        } else if let errorMessage, lots.isEmpty {
            errorPanel(errorMessage)
        } else {
            summary
            ForEach(ParkingType.allCases, id: \.self) { type in
                let group = lots.filter { $0.type == type }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        NamePlate(text: type.rawValue)
                        ForEach(group) { lot in
                            PixelParkingRow(
                                lot: lot,
                                isSelected: selectedID == lot.id,
                                onTap: { selectedID = (selectedID == lot.id) ? nil : lot.id },
                                isTracked: trackedNames.contains(lot.name),
                                onToggleTracking: { onToggleLotTracking(lot) }
                            )
                            .id(lot.id)
                        }
                    }
                }
            }
        }
    }

    private var summary: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("機車總計剩")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PixelPalette.ink)
            Text("\(motorcycleTotal)")
                .pixelFont(size: PixelMetrics.FontSize.large)
                .foregroundStyle(PixelPalette.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("機車總計剩 \(motorcycleTotal) 個車位")
    }

    private func errorPanel(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            NamePlate(text: "連線失敗", fill: PixelPalette.red, textColor: PixelPalette.paper)
            Text("暫時無法取得最新車位資訊，請稍後再試或檢查網路連線。")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.ink)
            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 15))
                    .foregroundStyle(PixelPalette.muted)
            }
            Button(action: onRetry) {
                Text("重試")
                    .pixelFont(size: PixelMetrics.FontSize.small)
                    .foregroundStyle(PixelPalette.ink)
                    .frame(minWidth: 44, minHeight: 28)
            }
            .buttonStyle(PixelButtonStyle(fill: PixelPalette.gold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.paper)
    }

    // MARK: 底部說明

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 門檻與 PixelStatus.forLot 一致（同標準模式的比例制）
            Text("剩餘過半充足，兩成以上緊張，兩成以下快滿，0 滿位")
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.ink)
            if !lots.isEmpty {
                Text("點列可展開，長按停車場可開始通勤即時追蹤")
                    .font(.system(size: 15))
                    .foregroundStyle(PixelPalette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 載入中：方塊離散閃爍（0.5 秒一步）；減少動態時靜止。
private struct PixelLoadingPanel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let step = reduceMotion ? 0 : Int(context.date.timeIntervalSinceReferenceDate / 0.5) % 4
            VStack(alignment: .leading, spacing: 10) {
                NamePlate(text: "載入中")
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle()
                            .fill(i == step ? PixelPalette.gold : PixelPalette.tan)
                            .frame(width: 16, height: 16)
                            .overlay(Rectangle().stroke(PixelPalette.ink, lineWidth: PixelMetrics.border))
                    }
                }
                Text("正在取得車位資料")
                    .font(.system(size: 15))
                    .foregroundStyle(PixelPalette.ink)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: PixelPalette.paper)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("載入中")
    }
}

#if DEBUG
#Preview("像素停車頁") {
    PixelParkingContent(lots: PixelMapSampleData.lots)
}

#Preview("像素停車頁 載入中") {
    PixelParkingContent(lots: [], isLoading: true)
}

#Preview("像素停車頁 錯誤") {
    PixelParkingContent(lots: [], errorMessage: "網路連線中斷")
}
#endif
