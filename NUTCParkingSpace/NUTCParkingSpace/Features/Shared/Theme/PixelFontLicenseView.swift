//
//  PixelFontLicenseView.swift
//  NUTCParkingSpace
//
//  像素模式開放原始碼授權：名牌區塊標題 + 缺角框資訊卡；授權全文可選取。
//

import SwiftUI

struct PixelFontLicenseView: View {
    let licenseText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PixelInfoSection(title: "字型") {
                    PixelInfoCard {
                        VStack(spacing: 10) {
                            row("名稱", "俐方體 11 號（Cubic 11）")
                            row("版本", "1.500")
                            row("授權", "SIL Open Font License 1.1")
                        }
                    }
                }
                PixelInfoSection(title: "授權全文") {
                    PixelInfoCard {
                        Text(licenseText)
                            .font(.system(size: 15))
                            .foregroundStyle(PixelPalette.ink)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .pixelInfoPage(title: "開放原始碼授權")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(PixelPalette.muted)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PixelPalette.ink)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
