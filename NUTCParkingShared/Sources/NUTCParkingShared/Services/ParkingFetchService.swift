import Foundation

public actor ParkingFetchService {
    public static let shared = ParkingFetchService()
    
    private let urlString = "https://apps.nutc.edu.tw/getParking/showParkingData.php"
    private let campusCenterLat = 24.149691
    private let campusCenterLon = 120.683974
    
    public func fetchParkingData() async throws -> [ParkingLotData] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return parseHTML(html)
    }
    
    private func parseHTML(_ html: String) -> [ParkingLotData] {
        return self.fullParseHTML(html)
    }
    
    private func fullParseHTML(_ html: String) -> [ParkingLotData] {
        let cleanHTML = html.replacingOccurrences(of: "[\\n\\r\\t]+", with: "", options: .regularExpression)
        
        var newLots: [ParkingLotData] = []
        
        newLots.append(contentsOf: parseSection(keyword: "汽車停車場", type: .car, html: cleanHTML))
        newLots.append(contentsOf: parseSection(keyword: "機車停車場", type: .motorcycle, html: cleanHTML))
        
        return newLots
    }

    private func parseSection(keyword: String, type: ParkingType, html: String) -> [ParkingLotData] {
        var sectionLots: [ParkingLotData] = []
        
        guard let range = html.range(of: keyword) else {
            return []
        }
        
        let contentAfterKeyword = String(html[range.upperBound...])
        
        let endRange = contentAfterKeyword.range(of: "<div class=\"partTitle\">")
            ?? contentAfterKeyword.range(of: "<h1>")
        
        let sectionContent: String
        if let end = endRange {
            sectionContent = String(contentAfterKeyword[..<end.lowerBound])
        } else {
            sectionContent = contentAfterKeyword
        }
        
        let tdPattern = "<(td|th)[^>]*class=\"([^\"]*)\"[^>]*>(.*?)</\\1>"
        
        do {
            let tdRegex = try NSRegularExpression(pattern: tdPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
            let nsString = sectionContent as NSString
            let matches = tdRegex.matches(in: sectionContent, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var currentName: String?
            var currentValues: [Int] = []
            
            for match in matches {
                let classString = nsString.substring(with: match.range(at: 2))
                let contentString = nsString.substring(with: match.range(at: 3))
                
                if classString.contains("partHead") {
                    if let name = currentName, !currentValues.isEmpty {
                        let available = currentValues.last ?? 0
                        let total = currentValues.first ?? 0
                        
                         if !name.isEmpty && name != "停車場" {
                            let lot = ParkingLotData(
                                name: name,
                                totalCapacity: total,
                                availableCount: available,
                                latitude: campusCenterLat,
                                longitude: campusCenterLon,
                                lastUpdated: Date(),
                                type: type
                            )
                            sectionLots.append(lot)
                         }
                    }
                    
                    currentName = cleanString(contentString)
                    currentValues = []
                    
                } else if (classString.contains("partAll") || classString.contains("partMotoAll")) {
                    if let val = cleanInt(contentString) {
                        currentValues.append(val)
                    }
                }
            }
            
            if let name = currentName, !currentValues.isEmpty {
                let available = currentValues.last ?? 0
                let total = currentValues.first ?? 0
                
                 if !name.isEmpty && name != "停車場" {
                    let lot = ParkingLotData(
                        name: name,
                        totalCapacity: total,
                        availableCount: available,
                        latitude: campusCenterLat,
                        longitude: campusCenterLon,
                        lastUpdated: Date(),
                        type: type
                    )
                    sectionLots.append(lot)
                 }
            }
            
        } catch {
            print("Regex error: \(error)")
        }
        
        return sectionLots
    }
    
    private func cleanString(_ input: String) -> String {
        var text = input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        text = text.replacingOccurrences(of: "\\(.*?\\)", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "（.*?）", with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func cleanInt(_ input: String) -> Int? {
        let cleaned = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return Int(cleaned)
    }
}
