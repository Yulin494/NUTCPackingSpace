//
//  PixelMapGalleryView.swift
//  NUTCParkingSpace
//
//  DEBUG 專用：兩種鏡頭上下排的地圖檢視，供實機／模擬器截圖驗收。
//  啟動參數 `-PixelMapGallery YES` 時由 NUTCParkingSpaceApp 取代根畫面。
//

#if DEBUG
import SwiftUI

struct PixelMapGalleryView: View {
    @State private var selectedName = "（未選取）"

    /// 教室字串比對檢查：（輸入，預期建築名稱或 nil）
    private static let matchCases: [(String, String?)] = [
        ("中正大樓 702", "中科大樓"),
        ("中科大樓 702", "中科大樓"),
        ("中正 702", "中科大樓"),
        ("資訊大樓 405", "資訊館"),
        ("資訊館 405", "資訊館"),
        ("體育館", "體育館"),
        ("翰英樓 301", "翰英樓"),
        ("弘業樓 201", "弘業樓"),
        ("線上課程", nil),
    ]

    private var matchReport: String {
        Self.matchCases.map { input, expected in
            let got = CampusBuilding.match(location: input)?.name
            return "\(got == expected ? "OK" : "NG") \(input) -> \(got ?? "nil")"
        }.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("campus 鏡頭（晴・雲）")
                PixelCampusMapView(camera: .campus,
                                   lots: PixelMapSampleData.lots,
                                   highlightBuilding: CampusBuilding.match(location: "中科大樓 702"),
                                   highlightText: "28 分",
                                   weather: .cloudy,
                                   onSelectLot: { selectedName = $0.name })
                Text("parking 鏡頭（晴天）")
                PixelCampusMapView(camera: .parking,
                                   lots: PixelMapSampleData.lots,
                                   weather: .clear,
                                   onSelectLot: { selectedName = $0.name })
                Text("點選：\(selectedName)")
                Text(matchReport)
                    .font(.system(size: 11, design: .monospaced))
            }
            .pixelFont(size: PixelMetrics.FontSize.small)
            .foregroundStyle(PixelPalette.ink)
            .padding(.vertical, 8)
        }
        .background(PixelPalette.paper2)
    }
}

#Preview {
    PixelMapGalleryView()
}
#endif
