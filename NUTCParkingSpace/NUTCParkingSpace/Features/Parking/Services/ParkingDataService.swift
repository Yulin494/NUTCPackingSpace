import Foundation
import CoreLocation
import Combine

class ParkingDataService: ObservableObject {
    static let shared = ParkingDataService()
    
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let urlString = "https://apps.nutc.edu.tw/getParking/showParkingData.php"
    
    // 根據規格說明，統一使用校園中心座標
    private let campusCenter = CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974)
    
    func fetchParkingData(completion: (([ParkingLot]) -> Void)? = nil) {
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60 // 增加逾時時間
        
        // 模擬完整的瀏覽器 Headers
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7", forHTTPHeaderField: "Accept")
        request.addValue("zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.addValue("max-age=0", forHTTPHeaderField: "Cache-Control")
        request.addValue("https://apps.nutc.edu.tw/", forHTTPHeaderField: "Referer")
        request.addValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.addValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.addValue("none", forHTTPHeaderField: "Sec-Fetch-Site")
        request.addValue("?1", forHTTPHeaderField: "Sec-Fetch-User")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("ParkingDataService 錯誤: \(error.localizedDescription)")
                    self?.errorMessage = "連線失敗: \(error.localizedDescription)"
                    completion?(self?.parkingLots ?? [])
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    // print("ParkingDataService Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        self?.errorMessage = "伺服器回應錯誤: \(httpResponse.statusCode)"
                        completion?(self?.parkingLots ?? [])
                        return
                    }
                }
                
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "無法讀取資料"
                    return
                }
                
                self?.parseHTML(html)
                completion?(self?.parkingLots ?? [])
            }
        }.resume()
    }
    
    private func parseHTML(_ html: String) {
        // 移除所有換行符號與 Tab，將 HTML 壓縮成一行，解決標籤屬性或關鍵字被斷行的問題
        let cleanHTML = html.replacingOccurrences(of: "[\\n\\r\\t]+", with: "", options: .regularExpression)
        
        var newLots: [ParkingLot] = []
        
        // 定義解析區塊的輔助函式
        func parseSection(keyword: String, type: ParkingType, html: String) -> [ParkingLot] {
            var sectionLots: [ParkingLot] = []
            
            // 1. 找到區塊標題 (例如 <h1>汽車停車場</h1>)
            // 使用 components 分割可能不夠精確，改用 Range 搜尋
            guard let range = html.range(of: keyword) else {
                return []
            }
            
            // 取得該關鍵字之後的字串
            let contentAfterKeyword = String(html[range.upperBound...])
            
            // 為了避免讀到下一個區塊，我們嘗試找到下一個 "<h1>" 或 "partTitle" 作為結束點
            // 如果找不到，就用到字串結尾
            let endRange = contentAfterKeyword.range(of: "<div class=\"partTitle\">") 
                ?? contentAfterKeyword.range(of: "<h1>")
            
            let sectionContent: String
            if let end = endRange {
                sectionContent = String(contentAfterKeyword[..<end.lowerBound])
            } else {
                sectionContent = contentAfterKeyword
            }
            
            // 2. 解析該區塊內的 td 或 th
            // 模式：<(td|th) class="partHead">名稱</(td|th)> ... <(td|th) class="partAll/partMotoAll" ...>數量</(td|th)>
            // 支援 td 與 th 標籤，並使用 "最後一個整數為剩餘車位" 的策略
            
            let tdPattern = "<(td|th)[^>]*class=\"([^\"]*)\"[^>]*>(.*?)</\\1>"
            
            do {
                let tdRegex = try NSRegularExpression(pattern: tdPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
                let nsString = sectionContent as NSString
                let matches = tdRegex.matches(in: sectionContent, options: [], range: NSRange(location: 0, length: nsString.length))
                
                var currentName: String?
                var currentValues: [Int] = []
                
                for match in matches {
                    // Group 1: tag (td/th) - ignored
                    // Group 2: class
                    // Group 3: content
                    let classString = nsString.substring(with: match.range(at: 2))
                    let contentString = nsString.substring(with: match.range(at: 3))
                    
                    if classString.contains("partHead") {
                        // 如果已經有正在處理的停車場，且有找到數值，則儲存它
                        if let name = currentName, let available = currentValues.last {
                            // 排除 "停車場" 這種標題列
                            if !name.isEmpty && name != "停車場" {
                                // 假設有兩個數值，第一個是總數；若只有一個，則總數=剩餘 (或設為0表示未知)
                                let total = currentValues.count >= 2 ? currentValues.first! : 0
                                
                                let lot = ParkingLot(
                                    name: name,
                                    totalCapacity: total,
                                    availableCount: available,
                                    coordinate: self.campusCenter,
                                    lastUpdated: Date(),
                                    type: type
                                )
                                sectionLots.append(lot)
                            }
                        }
                        
                        // 開始處理新的停車場
                        currentName = cleanString(contentString)
                        currentValues = [] // 重置數值
                        
                    } else if (classString.contains("partAll") || classString.contains("partMotoAll")) {
                        // 解析數值並加入列表
                        if let val = cleanInt(contentString) {
                            currentValues.append(val)
                        }
                    }
                }
                
                // 處理最後一個停車場
                if let name = currentName, let available = currentValues.last {
                    if !name.isEmpty && name != "停車場" {
                        let total = currentValues.count >= 2 ? currentValues.first! : 0
                        let lot = ParkingLot(
                            name: name,
                            totalCapacity: total,
                            availableCount: available,
                            coordinate: self.campusCenter,
                            lastUpdated: Date(),
                            type: type
                        )
                        sectionLots.append(lot)
                    }
                }
                
            } catch {
                print("Regex error in section \(keyword): \(error)")
            }
            
            return sectionLots
        }
        
        // 注意：網頁結構通常是先汽車，再機車，或者反過來。
        // 為了避免順序問題，我們搜尋整個 HTML
        
        // Parse Car (汽車) - 關鍵字用 "汽車停車場"
        newLots.append(contentsOf: parseSection(keyword: "汽車停車場", type: .car, html: cleanHTML))
        
        // Parse Motorcycle (機車) - 關鍵字用 "機車停車場"
        newLots.append(contentsOf: parseSection(keyword: "機車停車場", type: .motorcycle, html: cleanHTML))
        
        self.parkingLots = newLots
        
        if newLots.isEmpty {
            self.errorMessage = "解析後無資料 (格式可能已變更)"
        }
    }
    
    private func cleanString(_ input: String) -> String {
        // 1. 移除 HTML 標籤
        var text = input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        
        // 2. 移除括弧內容 (例如 "(開放訪客)")
        text = text.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression, range: nil)
        text = text.replacingOccurrences(of: "（.*?）", with: "", options: .regularExpression, range: nil)
        
        // 3. 去除前後空白
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanInt(_ input: String) -> Int? {
        let cleaned = cleanString(input)
        return Int(cleaned)
    }
}
