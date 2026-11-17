//
//  PixelEmergencyView.swift
//  NUTCParkingSpace
//
//  像素模式緊急聯絡：紅色 SOS 橫幅 + 每個聯絡人一張像素按鈕卡（點擊撥號 tel:）。
//
//  對比（WCAG 2.x 實算）：
//   - 白字 #FFFFFF 對 PixelPalette.red #C4503A：相對亮度 0.178 → (1.05)/(0.178+0.05) = 4.61:1（>= 4.5:1，通過）
//   - 墨色 #2B2438 對 paper #FBF4DD / paper2 #E8DCB5 皆 >= 10:1
//   - 紙色對 red 僅約 4.2:1，故紅底一律使用純白字
//

import SwiftUI

struct PixelEmergencyContact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let desc: String
    let kind: PixelInfoGlyphKind
}

struct PixelEmergencyView: View {
    let contacts: [PixelEmergencyContact]
    @Environment(\.openURL) private var openURL

    /// 紅底上的前景色：白字 4.61:1（見檔頭註解）
    private let onRed = Color.white

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sosBanner
                ForEach(contacts) { c in
                    contactButton(c)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .pixelInfoPage(title: "緊急聯絡")
    }

    private var sosBanner: some View {
        HStack(spacing: 12) {
            Text("SOS")
                .pixelFont(size: PixelMetrics.FontSize.large)
                .foregroundStyle(onRed)
            VStack(alignment: .leading, spacing: 4) {
                Text("緊急聯絡")
                    .pixelFont(size: PixelMetrics.FontSize.medium)
                    .foregroundStyle(onRed)
                Text("遇到緊急狀況請立即撥打")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(onRed)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelFrame(fill: PixelPalette.red)
        .accessibilityElement(children: .combine)
    }

    private func contactButton(_ c: PixelEmergencyContact) -> some View {
        Button {
            if let url = URL(string: "tel:\(c.phone.filter(\.isNumber))") {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                PixelInfoGlyph(kind: c.kind, scale: 3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PixelPalette.ink)
                    Text(c.desc)
                        .font(.system(size: 15))
                        .foregroundStyle(PixelPalette.muted)
                    Text(c.phone)
                        .pixelFont(size: PixelMetrics.FontSize.medium)
                        .foregroundStyle(PixelPalette.ink)
                }
                Spacer(minLength: 8)
                // 醒目撥號章：紅底白字 + 電話圖示
                VStack(spacing: 4) {
                    PixelInfoGlyph(kind: .phone, scale: 2, color: onRed)
                    Text("撥打")
                        .pixelFont(size: PixelMetrics.FontSize.small)
                        .foregroundStyle(onRed)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 56, minHeight: 56)
                .pixelFrame(fill: PixelPalette.red)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        }
        .buttonStyle(.pixel)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(c.name)，\(c.desc)，電話 \(c.phone)")
        .accessibilityHint("點兩下撥打電話")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        PixelEmergencyView(contacts: [
            PixelEmergencyContact(name: "校安中心", phone: "04-22195999", desc: "校園安全通報專線", kind: .shield)
        ])
    }
}
