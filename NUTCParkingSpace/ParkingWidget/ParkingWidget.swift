import WidgetKit
import SwiftUI
import AppIntents
import CoreLocation

// MARK: - 時間軸項目 (Timeline Entry)
struct ParkingEntry: TimelineEntry {
    let date: Date
    let parkingLots: [ParkingLot]
    let error: String?
}

// MARK: - 時間軸提供者 (Timeline Provider)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ParkingEntry {
        ParkingEntry(date: Date(), parkingLots: placeholderLots(), error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ParkingEntry) -> ()) {
        let entry = ParkingEntry(date: Date(), parkingLots: placeholderLots(), error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkingEntry>) -> ()) {
        // 抓取即時資料
        ParkingDataService.shared.fetchParkingData { lots in
            let currentDate = Date()
            
            // 邏輯處理：只顯示機車停車場 (.motorcycle) 並依剩餘車位排序 (由多到少)
            let filteredLots = lots
                .filter { $0.type == .motorcycle }
                .sorted { $0.availableCount > $1.availableCount }
            
            // 建立 Entry
            // 如果 fetch 失敗 (lots 為空且 Service 有錯誤訊息)，可以傳遞 error
            // 這裡簡單處理：如果有資料就顯示，沒資料看是否是錯誤
            let errorMsg = filteredLots.isEmpty ? ParkingDataService.shared.errorMessage : nil
            
            let entry = ParkingEntry(
                date: currentDate,
                parkingLots: filteredLots,
                error: errorMsg
            )
            
            // 設定更新策略：現在起 15 分鐘後再次更新
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            
            completion(timeline)
        }
    }
    
    // 預覽用的假資料
    private func placeholderLots() -> [ParkingLot] {
        return [
            ParkingLot(name: "中技 B3", totalCapacity: 200, availableCount: 120, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "中商 B2", totalCapacity: 300, availableCount: 45, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "民生校區", totalCapacity: 100, availableCount: 0, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "操場地下", totalCapacity: 150, availableCount: 88, coordinate: .init(), lastUpdated: Date(), type: .motorcycle)
        ]
    }
}

// MARK: - 小工具視圖 (Widget View)
struct ParkingWidgetEntryView: View {
    var entry: Provider.Entry
    
    // 從 View 中取得 Widget 的環境變數 (如尺寸)
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header (極簡化，只佔用最少空間)
                HStack {
                    Label("機車車位", systemImage: "motorcycle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button(intent: RefreshIntent()) {
                        HStack(spacing: 2) {
                            Text(entry.date, style: .time)
                                .font(.system(size: 8))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                                .padding(3)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)
                
                if let error = entry.error, entry.parkingLots.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(error).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.gray)
                } else {
                    // 使用 VStack/HStack 進行手動網格佈局，以完美填滿垂直空間
                    let displayLots = Array(entry.parkingLots.prefix(4))
                    // 分割成上下兩列
                    let topRow = Array(displayLots.prefix(2))
                    let bottomRow = Array(displayLots.dropFirst(2).prefix(2))
                    
                    VStack(spacing: 6) {
                        // 上排
                        HStack(spacing: 6) {
                            ForEach(topRow) { lot in
                                ParkingCell(lot: lot)
                            }
                            // 如果只有一個，補一個 Spacer 讓它靠左 (雖然這裡應該都是偶數)
                            if topRow.count == 1 { Spacer() }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // 下排
                        HStack(spacing: 6) {
                            ForEach(bottomRow) { lot in
                                ParkingCell(lot: lot)
                            }
                            if bottomRow.count == 1 { Spacer() }
                            // 如果下面沒資料，補 Spacer 佔位
                            if bottomRow.isEmpty { Spacer(); Spacer() }
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// 抽離出 Cell 元件以保持程式碼整潔
struct ParkingCell: View {
    let lot: ParkingLot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lot.name)
                .font(.system(size: 10))
                .fontWeight(.bold)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 0)
            
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text("\(lot.availableCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(lot.availableCount > 0 ? .green : .red)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: Double(lot.availableCount)))
                
                Text("位")
                    .font(.system(size: 9))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 小工具設定 (Widget Configuration)
struct ParkingWidget: Widget {
    let kind: String = "ParkingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ParkingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("機車車位快看")
        .description("顯示目前校內機車停車場的剩餘數量。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 預覽 (Preview)
#Preview(as: .systemSmall) {
    ParkingWidget()
} timeline: {
    ParkingEntry(
        date: Date(),
        parkingLots: [
            ParkingLot(name: "中技 B3", totalCapacity: 200, availableCount: 50, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "中商 B2", totalCapacity: 300, availableCount: 5, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "民生校區", totalCapacity: 100, availableCount: 0, coordinate: .init(), lastUpdated: Date(), type: .motorcycle),
            ParkingLot(name: "操場地下", totalCapacity: 150, availableCount: 88, coordinate: .init(), lastUpdated: Date(), type: .motorcycle)
        ],
        error: nil
    )
    
    ParkingEntry(date: Date(), parkingLots: [], error: "無法連線")
}
