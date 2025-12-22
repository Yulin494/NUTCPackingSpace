import Foundation
import CoreLocation

class ParkingDataService: ObservableObject {
    static let shared = ParkingDataService()
    
    @Published var parkingLots: [ParkingLot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let urlString = "https://apps.nutc.edu.tw/getParking/showParkingData.php"
    
    // Using the campus center for all lots as per spec clarification
    private let campusCenter = CLLocationCoordinate2D(latitude: 24.149691, longitude: 120.683974)
    
    func fetchParkingData(completion: (([ParkingLot]) -> Void)? = nil) {
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "連線失敗: \(error.localizedDescription)"
                    return
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
        var newLots: [ParkingLot] = []
        
        // 1. Split by "機車停車場" to get the second part
        let parts = html.components(separatedBy: "機車停車場")
        guard parts.count > 1 else {
            // If "機車停車場" is not found, it might be a different format or error page
            // Try to parse anyway if it's the only table, but safer to check.
            // The web page has "汽車停車場" first, then "機車停車場".
            self.errorMessage = "找不到機車停車場資料"
            return
        }
        
        let motorcycleSection = parts[1]
        
        // 2. Find rows <tr>
        let rowPattern = "<tr>(.*?)</tr>"
        let colPattern = "<td>(.*?)</td>"
        
        do {
            let rowRegex = try NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators])
            let colRegex = try NSRegularExpression(pattern: colPattern, options: [.dotMatchesLineSeparators])
            
            let nsString = motorcycleSection as NSString
            let matches = rowRegex.matches(in: motorcycleSection, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                let rowContent = nsString.substring(with: match.range(at: 1))
                
                // Extract columns
                let colMatches = colRegex.matches(in: rowContent, options: [], range: NSRange(location: 0, length: (rowContent as NSString).length))
                
                if colMatches.count >= 2 {
                    let name = (rowContent as NSString).substring(with: colMatches[0].range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    let countString = (rowContent as NSString).substring(with: colMatches[1].range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Filter out header row
                    if name.contains("停車場") { continue }
                    
                    if let count = Int(countString) {
                        let lot = ParkingLot(
                            name: name,
                            availableCount: count,
                            coordinate: self.campusCenter,
                            lastUpdated: Date()
                        )
                        newLots.append(lot)
                    }
                }
            }
            
            self.parkingLots = newLots
            
        } catch {
            self.errorMessage = "解析資料失敗: \(error.localizedDescription)"
        }
    }
}
