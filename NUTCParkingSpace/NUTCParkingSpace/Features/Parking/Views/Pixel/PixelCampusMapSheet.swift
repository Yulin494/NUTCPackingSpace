//
//  PixelCampusMapSheet.swift
//  NUTCParkingSpace
//
//  像素模式三民校區配置圖：像素導覽列 + 2pt 墨框；圖片與縮放（ZoomableImage）沿用不改。
//

import SwiftUI

struct PixelCampusMapSheet: View {
    let dismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZoomableImage(imageName: "CampusMap")
                .padding(PixelMetrics.border)
                .background(PixelPalette.ink)
                .padding(12)
                .pixelInfoPage(title: "三民校區配置圖")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: dismiss) {
                            Text("關閉")
                                .pixelFont(size: PixelMetrics.FontSize.small)
                                .foregroundStyle(PixelPalette.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("關閉")
                    }
                }
        }
    }
}
