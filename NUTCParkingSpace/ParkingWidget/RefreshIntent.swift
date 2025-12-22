import AppIntents
import WidgetKit
import Foundation

struct RefreshIntent: AppIntent {
    // Intent 的標題，顯示在系統介面或捷徑中
    static var title: LocalizedStringResource = "重新整理停車資訊"
    
    // 描述這個 Intent 的作用
    static var description: IntentDescription = IntentDescription("強制刷新 Parking Widget 的資料")

    // 不需要參數，因為只是單純的刷新動作
    
    init() {}

    func perform() async throws -> some IntentResult {
        // 使用 WidgetCenter 重新載入所有 Widget 的 Timeline
        // 這會觸發 TimelineProvider 的 getTimeline 方法
        WidgetCenter.shared.reloadAllTimelines()
        
        // 回傳執行結果
        return .result()
    }
}
